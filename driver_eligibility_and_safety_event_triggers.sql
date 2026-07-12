-- ==========================================================
-- DRIVER ELIGIBILITY & SAFETY EVENT TRIGGERS  (3 of 5)
-- ==========================================================
-- Scope: sp_RecomputeDriverEligibility (the cached-eligibility
-- engine) and everything that happens on SafetyEvent creation --
-- severity routing, the eligibility recompute for Critical events,
-- penalty rule evaluation against DriverScorePenalty, and the
-- historical-fact lock on SafetyEvent itself.
--
-- Depends on: schema.sql
-- Note: sp_RecomputeDriverEligibility, defined below, is also called
-- from review_coaching_and_scoring_triggers.sql (EventReview and
-- CoachingRecord triggers) whenever a blocking reason clears.
-- ==========================================================

-- ==========================================
-- SHARED PROCEDURE: Driver Eligibility Recompute
-- ==========================================
-- DrivingEligibility is a CACHE, not a record. Nothing ever writes 'Eligible'
-- or 'Suspended' from local knowledge -- every touchpoint (critical event,
-- review closing, coaching outcome) calls this, and it re-derives the answer
-- from scratch by checking every disqualifying condition. This is what lets
-- two independent reasons (an open review AND an open retraining) coexist
-- without one trigger clobbering the other's write.
--
-- DELIBERATE DESIGN DECISION: a driver is only Eligible again once EVERY
-- open reason clears (AND-to-clear), not once ANY single reason clears. The
-- brief's "until the review has been completed or he completes the safety
-- training" describes the two release valves the system has, not a strict
-- either/or on one shared block. Reason 1 (critical event review) and
-- Reason 2 (score-driven retraining) have different causes and don't know
-- about each other -- a driver whose critical-event review just closed but
-- who separately has an open retraining from a bad score stays Suspended,
-- because the retraining is what's actually making them unsafe to drive,
-- and it's unrelated to whether that specific review happened to finish.

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

    -- This is the ONLY authorized writer of DrivingEligibility -- the flag
    -- tells TRG_Driver_BeforeUpdate to let this specific write through, and
    -- gets cleared immediately after so nothing else can piggyback on it.
    SET @sfms_allow_eligibility_write = 1;
    UPDATE Driver
    SET DrivingEligibility = IF(v_Blocked, 'Suspended', 'Eligible')
    WHERE DriverID = p_DriverID;
    SET @sfms_allow_eligibility_write = NULL;
END;
//

