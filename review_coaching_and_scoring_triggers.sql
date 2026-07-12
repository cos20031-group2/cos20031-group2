-- ==========================================================
-- EVENT REVIEW, COACHING & SCORING TRIGGERS  (4 of 5)
-- ==========================================================
-- Scope: the "downstream consequences" side of the safety system --
-- fn_EventReviewState and the EventReview close-guard/back-write
-- triggers, the DriverScorePenalty score cascade (including
-- automatic CoachingRecord creation), CoachingRecord completion
-- clearing eligibility, and the sp_InitializeMonthlyScores procedure.
--
-- Depends on: schema.sql, driver_eligibility_and_safety_event_triggers.sql
-- (calls sp_RecomputeDriverEligibility, defined there).
-- ==========================================================

-- ==========================================
-- SUPPORTING FUNCTION: EventReview Aggregation
-- ==========================================
-- Recomputes what SafetyEvent.ReviewState should be from the full set of
-- EventReview rows tied to an event -- same "recompute the whole picture,
-- don't patch incrementally" approach as the eligibility procedure above.
-- Returns NULL when no review has been assigned yet, signalling the caller
-- to leave SafetyEvent.ReviewState (Pending / No Review Required) untouched.

DELIMITER //

CREATE FUNCTION fn_EventReviewState(p_EventID VARCHAR(100))
RETURNS VARCHAR(50)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total INT DEFAULT 0;
    DECLARE v_Open INT DEFAULT 0;
    DECLARE v_Started INT DEFAULT 0;

    SELECT COUNT(*) INTO v_Total FROM EventReview WHERE EventID = p_EventID;

    IF v_Total = 0 THEN
        RETURN NULL;
    END IF;

    -- All reviewers Closed -> the event's review is fully Completed.
    SELECT COUNT(*) INTO v_Open
    FROM EventReview WHERE EventID = p_EventID AND Status <> 'Closed';

    IF v_Open = 0 THEN
        RETURN 'Completed';
    END IF;

    -- At least one reviewer has started looking -> In Review.
    SELECT COUNT(*) INTO v_Started
    FROM EventReview WHERE EventID = p_EventID AND Status IN ('Read', 'Commented');

    IF v_Started > 0 THEN
        RETURN 'In Review';
    END IF;

    -- Reviewer(s) exist but nobody's opened it yet.
    RETURN 'Assigned';
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGERS: EventReview - Close Guard & Back-write
-- ==========================================

DELIMITER //

-- BEFORE UPDATE: Can't close a review that was never read, and once Closed,
-- a review is a historical fact -- matches the "Can't be edited after being
-- closed" line in the CHK_ER_StatusConsistency comment in schema.sql, which
-- wasn't actually enforced anywhere until now.
CREATE TRIGGER TRG_EventReview_BeforeUpdate
BEFORE UPDATE ON EventReview
FOR EACH ROW
BEGIN
    IF OLD.Status = 'Closed' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify a review that has already been closed.';
    END IF;

    IF NEW.Status = 'Closed' AND OLD.Status = 'Unread' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot close a review that has not been read.';
    END IF;
END;
//

-- BEFORE INSERT: A review can't be born already Closed -- same "must be
-- Read first" rule as the BeforeUpdate guard, just covering the entry point
-- that guard can't see (INSERT has no OLD.Status to compare against).
CREATE TRIGGER TRG_EventReview_BeforeInsert
BEFORE INSERT ON EventReview
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Closed' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot insert a review as Closed; it must be read first.';
    END IF;
END;
//

-- AFTER INSERT: A new reviewer being assigned always moves the needle.
CREATE TRIGGER TRG_EventReview_AfterInsert
AFTER INSERT ON EventReview
FOR EACH ROW
BEGIN
    DECLARE v_NewState VARCHAR(50);
    DECLARE v_DriverID VARCHAR(20);

    SET v_NewState = fn_EventReviewState(NEW.EventID);

    IF v_NewState IS NOT NULL THEN
        SET @sfms_allow_reviewstate_write = 1;
        UPDATE SafetyEvent SET ReviewState = v_NewState WHERE EventID = NEW.EventID;
        SET @sfms_allow_reviewstate_write = NULL;
    END IF;

    -- With the BeforeInsert guard above, a freshly inserted row can never
    -- itself be Closed, so this branch should be structurally unreachable
    -- today. Kept anyway, mirroring AfterUpdate exactly, as cheap insurance
    -- in case that guard is ever loosened later.
    IF v_NewState = 'Completed' THEN
        SELECT DriverID INTO v_DriverID FROM SafetyEvent WHERE EventID = NEW.EventID;
        CALL sp_RecomputeDriverEligibility(v_DriverID);
    END IF;
