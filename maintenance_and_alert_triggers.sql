-- ==========================================================
-- MAINTENANCE & PREDICTIVE ALERT TRIGGERS  (2 of 5)
-- ==========================================================
-- Scope: MaintenanceJob lifecycle automation (open/close, the
-- one-open-job-per-VIN gate, the historical-fact lock) and the
-- PredictiveAlert -> ScheduledService auto-scheduling procedure
-- and triggers.
--
-- Depends on: schema.sql, vehicle_assignment_triggers.sql
-- (calls fn_NextVehicleStatus, defined there).
-- ==========================================================

-- ==========================================
-- TRIGGERS: Maintenance Job Lifecycle Automation
-- ==========================================
-- Refactored to call fn_NextVehicleStatus instead of duplicating the
-- "check ScheduledService" logic that used to live in both this trigger
-- and TRG_VehicleAssignment_AfterUpdate.

DELIMITER //

-- 0. BEFORE INSERT: A vehicle can only be in one workshop bay at a time --
--    reject a new job if one's already open on this VIN. This is the
--    root-cause fix for the overlapping-jobs issue; the fn_NextVehicleStatus
--    rewrite below is the defense-in-depth backstop in case this is ever
--    bypassed (bulk import, race condition, etc.).
CREATE TRIGGER TRG_MaintenanceJob_BeforeInsert
BEFORE INSERT ON MaintenanceJob
FOR EACH ROW
BEGIN
    DECLARE v_OpenJobs INT DEFAULT 0;

    SELECT COUNT(*) INTO v_OpenJobs
    FROM MaintenanceJob
    WHERE VIN = NEW.VIN AND DateClosed IS NULL;

    IF v_OpenJobs > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot open a new maintenance job: this vehicle already has an open job.';
    END IF;
END;
//

