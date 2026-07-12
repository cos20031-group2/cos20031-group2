-- ==========================================================
-- VEHICLE ASSIGNMENT TRIGGERS  (1 of 5)
-- ==========================================================
-- Scope: fn_NextVehicleStatus (the shared vehicle-status derivation
-- function) and the full VehicleAssignment lifecycle -- booking
-- (Pending) -> In Operation -> Completed/Cancelled -- including the
-- eligibility/certification gate and the vehicle status flips that
-- go with each transition.
--
-- Depends on: schema.sql
-- Note: fn_NextVehicleStatus, defined below, is also called from the
-- MaintenanceJob triggers in maintenance_and_alert_triggers.sql.
-- ==========================================================

-- ==========================================
-- SUPPORTING FUNCTION
-- ==========================================
-- Decides what a vehicle should become when it's released back to the fleet,
-- whether that's from a VehicleAssignment ending or a MaintenanceJob closing.
-- Checks three independent sources of truth, in priority order: is another
-- MaintenanceJob still open on this VIN, is there still an In Operation
-- VehicleAssignment on it, and finally, is a ScheduledService due. Extracted
-- because every call site needs the same full picture, and duplicating this
-- logic across triggers was already a maintenance risk with just two call
-- sites -- now with three checks instead of one, keeping it in one place
-- matters even more.

DELIMITER //

CREATE FUNCTION fn_NextVehicleStatus(p_VIN VARCHAR(17))
RETURNS SMALLINT UNSIGNED
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_OpenJobs INT DEFAULT 0;
    DECLARE v_OpenAssignment INT DEFAULT 0;
    DECLARE v_PendingServices INT DEFAULT 0;
    DECLARE v_StatusID SMALLINT UNSIGNED;

    -- Tier 1: still physically being worked on (another job open on this VIN)?
    -- Beats everything else -- a vehicle mid-repair can't be handed to a driver.
    SELECT COUNT(*) INTO v_OpenJobs
    FROM MaintenanceJob
    WHERE VIN = p_VIN AND DateClosed IS NULL;

    IF v_OpenJobs > 0 THEN
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Under Maintenance';
        RETURN v_StatusID;
    END IF;

    -- Tier 2: still administratively out with a driver? (The "emergency
    -- repair on an In Operation vehicle" case -- we don't auto-cancel that
    -- assignment, so when the job closes it should go back to Active, not
    -- Available, since someone still has it.)
    SELECT COUNT(*) INTO v_OpenAssignment
    FROM VehicleAssignment
    WHERE VIN = p_VIN AND AssignmentStatus = 'In Operation';

    IF v_OpenAssignment > 0 THEN
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Active';
        RETURN v_StatusID;
    END IF;

    -- Tier 3: free and clear -- just check whether something's due.
    SELECT COUNT(*) INTO v_PendingServices
    FROM ScheduledService
    WHERE VIN = p_VIN
      AND Status IN ('Scheduled', 'In Progress')
      AND ScheduledDate <= CURDATE();

    IF v_PendingServices > 0 THEN
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Awaiting Inspection';
    ELSE
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Available';
    END IF;

    RETURN v_StatusID;
END;
//

DELIMITER ;



-- ==========================================
-- TRIGGERS: Vehicle Assignment Validations & Status Automation
-- ==========================================

DELIMITER //

