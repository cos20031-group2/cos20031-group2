-- ==========================================
-- SHARED PROCEDURE: Driver Eligibility Recompute
-- ==========================================
-- DrivingEligibility is a CACHE, not a record. Nothing ever writes 'Eligible'
-- or 'Suspended' from local knowledge -- every touchpoint (critical event,
-- review closing, coaching outcome) calls this, and it re-derives the answer
-- from scratch by checking every disqualifying condition. This is what lets
-- two independent reasons (an open review AND an open retraining) coexist
-- without one trigger clobbering the other's write.

DELIMITER //

CREATE PROCEDURE sp_RecomputeDriverEligibility(IN p_DriverID VARCHAR(20))
BEGIN
    DECLARE v_Blocked BOOLEAN DEFAULT FALSE;

    -- Reason 1: an unresolved Critical-severity event. SafetyEvent.ReviewState
    -- is itself kept in sync with EventReview by the triggers below, so this
    -- only reads a column, it doesn't re-derive review state itself.
    IF EXISTS (
        SELECT 1
        FROM SafetyEvent se
        JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
        WHERE se.DriverID = p_DriverID
          AND sev.SeverityLevel = 'Critical'
          AND se.ReviewState <> 'Completed'
    ) THEN
        SET v_Blocked = TRUE;
    END IF;

    -- Reason 2: an outstanding Retraining requirement (score <= 50 cascade).
    -- Anything other than 'Passed' keeps the driver blocked, including 'Failed'
    -- -- a failed retraining doesn't clear the requirement, it just sits there
    -- until staff enrol them in a new one or update the outcome.
    IF EXISTS (
        SELECT 1
        FROM CoachingRecord
        WHERE DriverID = p_DriverID
          AND CoachingType = 'Retraining'
          AND Outcome <> 'Passed'
    ) THEN
        SET v_Blocked = TRUE;
    END IF;

    UPDATE Driver
    SET DrivingEligibility = IF(v_Blocked, 'Suspended', 'Eligible')
    WHERE DriverID = p_DriverID;
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGERS: SafetyEvent - Severity Routing
-- ==========================================

DELIMITER //

-- BEFORE INSERT: High/Critical always forces 'Pending', overriding whatever
-- the app sent. Low/Medium is left completely alone -- if the app didn't
-- specify a value, the column's own DEFAULT 'No Review Required' already
-- applies before this trigger runs, so there's nothing extra to do here.
CREATE TRIGGER TRG_SafetyEvent_BeforeInsert
BEFORE INSERT ON SafetyEvent
FOR EACH ROW
BEGIN
    DECLARE v_SeverityLevel VARCHAR(100);

    SELECT SeverityLevel INTO v_SeverityLevel
    FROM EventSeverity WHERE SeverityID = NEW.SeverityID;

    IF v_SeverityLevel IN ('High', 'Critical') THEN
        SET NEW.ReviewState = 'Pending';
    END IF;
END;
//

-- AFTER INSERT: Critical events are the only ones that touch eligibility.
CREATE TRIGGER TRG_SafetyEvent_AfterInsert
AFTER INSERT ON SafetyEvent
FOR EACH ROW
BEGIN
    DECLARE v_SeverityLevel VARCHAR(100);

    SELECT SeverityLevel INTO v_SeverityLevel
    FROM EventSeverity WHERE SeverityID = NEW.SeverityID;

    IF v_SeverityLevel = 'Critical' THEN
        CALL sp_RecomputeDriverEligibility(NEW.DriverID);
    END IF;
END;
//

DELIMITER ;


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

-- BEFORE UPDATE: Can't close a review that was never read.
CREATE TRIGGER TRG_EventReview_BeforeUpdate
BEFORE UPDATE ON EventReview
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Closed' AND OLD.Status = 'Unread' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot close a review that has not been read.';
    END IF;
END;
//

-- AFTER INSERT: A new reviewer being assigned always moves the needle.
CREATE TRIGGER TRG_EventReview_AfterInsert
AFTER INSERT ON EventReview
FOR EACH ROW
BEGIN
    DECLARE v_NewState VARCHAR(50);
    SET v_NewState = fn_EventReviewState(NEW.EventID);

    IF v_NewState IS NOT NULL THEN
        UPDATE SafetyEvent SET ReviewState = v_NewState WHERE EventID = NEW.EventID;
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
            UPDATE SafetyEvent SET ReviewState = v_NewState WHERE EventID = NEW.EventID;
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