END;
//

-- AFTER UPDATE: Any status change re-syncs SafetyEvent.ReviewState, and if the
-- event just became fully Completed (all reviewers Closed), the driver's
-- eligibility may need to clear -- safe to always call the procedure here,
-- since it re-checks every condition rather than assuming this was the only one.
CREATE TRIGGER TRG_EventReview_AfterUpdate
AFTER UPDATE ON EventReview
FOR EACH ROW
BEGIN
    DECLARE v_NewState VARCHAR(50);
    DECLARE v_DriverID VARCHAR(20);

    IF OLD.Status <> NEW.Status THEN
        SET v_NewState = fn_EventReviewState(NEW.EventID);

        IF v_NewState IS NOT NULL THEN
            SET @sfms_allow_reviewstate_write = 1;
            UPDATE SafetyEvent SET ReviewState = v_NewState WHERE EventID = NEW.EventID;
            SET @sfms_allow_reviewstate_write = NULL;
        END IF;

        IF v_NewState = 'Completed' THEN
            SELECT DriverID INTO v_DriverID FROM SafetyEvent WHERE EventID = NEW.EventID;
            CALL sp_RecomputeDriverEligibility(v_DriverID);
        END IF;
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGERS: DriverScorePenalty - Score Cascade
-- ==========================================
-- NOTE: assumes DriverMonthlySafetyScore.Score is stored-and-decremented
-- (per our earlier discussion), not computed-on-read. This trigger IS the
-- decrement -- nothing else updates that column.

DELIMITER //

CREATE TRIGGER TRG_DriverScorePenalty_AfterInsert
AFTER INSERT ON DriverScorePenalty
FOR EACH ROW
BEGIN
    DECLARE v_DriverID VARCHAR(20);
    DECLARE v_NewScore DECIMAL(5,2);
    DECLARE v_OpenCoaching INT DEFAULT 0;
    DECLARE v_OpenRetraining INT DEFAULT 0;

    -- Step 1: apply the deduction.
    UPDATE DriverMonthlySafetyScore
    SET Score = Score - NEW.PointsDeducted
    WHERE DriverMonthlySafetyScoreID = NEW.DriverMonthlySafetyScoreID;

    -- Step 2: fetch the driver + freshly updated score.
    SELECT DriverID, Score INTO v_DriverID, v_NewScore
    FROM DriverMonthlySafetyScore
    WHERE DriverMonthlySafetyScoreID = NEW.DriverMonthlySafetyScoreID;

    -- Step 3: score <= 75 -> ensure a Safety Coaching requirement exists.
    -- Non-blocking -- doesn't touch DrivingEligibility. Guarded so repeated
    -- penalties in the same low-score window don't spawn duplicate records.
    IF v_NewScore <= 75 THEN
        SELECT COUNT(*) INTO v_OpenCoaching
        FROM CoachingRecord
        WHERE DriverID = v_DriverID
          AND CoachingType = 'Safety Coaching'
          AND Outcome IN ('Pending', 'In Progress');

        IF v_OpenCoaching = 0 THEN
            INSERT INTO CoachingRecord (DriverID, CoachingType, CoachingDate, Outcome)
            VALUES (v_DriverID, 'Safety Coaching', CURDATE(), 'Pending');
        END IF;
    END IF;

    -- Step 4: score <= 50 -> ensure a Retraining requirement exists. This one
    -- IS blocking, via sp_RecomputeDriverEligibility below.
    IF v_NewScore <= 50 THEN
        SELECT COUNT(*) INTO v_OpenRetraining
        FROM CoachingRecord
        WHERE DriverID = v_DriverID
          AND CoachingType = 'Retraining'
          AND Outcome <> 'Passed';

        IF v_OpenRetraining = 0 THEN
            INSERT INTO CoachingRecord (DriverID, CoachingType, CoachingDate, Outcome)
            VALUES (v_DriverID, 'Retraining', CURDATE(), 'Pending');
        END IF;
    END IF;

    -- Step 5: recompute regardless -- covers the case where this penalty
    -- pushed the score below 50 for the first time.
    CALL sp_RecomputeDriverEligibility(v_DriverID);
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGER: CoachingRecord - Completion Clears Eligibility
-- ==========================================