-- 1. BEFORE INSERT: Gate only applies when a row is born already 'In Operation'
--    (walk-up assignment, no advance Pending booking). 'Pending' inserts skip
--    validation entirely -- that's the whole point of Pending existing.
--    Historical backfills landing directly as Completed/Cancelled also skip
--    the gate, since checking today's vehicle/driver state against a past
--    record would reject perfectly legitimate historical data.
CREATE TRIGGER TRG_VehicleAssignment_BeforeInsert
BEFORE INSERT ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_VehicleStatus VARCHAR(100);
    DECLARE v_DriverEligibility VARCHAR(100);
    DECLARE v_EmploymentStatus VARCHAR(50);
    DECLARE v_CategoryID SMALLINT UNSIGNED;
    DECLARE v_MissingCerts INT DEFAULT 0;

    IF NEW.AssignmentStatus = 'In Operation' THEN

        SELECT vs.VehicleStatus, v.CategoryID
        INTO v_VehicleStatus, v_CategoryID
        FROM Vehicle v
        JOIN VehicleStatus vs ON v.OperationalStatus = vs.VehicleStatusID
        WHERE v.VIN = NEW.VIN;

        IF v_VehicleStatus IS NULL OR v_VehicleStatus <> 'Available' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign vehicle: vehicle is not currently Available.';
        END IF;

        SELECT DrivingEligibility, EmploymentStatus
        INTO v_DriverEligibility, v_EmploymentStatus
        FROM Driver
        WHERE DriverID = NEW.DriverID;

        -- Two independent axes: EmploymentStatus (do they
        -- work here right now) and DrivingEligibility (are they cleared to
        -- drive). Both must pass -- a fully eligible driver who's On Leave or
        -- Terminated is still not assignable.
        IF v_EmploymentStatus IS NULL OR v_EmploymentStatus <> 'Active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign driver: driver is not currently an active employee.';
        END IF;

        IF v_DriverEligibility <> 'Eligible' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign driver: driver is not currently eligible.';
        END IF;

        SELECT COUNT(*) INTO v_MissingCerts
        FROM VehicleCertificationRequirement vcr
        WHERE vcr.VehicleCategoryID = v_CategoryID
          AND NOT EXISTS (
              SELECT 1 FROM DriverCertification dc
              WHERE dc.DriverID = NEW.DriverID
                AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
                AND dc.Status IN ('Active', 'Reinstated')
                AND dc.ExpiryDate > CURDATE()
          );

        IF v_MissingCerts > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign driver: driver lacks required active certifications for this vehicle category.';
        END IF;

    END IF;
END;
//


