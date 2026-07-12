-- ==========================================================
-- WORKSHOP OPERATIONS TRIGGERS  (5 of 5)
-- ==========================================================
-- Scope: MechanicWorkSession certification/employment gating, Part
-- inventory tracking on ActivityPart (stock deduction/restoration),
-- and the WarrantyClaim historical-fact lock.
--
-- Depends on: schema.sql
-- ==========================================================

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

    IF v_EmploymentStatus IS NULL OR v_EmploymentStatus <> 'Active' THEN
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
-- ==========================================
-- TRIGGERS: Part Inventory Tracking
-- ==========================================
-- Nothing previously decremented Part.CurrentStock when a part actually got
-- used on a job, despite the brief calling out reorder-threshold monitoring
-- as a real workshop-manager need (p.13) and the schema already having both
-- CurrentStock and ReorderThreshold to support it.

DELIMITER //

-- BEFORE INSERT: Can't use more of a part than is actually on the shelf.
-- CurrentStock is SMALLINT UNSIGNED, so an unguarded decrement below zero
-- wouldn't just be wrong, it would be a hard error (or silently clamp,
-- depending on SQL mode) -- better to reject the usage record outright with
-- a clear message than let the AFTER INSERT decrement below hit that wall.
--
-- Also validates ClaimID, if provided: WarrantyClaim belongs to exactly one
-- ActivityID (FK_WC_Activity), so a claim opened for a different job can't
-- be attached here.
CREATE TRIGGER TRG_ActivityPart_BeforeInsert
BEFORE INSERT ON ActivityPart
FOR EACH ROW
BEGIN
    DECLARE v_CurrentStock SMALLINT UNSIGNED;
    DECLARE v_ClaimActivityID INT UNSIGNED;

    SELECT CurrentStock INTO v_CurrentStock
    FROM Part WHERE PartNumber = NEW.PartNumber;

    IF v_CurrentStock IS NULL OR v_CurrentStock < NEW.QuantityUsed THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot use more of this part than is currently in stock.';
    END IF;

    IF NEW.ClaimID IS NOT NULL THEN
        SELECT ActivityID INTO v_ClaimActivityID
        FROM WarrantyClaim WHERE ClaimID = NEW.ClaimID;

        IF v_ClaimActivityID IS NULL OR v_ClaimActivityID <> NEW.ActivityID THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ClaimID does not belong to this ActivityID.';
        END IF;
    END IF;
END;
//

-- AFTER INSERT: Apply the deduction, now guaranteed safe by the gate above.
CREATE TRIGGER TRG_ActivityPart_AfterInsert
AFTER INSERT ON ActivityPart
FOR EACH ROW
BEGIN
    UPDATE Part
    SET CurrentStock = CurrentStock - NEW.QuantityUsed
    WHERE PartNumber = NEW.PartNumber;
END;
//

-- BEFORE UPDATE: ActivityID, PartNumber, and QuantityUsed are locked once
-- the row exists -- the AFTER INSERT decrement above already happened
-- against the original QuantityUsed, so silently changing it later would
-- desync CurrentStock from what was actually recorded as used. UnitCost is
-- locked for the same "historical fact" reasoning as everywhere else in
-- this project. ClaimID stays open, since attaching a warranty claim after
-- the fact is a normal, expected edit.
CREATE TRIGGER TRG_ActivityPart_BeforeUpdate
BEFORE UPDATE ON ActivityPart
FOR EACH ROW
BEGIN
    DECLARE v_ClaimActivityID INT UNSIGNED;

    IF NEW.ActivityID <> OLD.ActivityID
       OR NEW.PartNumber <> OLD.PartNumber
       OR NEW.QuantityUsed <> OLD.QuantityUsed
       OR NEW.UnitCost <> OLD.UnitCost THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify ActivityID, PartNumber, QuantityUsed, or UnitCost on an existing part-usage record. Only ClaimID may be updated.';
    END IF;

    IF NEW.ClaimID IS NOT NULL AND NOT (NEW.ClaimID <=> OLD.ClaimID) THEN
        SELECT ActivityID INTO v_ClaimActivityID
        FROM WarrantyClaim WHERE ClaimID = NEW.ClaimID;

        IF v_ClaimActivityID IS NULL OR v_ClaimActivityID <> NEW.ActivityID THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ClaimID does not belong to this ActivityID.';
        END IF;
    END IF;
END;
//

-- AFTER DELETE: Since QuantityUsed is locked (correction = delete + re-insert,
-- not edit), a delete without this would silently under-count real stock
-- forever -- undermining the reorder-threshold tracking this file exists for.
CREATE TRIGGER TRG_ActivityPart_AfterDelete
AFTER DELETE ON ActivityPart
FOR EACH ROW
BEGIN
    UPDATE Part
    SET CurrentStock = CurrentStock + OLD.QuantityUsed
    WHERE PartNumber = OLD.PartNumber;
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGER: WarrantyClaim - Historical Fact Lock
-- ==========================================
-- The other gap in the project-wide "lock once written" pattern (alongside
-- MaintenanceJob, fixed in phase1_triggers.sql this same pass). ActivityID,
-- ClaimSource, and ClaimDate are the "what/why/when this was filed" facts --
-- locked once set. Status and ResolutionDate stay open, since progressing a
-- claim through Pending -> Approved/Rejected/Settled is the point.

DELIMITER //

CREATE TRIGGER TRG_WarrantyClaim_BeforeUpdate
BEFORE UPDATE ON WarrantyClaim
FOR EACH ROW
BEGIN
    IF NEW.ActivityID <> OLD.ActivityID
       OR NEW.ClaimSource <> OLD.ClaimSource
       OR NEW.ClaimDate <> OLD.ClaimDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify ActivityID, ClaimSource, or ClaimDate on an existing warranty claim.';
    END IF;
END;
//

DELIMITER ;