DELIMITER //

-- BEFORE UPDATE: DriverID, CoachingType, and CoachingDate are the "who/what/
-- when this was opened" facts -- locked once set, same pattern as
-- VehicleAssignment and MechanicWorkSession. Outcome and CompletionDate stay
-- open, since progressing a coaching record to Passed/Failed is the point.
CREATE TRIGGER TRG_CoachingRecord_BeforeUpdate
BEFORE UPDATE ON CoachingRecord
FOR EACH ROW
BEGIN
    IF NEW.DriverID <> OLD.DriverID
       OR NEW.CoachingType <> OLD.CoachingType
       OR NEW.CoachingDate <> OLD.CoachingDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify DriverID, CoachingType, or CoachingDate on an existing coaching record.';
    END IF;
END;
//

CREATE TRIGGER TRG_CoachingRecord_AfterUpdate
AFTER UPDATE ON CoachingRecord
FOR EACH ROW
BEGIN
    -- Only Retraining outcomes matter for eligibility; Safety Coaching and
    -- Licence Review never blocked in the first place, so nothing to clear.
    IF NEW.CoachingType = 'Retraining' AND OLD.Outcome <> NEW.Outcome THEN
        CALL sp_RecomputeDriverEligibility(NEW.DriverID);
    END IF;
END;
//

-- AFTER INSERT: covers a Retraining record created directly (staff manually
-- enrolling a driver) rather than via the DriverScorePenalty cascade above,
-- which already calls the procedure itself as part of its own insert.
CREATE TRIGGER TRG_CoachingRecord_AfterInsert
AFTER INSERT ON CoachingRecord
FOR EACH ROW
BEGIN
    IF NEW.CoachingType = 'Retraining' AND NEW.Outcome <> 'Passed' THEN
        CALL sp_RecomputeDriverEligibility(NEW.DriverID);
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- SUPPORTING PROCEDURE: Monthly Score Initialization
-- ==========================================
-- Creates a DriverMonthlySafetyScore row at Score = 100 for every eligible
-- driver for a given month/year. Not a trigger -- there's no DML event that
-- means "a new month started," so this needs an explicit call, either from
-- a MySQL scheduled EVENT (not built here) or an app-side monthly job.
--
-- Idempotent by design (NOT EXISTS guard + the table's own
-- UC_DriverMonthlySafetyScore unique constraint as a backstop), so it's safe
-- to call more than once for the same month -- which matters, because
-- 'On Leave' drivers are deliberately included below. A driver who returns
-- from leave mid-month, or who's assigned a depot mid-month, needs this
-- re-run to pick them up; otherwise the first DriverScorePenalty against
-- them that month has no row to decrement.
--
-- Only 'Terminated' is excluded. Drivers with no CurrentDepotID are skipped
-- entirely (DepotID is NOT NULL on this table) -- worth revisiting if that
-- turns out to be a real scenario rather than an edge case.

DELIMITER //

CREATE PROCEDURE sp_InitializeMonthlyScores(IN p_Month TINYINT UNSIGNED, IN p_Year YEAR)
BEGIN
    INSERT INTO DriverMonthlySafetyScore (DriverID, Month, Year, DepotID, Score)
    SELECT d.DriverID, p_Month, p_Year, d.CurrentDepotID, 100.00
    FROM Driver d
    WHERE d.EmploymentStatus <> 'Terminated'
      AND d.CurrentDepotID IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM DriverMonthlySafetyScore dmss
          WHERE dmss.DriverID = d.DriverID
            AND dmss.Month = p_Month
            AND dmss.Year = p_Year
      );
END;
//

DELIMITER ;

-- Example call, for this month:
--   CALL sp_InitializeMonthlyScores(MONTH(CURDATE()), YEAR(CURDATE()));