-- 0.5 BEFORE UPDATE: Same "historical fact once written" lock as every other
--     record-of-a-thing-that-happened table in this project. VIN, WorkshopID,
--     DateOpened, and ScheduleID are locked. DateClosed and TotalCost stay
--     open (closing/costing the job is the whole point) -- EXCEPT DateClosed
--     can never move back from NOT NULL to NULL. Un-closing a job would
--     silently break the one-open-job-per-VIN gate above, since that gate
--     only runs on INSERT: Job A closes, Job B opens (allowed, A is closed),
--     then un-closing A would leave two jobs open on the same VIN with
--     nothing left to catch it.
CREATE TRIGGER TRG_MaintenanceJob_BeforeUpdate
BEFORE UPDATE ON MaintenanceJob
FOR EACH ROW
BEGIN
    IF NEW.VIN <> OLD.VIN
       OR NEW.WorkshopID <> OLD.WorkshopID
       OR NEW.DateOpened <> OLD.DateOpened
       OR NOT (NEW.ScheduleID <=> OLD.ScheduleID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify VIN, WorkshopID, DateOpened, or ScheduleID on an existing maintenance job.';
    END IF;

    IF OLD.DateClosed IS NOT NULL AND NEW.DateClosed IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot re-open a maintenance job that has already been closed.';
    END IF;
END;
//

-- 1. AFTER INSERT: Force vehicle into 'Under Maintenance' the second a job opens,
--    regardless of what it was doing before (Available, Awaiting Inspection, or
--    still administratively 'In Operation' under an unrelated active assignment --
--    per our discussion, we're deliberately NOT auto-cancelling that assignment).
--
--    FIX (found during seed-data generator design): the original version of
--    this trigger set 'Under Maintenance' unconditionally, with no check on
--    NEW.DateClosed. A job inserted already-closed (e.g. a historical
--    backfill row) would still shove the vehicle into 'Under Maintenance' --
--    but since TRG_MaintenanceJob_AfterUpdate's release logic only fires on
--    an actual OLD.DateClosed IS NULL -> NEW.DateClosed IS NOT NULL
--    transition, a pre-closed insert leaves nothing to ever release it, and
--    a linked ScheduledService (if any) never gets its back-write either.
--    Branching on NEW.DateClosed here mirrors the AfterUpdate logic for the
--    already-closed case, so both entry points (insert-open-then-update, and
--    insert-pre-closed-in-one-shot) leave the vehicle and any linked
--    ScheduledService correctly triaged.
CREATE TRIGGER TRG_MaintenanceJob_AfterInsert
AFTER INSERT ON MaintenanceJob
FOR EACH ROW
BEGIN
    DECLARE v_UnderMaintenanceStatusID SMALLINT UNSIGNED;

    IF NEW.DateClosed IS NULL THEN
        -- Job is genuinely open: vehicle goes into the shop now.
        SELECT VehicleStatusID INTO v_UnderMaintenanceStatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Under Maintenance';

        UPDATE Vehicle
        SET OperationalStatus = v_UnderMaintenanceStatusID
        WHERE VIN = NEW.VIN;
    ELSE
        -- Job arrived already closed (e.g. historical backfill): it never
        -- actually held the vehicle at insert time, so re-triage instead of
        -- forcing Under Maintenance. Mirrors the AfterUpdate release path.
        IF NEW.ScheduleID IS NOT NULL THEN
            UPDATE ScheduledService
            SET Status = 'Completed',
                CompletionDate = DATE(NEW.DateClosed)
            WHERE ScheduleID = NEW.ScheduleID;
        END IF;

        UPDATE Vehicle
        SET OperationalStatus = fn_NextVehicleStatus(NEW.VIN)
        WHERE VIN = NEW.VIN;
    END IF;
END;
//


-- 2. AFTER UPDATE: Release vehicle when the job closes. Also back-writes the
--    linked ScheduledService to Completed, if this job was fulfilling one --
--    otherwise that service sits at 'Scheduled' forever, permanently overdue,
--    and fn_NextVehicleStatus would keep routing this vehicle to
--    'Awaiting Inspection' even after the work that satisfied it is done.
CREATE TRIGGER TRG_MaintenanceJob_AfterUpdate
AFTER UPDATE ON MaintenanceJob
FOR EACH ROW
BEGIN
    IF OLD.DateClosed IS NULL AND NEW.DateClosed IS NOT NULL THEN

        IF NEW.ScheduleID IS NOT NULL THEN
            UPDATE ScheduledService
            SET Status = 'Completed',
                CompletionDate = DATE(NEW.DateClosed)
            WHERE ScheduleID = NEW.ScheduleID;
        END IF;

        UPDATE Vehicle
        SET OperationalStatus = fn_NextVehicleStatus(NEW.VIN)
        WHERE VIN = NEW.VIN;
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- SUPPORTING PROCEDURE + TRIGGERS: Predictive Alert Auto-Scheduling
-- ==========================================
-- When staff escalate a PredictiveAlert to 'Scheduled For Inspection' or
-- 'Urgent Repair Standby', a ScheduledService row gets created automatically
-- -- but NOT for the raw 'Unresolved' telemetry signal itself, since that
-- would auto-schedule every blip before a human's looked at it. Two entry
-- points (insert directly at an escalated status, or update into one) share
-- one procedure so the guard logic only exists in one place.

DELIMITER //

CREATE PROCEDURE sp_AutoScheduleFromAlert(IN p_AlertID INT UNSIGNED, IN p_VIN VARCHAR(17))
BEGIN
    DECLARE v_Existing INT DEFAULT 0;

    -- Guard against re-triggering a duplicate schedule if the alert bounces
    -- between statuses again while one's already open.
    SELECT COUNT(*) INTO v_Existing
    FROM ScheduledService
    WHERE AlertID = p_AlertID AND Status IN ('Scheduled', 'In Progress');

    IF v_Existing = 0 THEN
        INSERT INTO ScheduledService (VIN, ScheduledDate, Reason, AlertID, Status)
        VALUES (
            p_VIN,
            CURDATE(),
            CONCAT('Auto-generated from PredictiveAlert #', p_AlertID),
            p_AlertID,
            'Scheduled'
        );
    END IF;
END;
//

CREATE TRIGGER TRG_PredictiveAlert_AfterInsert
AFTER INSERT ON PredictiveAlert
FOR EACH ROW
BEGIN
    IF NEW.AlertStatus IN ('Scheduled For Inspection', 'Urgent Repair Standby') THEN
        CALL sp_AutoScheduleFromAlert(NEW.AlertID, NEW.VIN);
    END IF;
END;
//

CREATE TRIGGER TRG_PredictiveAlert_AfterUpdate
AFTER UPDATE ON PredictiveAlert
FOR EACH ROW
BEGIN
    IF NEW.AlertStatus IN ('Scheduled For Inspection', 'Urgent Repair Standby')
       AND OLD.AlertStatus <> NEW.AlertStatus THEN
        CALL sp_AutoScheduleFromAlert(NEW.AlertID, NEW.VIN);
    END IF;
END;
//

DELIMITER ;