-- BEFORE UPDATE: DrivingEligibility is derived-only. Any attempt to write it
-- outside of sp_RecomputeDriverEligibility (i.e. without the flag set) is
-- rejected -- this is what makes the "cache, not a record" design an actual
-- enforced invariant rather than just a comment everyone has to remember to
-- respect.
CREATE TRIGGER TRG_Driver_BeforeUpdate
BEFORE UPDATE ON Driver
FOR EACH ROW
BEGIN
    IF NEW.DrivingEligibility <> OLD.DrivingEligibility
       AND (@sfms_allow_eligibility_write IS NULL OR @sfms_allow_eligibility_write <> 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DrivingEligibility cannot be written directly; it is derived by sp_RecomputeDriverEligibility.';
    END IF;
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
-- SUPPORTING PROCEDURE + TRIGGER: Penalty Evaluation
-- ==========================================
-- Nothing previously read PenaltyRule at all -- monthly scores never moved
-- unless something manually inserted DriverScorePenalty rows. This closes
-- that gap: every SafetyEvent insert evaluates against every matching rule
-- (Base on severity, Conditional on event type + count-within-month) and
-- applies whatever's due.
--
-- HARD DEPENDENCY: requires a DriverMonthlySafetyScore row to already exist
-- for this driver's month (via sp_InitializeMonthlyScores) -- there's no
-- score row to attach the penalty to otherwise, and this procedure rejects
-- the insert rather than silently skipping the penalty. This means seeding
-- historical SafetyEvent data now requires initializing that historical
-- month's score row FIRST.
--
-- ONLY CORRECTLY HANDLES TimeWindowMonths = 1 (matching current seed data).
-- A Conditional rule's window is treated as "the calendar month this event
-- falls in," not a rolling N-month window -- forced by DriverScorePenalty
-- attaching to exactly one DriverMonthlySafetyScoreID, which a window
-- spanning a month boundary wouldn't cleanly map to. A future rule with
-- TimeWindowMonths > 1 would need this reworked, not just parameterized.

DELIMITER //

CREATE PROCEDURE sp_EvaluatePenaltiesForEvent(IN p_EventID VARCHAR(100))
BEGIN
    DECLARE v_DriverID VARCHAR(20);
    DECLARE v_EventTypeID SMALLINT UNSIGNED;
    DECLARE v_SeverityID SMALLINT UNSIGNED;
    DECLARE v_EventTimestamp TIMESTAMP;
    DECLARE v_ScoreID INT UNSIGNED;

    DECLARE v_Done INT DEFAULT FALSE;
    DECLARE v_RuleID SMALLINT UNSIGNED;
    DECLARE v_RuleType VARCHAR(20);
    DECLARE v_MinEventCount TINYINT UNSIGNED;
    DECLARE v_TimeWindowMonths TINYINT UNSIGNED;
    DECLARE v_PenaltyPoints DECIMAL(5,2);
    DECLARE v_MatchCount INT;
    DECLARE v_AlreadyApplied INT;

    -- Rules that could possibly apply to this event: a Base rule matching
    -- its severity, or a Conditional rule matching its event type. Severity/
    -- EventType values are captured below, before OPEN, since a cursor's
    -- query is evaluated against variable values at OPEN time.
    DECLARE cur CURSOR FOR
        SELECT PenaltyRuleID, RuleType, MinEventCount, TimeWindowMonths, PenaltyPoints
        FROM PenaltyRule
        WHERE (RuleType = 'Base' AND SeverityID = v_SeverityID)
           OR (RuleType = 'Conditional' AND EventTypeID = v_EventTypeID);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_Done = TRUE;

    SELECT DriverID, EventTypeID, SeverityID, EventTimestamp
    INTO v_DriverID, v_EventTypeID, v_SeverityID, v_EventTimestamp
    FROM SafetyEvent WHERE EventID = p_EventID;

    SELECT DriverMonthlySafetyScoreID INTO v_ScoreID
    FROM DriverMonthlySafetyScore
    WHERE DriverID = v_DriverID
      AND Month = MONTH(v_EventTimestamp)
      AND Year = YEAR(v_EventTimestamp);

    IF v_ScoreID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot apply penalty: no DriverMonthlySafetyScore row exists for this driver/month. Run sp_InitializeMonthlyScores first.';
    END IF;

    OPEN cur;
    penalty_loop: LOOP
        FETCH cur INTO v_RuleID, v_RuleType, v_MinEventCount, v_TimeWindowMonths, v_PenaltyPoints;
        IF v_Done THEN
            LEAVE penalty_loop;
        END IF;

        IF v_RuleType = 'Base' THEN
            -- One penalty per event -- every High/Critical/etc event incurs
            -- its own deduction, guarded per-EventID so re-evaluation (if
            -- this procedure is ever called again for the same event) can't
            -- double-charge it.
            SELECT COUNT(*) INTO v_AlreadyApplied
            FROM DriverScorePenalty
            WHERE EventID = p_EventID AND PenaltyRuleID = v_RuleID;

            IF v_AlreadyApplied = 0 THEN
                INSERT INTO DriverScorePenalty
                    (DriverMonthlySafetyScoreID, PenaltyRuleID, EventID, PointsDeducted, DateApplied)
                VALUES
                    (v_ScoreID, v_RuleID, p_EventID, v_PenaltyPoints, v_EventTimestamp);
            END IF;

        ELSE -- Conditional
            -- "More than N events of this type this month" -- strictly
            -- greater than, matching the brief's wording exactly (N=3 means
            -- the 4th event is what crosses it, not the 3rd).
            SELECT COUNT(*) INTO v_MatchCount
            FROM SafetyEvent
            WHERE DriverID = v_DriverID
              AND EventTypeID = v_EventTypeID
              AND MONTH(EventTimestamp) = MONTH(v_EventTimestamp)
              AND YEAR(EventTimestamp) = YEAR(v_EventTimestamp);

            IF v_MatchCount > v_MinEventCount THEN
                -- Fires once per month per rule -- once applied to this
                -- month's score row, subsequent events of the same type
                -- don't re-trigger it.
                SELECT COUNT(*) INTO v_AlreadyApplied
                FROM DriverScorePenalty
                WHERE DriverMonthlySafetyScoreID = v_ScoreID
                  AND PenaltyRuleID = v_RuleID;

                IF v_AlreadyApplied = 0 THEN
                    INSERT INTO DriverScorePenalty
                        (DriverMonthlySafetyScoreID, PenaltyRuleID, EventID, PointsDeducted, DateApplied)
                    VALUES
                        (v_ScoreID, v_RuleID, p_EventID, v_PenaltyPoints, v_EventTimestamp);
                END IF;
            END IF;
        END IF;
    END LOOP;
    CLOSE cur;
END;
//

-- AFTER INSERT: kept separate from TRG_SafetyEvent_AfterInsert (eligibility)
-- deliberately -- two different concerns, two triggers. MySQL fires multiple
-- AFTER INSERT triggers on the same table in creation order by default.
CREATE TRIGGER TRG_SafetyEvent_AfterInsert_EvaluatePenalties
AFTER INSERT ON SafetyEvent
FOR EACH ROW
BEGIN
    CALL sp_EvaluatePenaltiesForEvent(NEW.EventID);
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGER: SafetyEvent - Historical Fact Lock
-- ==========================================

DELIMITER //

-- BEFORE UPDATE: An incident record is a historical fact once logged -- who,
-- what vehicle, what depot, what type/severity, when, and at what odometer
-- reading are all locked. ReviewState is the one column allowed to change,
-- but ONLY via the EventReview back-write triggers -- same session-flag
-- pattern as the Driver.DrivingEligibility guard, so a direct
-- UPDATE SafetyEvent SET ReviewState = ... can no longer silently bypass
-- the review workflow and skip the eligibility recompute that's supposed
-- to come with it.
CREATE TRIGGER TRG_SafetyEvent_BeforeUpdate
BEFORE UPDATE ON SafetyEvent
FOR EACH ROW
BEGIN
    IF NEW.DriverID <> OLD.DriverID
       OR NEW.VIN <> OLD.VIN
       OR NEW.DepotID <> OLD.DepotID
       OR NEW.EventTypeID <> OLD.EventTypeID
       OR NEW.SeverityID <> OLD.SeverityID
       OR NEW.EventTimestamp <> OLD.EventTimestamp
       OR NEW.Odometer <> OLD.Odometer THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify the recorded facts of a safety event. Only ReviewState may change, and only via the review workflow.';
    END IF;

    IF NEW.ReviewState <> OLD.ReviewState
       AND (@sfms_allow_reviewstate_write IS NULL OR @sfms_allow_reviewstate_write <> 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ReviewState cannot be written directly; it is derived from EventReview.';
    END IF;
END;
//

DELIMITER ;


