-- ==========================================
-- TRIGGERS: MechanicWorkSession - Certification Gate
-- ==========================================

DELIMITER //

-- BEFORE INSERT: A mechanic can only log a session against an activity if
-- they're an active employee AND hold an active, unexpired certification
-- matching that activity's required cert type.
CREATE TRIGGER TRG_MechanicWorkSession_BeforeInsert
BEFORE INSERT ON MechanicWorkSession
FOR EACH ROW
BEGIN
    DECLARE v_EmploymentStatus VARCHAR(50);
    DECLARE v_RequiredCertTypeID SMALLINT UNSIGNED;
    DECLARE v_HasValidCert INT DEFAULT 0;

    -- Rule 1: same EmploymentStatus pattern as the VehicleAssignment gate --
    -- a suspended/terminated mechanic can't log billable work.
    SELECT EmploymentStatus INTO v_EmploymentStatus
    FROM Mechanic WHERE MechanicID = NEW.MechanicID;

    IF v_EmploymentStatus <> 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot log work session: mechanic is not currently an active employee.';
    END IF;

    -- Rule 2: mechanic must hold the specific certification this activity
    -- type requires, active and not expired.
    SELECT at.RequiredMechanicCertification INTO v_RequiredCertTypeID
    FROM MaintenanceActivity ma
    JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
    WHERE ma.ActivityID = NEW.ActivityID;

    SELECT COUNT(*) INTO v_HasValidCert
    FROM MechanicCertification mc
    WHERE mc.MechanicID = NEW.MechanicID
      AND mc.MechanicCertificationTypeID = v_RequiredCertTypeID
      AND mc.Status IN ('Active', 'Reinstated')
      AND mc.ExpiryDate > CURDATE();

    IF v_HasValidCert = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot log work session: mechanic lacks the required active certification for this activity type.';
    END IF;

END;
//

-- BEFORE UPDATE: MechanicID, ActivityID, and StartTime are locked once the
-- row exists -- who did the work, on what, and when they started is a
-- historical fact. Only EndTime is legitimately mutable (closing a session
-- out, or logging a break/re-start as a fresh row per the schema comment).
CREATE TRIGGER TRG_MechanicWorkSession_BeforeUpdate
BEFORE UPDATE ON MechanicWorkSession
FOR EACH ROW
BEGIN
    IF NEW.MechanicID <> OLD.MechanicID
       OR NEW.ActivityID <> OLD.ActivityID
       OR NEW.StartTime <> OLD.StartTime THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify MechanicID, ActivityID, or StartTime on an existing work session. Close it and log a new session instead.';
    END IF;
END;
//

DELIMITER ;