-- 2. BEFORE UPDATE: Transition guard + field-lock + gate on the one transition
--    that actually starts an assignment.
CREATE TRIGGER TRG_VehicleAssignment_BeforeUpdate
BEFORE UPDATE ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_VehicleStatus VARCHAR(100);
    DECLARE v_DriverEligibility VARCHAR(100);
    DECLARE v_EmploymentStatus VARCHAR(50);
    DECLARE v_CategoryID SMALLINT UNSIGNED;
    DECLARE v_MissingCerts INT DEFAULT 0;

    -- Rule 0: Completed/Cancelled are terminal. Nothing about the row moves again.
    IF OLD.AssignmentStatus IN ('Completed', 'Cancelled') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify a Completed or Cancelled assignment.';
    END IF;

    -- Rule 1: Only these status transitions are legal.
    IF OLD.AssignmentStatus <> NEW.AssignmentStatus THEN
        IF NOT (
            (OLD.AssignmentStatus = 'Pending'      AND NEW.AssignmentStatus IN ('In Operation', 'Cancelled'))
            OR (OLD.AssignmentStatus = 'In Operation' AND NEW.AssignmentStatus IN ('Completed', 'Cancelled'))
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid assignment status transition.';
        END IF;
    END IF;

    -- Rule 2: Once an assignment has left Pending, the facts of "who/what/when
    -- it started" are locked. Only Pending rows are freely correctable.
    IF OLD.AssignmentStatus <> 'Pending' THEN
        IF NEW.VIN <> OLD.VIN
           OR NEW.DriverID <> OLD.DriverID
           OR NEW.DepotID <> OLD.DepotID
           OR NEW.IssueDate <> OLD.IssueDate
           OR NOT (NEW.StartDate <=> OLD.StartDate) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot modify VIN, DriverID, DepotID, IssueDate, or StartDate once an assignment has left Pending.';
        END IF;
    END IF;

    -- Rule 3: Re-run the full gate on the Pending -> In Operation transition,
    -- since time has passed since the booking was made (cert could've expired,
    -- vehicle could've gone into maintenance, driver could've been suspended).
    IF OLD.AssignmentStatus = 'Pending' AND NEW.AssignmentStatus = 'In Operation' THEN

        IF NEW.StartDate IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'StartDate must be set when transitioning to In Operation.';
        END IF;

        SELECT vs.VehicleStatus, v.CategoryID
        INTO v_VehicleStatus, v_CategoryID
        FROM Vehicle v
        JOIN VehicleStatus vs ON v.OperationalStatus = vs.VehicleStatusID
        WHERE v.VIN = NEW.VIN;

        IF v_VehicleStatus IS NULL OR v_VehicleStatus <> 'Available' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: vehicle is not currently Available.';
        END IF;

        SELECT DrivingEligibility, EmploymentStatus
        INTO v_DriverEligibility, v_EmploymentStatus
        FROM Driver
        WHERE DriverID = NEW.DriverID;

        IF v_EmploymentStatus IS NULL OR v_EmploymentStatus <> 'Active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: driver is not currently an active employee.';
        END IF;

        IF v_DriverEligibility <> 'Eligible' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: driver is not currently eligible.';
        END IF;

        SELECT COUNT(*) INTO v_MissingCerts
        FROM VehicleCertificationRequirement vcr
        WHERE vcr.VehicleCategoryID = v_CategoryID
          AND NOT EXISTS (
              SELECT 1 FROM DriverCertification dc
              WHERE dc.DriverID = NEW.DriverID
                AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
                AND dc.Status IN ('Active', 'Reinstated')
                AND dc.ExpiryDate > CURDATE()
          );

        IF v_MissingCerts > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: driver lacks required active certifications.';
        END IF;

    END IF;

END;
//


-- 3. AFTER INSERT: Only fires the vehicle over to 'Active' when a row is born
--    directly 'In Operation' (the walk-up case). A 'Pending' insert doesn't
--    touch the vehicle at all -- nothing has physically happened yet.
CREATE TRIGGER TRG_VehicleAssignment_AfterInsert
AFTER INSERT ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_ActiveStatusID SMALLINT UNSIGNED;

    IF NEW.AssignmentStatus = 'In Operation' THEN
        SELECT VehicleStatusID INTO v_ActiveStatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Active';

        UPDATE Vehicle
        SET OperationalStatus = v_ActiveStatusID
        WHERE VIN = NEW.VIN;
    END IF;
END;
//


-- 4. AFTER UPDATE: Two independent triggers for the vehicle, matching the two
--    points in the lifecycle where the vehicle's real-world state changes.
CREATE TRIGGER TRG_VehicleAssignment_AfterUpdate
AFTER UPDATE ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_ActiveStatusID SMALLINT UNSIGNED;

    -- Booking just went live (Pending -> In Operation): vehicle leaves the depot.
    IF OLD.AssignmentStatus = 'Pending' AND NEW.AssignmentStatus = 'In Operation' THEN
        SELECT VehicleStatusID INTO v_ActiveStatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Active';

        UPDATE Vehicle
        SET OperationalStatus = v_ActiveStatusID
        WHERE VIN = NEW.VIN;
    END IF;

    -- Vehicle physically comes back, whether the run finished or was aborted
    -- mid-route. Either way it needs to be re-triaged for the next state.
    IF OLD.AssignmentStatus = 'In Operation' AND NEW.AssignmentStatus IN ('Completed', 'Cancelled') THEN
        UPDATE Vehicle
        SET OperationalStatus = fn_NextVehicleStatus(NEW.VIN)
        WHERE VIN = NEW.VIN;
    END IF;

    -- Pending -> Cancelled: the vehicle was never touched by this booking
    -- (no gate ran, no status flip happened on insert), so there's nothing
    -- to release here. Intentionally a no-op.

END;
//

DELIMITER ;


