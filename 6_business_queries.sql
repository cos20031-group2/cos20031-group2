-- ==========================================================
-- BUSINESS QUERIES  (6 of 6)
-- ==========================================================
-- Scope: read-only reporting/search queries satisfying every bullet in
-- "Use of Fleet Database" (brief p.12-13), plus the extension-scope needs
-- implied by the Part/Supplier/WarrantyClaim/MechanicCertification tables.
--
-- Depends on: schema.sql. No DDL/DML side effects -- pure SELECTs.
-- Parameterized queries use `?` positional placeholders (app-bound via
-- prepared statements). Optional-filter queries bind each value twice --
-- once for the equality check, once for the accompanying IS NULL check --
-- a standard idiom for "filter if provided, ignore if NULL".
-- ==========================================================


-- ==========================================
-- SECTION A: FLEET SAFETY OPERATIONS STAFF
-- ==========================================

-- Q1: Incident review feed -- "Review driver incidents"
-- TODO: list and sort out all events that are pending, in review, or completed, with the most recent first. Include all relevant details.
-- TODO: maybe sort by driver, vehicle, depot, etc.?
SELECT
    se.EventID, se.EventTimestamp, se.VIN, v.Model, v.Manufacturer,
    d.DepotName, se.DriverID, dr.FullName AS DriverName,
    et.EventType, sev.SeverityLevel, se.Odometer, se.ReviewState,
    er.ReviewID, ss.FullName AS ReviewerName, er.Status AS ReviewStatus,
    er.Comments, er.Recommendations, er.DateReviewed
FROM SafetyEvent se
JOIN Vehicle v ON v.VIN = se.VIN
JOIN Depot d ON d.DepotID = se.DepotID
JOIN Driver dr ON dr.DriverID = se.DriverID
JOIN EventType et ON et.EventTypeID = se.EventTypeID
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
LEFT JOIN EventReview er ON er.EventID = se.EventID
LEFT JOIN SafetyStaff ss ON ss.ReviewStaffID = er.ReviewerStaffID
ORDER BY se.EventTimestamp DESC;


-- Q2: High-risk drivers this month, worst score first -- "Monitor high-risk drivers"
-- TODO: maybe expand the data into listing out penalty rules applied per driver.
-- TODO: maybe fliter by month and so on too, don't lock it to current month or so on only.
SELECT
    dr.DriverID, dr.FullName, d.DepotName, dms.Month, dms.Year, dms.Score,
    (SELECT COUNT(*) FROM SafetyEvent se
    WHERE se.DriverID = dr.DriverID
       AND MONTH(se.EventTimestamp) = dms.Month
       AND YEAR(se.EventTimestamp) = dms.Year) AS EventsThisMonth
FROM DriverMonthlySafetyScore dms
JOIN Driver dr ON dr.DriverID = dms.DriverID
JOIN Depot d ON d.DepotID = dms.DepotID
WHERE dms.Month = MONTH(CURDATE()) AND dms.Year = YEAR(CURDATE())
ORDER BY dms.Score ASC;


-- Q3: Safety trends by depot, month-on-month -- "Compare safety trends between depots"
-- TODO: a graph would be nice, maybe in app layer.
-- TODO: sort by types of events and severity level.
SELECT
    d.DepotName, YEAR(se.EventTimestamp) AS Yr, MONTH(se.EventTimestamp) AS Mo,
    sev.SeverityLevel, COUNT(*) AS EventCount
FROM SafetyEvent se
JOIN Depot d ON d.DepotID = se.DepotID
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
GROUP BY d.DepotName, YEAR(se.EventTimestamp), MONTH(se.EventTimestamp), sev.SeverityLevel
ORDER BY d.DepotName, Yr, Mo, sev.SeverityLevel;


-- Q4: Licence expiry tracker (expiring within 30 days, or already past) -- "Track licence expiry dates"
-- TODO: sort by driver and/or license type
SELECT
    dr.DriverID, dr.FullName, dct.DriverCertificationType,
    dc.IssueDate, dc.ExpiryDate, dc.Status,
    DATEDIFF(dc.ExpiryDate, CURDATE()) AS DaysUntilExpiry
FROM DriverCertification dc
JOIN Driver dr ON dr.DriverID = dc.DriverID
JOIN DriverCertificationType dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
WHERE dc.Status IN ('Active', 'Reinstated')
  AND dc.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY dc.ExpiryDate ASC;


-- Q5a: Unresolved SAFETY EVENT reviews -- "Monitor unresolved incidents" (review side)
-- TODO: sort by vehicle and possibly serverity level
SELECT se.EventID, se.EventTimestamp, se.DriverID, se.VIN, sev.SeverityLevel, se.ReviewState
FROM SafetyEvent se
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE se.ReviewState NOT IN ('Completed', 'No Review Required')
ORDER BY se.EventTimestamp ASC;

-- Q5b: Unresolved PREDICTIVE ALERTS -- "Monitor unresolved incidents" (maintenance-telemetry side)
-- TODO: search by vehicle
SELECT pa.AlertID, pa.VIN, at.AlertType, pa.DateGenerated, pa.AlertStatus, pa.ActionTaken
FROM PredictiveAlert pa
JOIN AlertType at ON at.AlertTypeID = pa.AlertTypeID
WHERE pa.AlertStatus <> 'Resolved'
ORDER BY pa.DateGenerated ASC;


-- Q6: Coaching outcomes report -- "Record coaching outcomes"
-- TODO: sort by Outcome (Failed, In Progress, Pending, etc.), search by driver
SELECT cr.CoachingRecordID, cr.DriverID, dr.FullName, cr.CoachingType,
       cr.CoachingDate, cr.CompletionDate, cr.Outcome
FROM CoachingRecord cr
JOIN Driver dr ON dr.DriverID = cr.DriverID
ORDER BY cr.CoachingDate DESC;


-- Q7: Drivers requiring retraining -- "Identify drivers requiring retraining"
-- Same predicate sp_RecomputeDriverEligibility uses internally, exposed as a report.
-- NOTE: covereved by TRIGGERs, automatically create coaching record if driver's score below 75 or 50
SELECT DISTINCT cr.DriverID, dr.FullName, cr.CoachingDate, cr.Outcome
FROM CoachingRecord cr
JOIN Driver dr ON dr.DriverID = cr.DriverID
WHERE cr.CoachingType = 'Retraining' AND cr.Outcome <> 'Passed';


-- Q8: Flexible incident search -- filter by driver, vehicle, depot, event type,
-- severity, date range (all optional). 12 positional params, each bound twice.
SELECT se.EventID, se.EventTimestamp, se.DriverID, se.VIN, d.DepotName,
       et.EventType, sev.SeverityLevel, se.Odometer
FROM SafetyEvent se
JOIN Depot d ON d.DepotID = se.DepotID
JOIN EventType et ON et.EventTypeID = se.EventTypeID
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE (se.DriverID = ? OR ? IS NULL)
  AND (se.VIN = ? OR ? IS NULL)
  AND (se.DepotID = ? OR ? IS NULL)
  AND (se.EventTypeID = ? OR ? IS NULL)
  AND (se.SeverityID = ? OR ? IS NULL)
  AND (se.EventTimestamp >= ? OR ? IS NULL)
  AND (se.EventTimestamp <= ? OR ? IS NULL)
ORDER BY se.EventTimestamp DESC;


-- Q9a: A driver's own safety history -- "Drivers view own safety history" (param: DriverID)
SELECT se.EventID, se.EventTimestamp, v.Model, et.EventType, sev.SeverityLevel, se.ReviewState
FROM SafetyEvent se
JOIN Vehicle v ON v.VIN = se.VIN
JOIN EventType et ON et.EventTypeID = se.EventTypeID
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE se.DriverID = ?
ORDER BY se.EventTimestamp DESC;

-- Q9b: A driver's monthly score trend -- "compare monthly safety scores over time" (param: DriverID)
SELECT Year, Month, Score
FROM DriverMonthlySafetyScore
WHERE DriverID = ?
ORDER BY Year, Month;


-- Q10: Drivers ranked by speeding-incident count, worst first, no cutoff --
-- "Drivers with repeated speeding incidents"
-- WOULD BE NICE TO HAVE: count by other event types, not required as of now
SELECT dr.DriverID, dr.FullName, COUNT(*) AS SpeedingEventCount
FROM SafetyEvent se
JOIN Driver dr ON dr.DriverID = se.DriverID
JOIN EventType et ON et.EventTypeID = se.EventTypeID
WHERE et.EventType = 'Excessive speeding'
GROUP BY dr.DriverID, dr.FullName
ORDER BY SpeedingEventCount DESC;


-- Q11: Vehicles associated with severe incidents -- "Vehicles associated with severe incidents"
-- WOULD BE NICE TO HAVE: sort by event type
SELECT v.VIN, v.Model, v.Manufacturer, sev.SeverityLevel, COUNT(*) AS EventCount
FROM SafetyEvent se
JOIN Vehicle v ON v.VIN = se.VIN
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE sev.SeverityLevel IN ('High', 'Critical')
GROUP BY v.VIN, v.Model, v.Manufacturer, sev.SeverityLevel
ORDER BY EventCount DESC;


-- Q12: Drivers with expired certifications -- "Drivers with expired certifications"
-- TODO: search by driver?
SELECT dr.DriverID, dr.FullName, dct.DriverCertificationType, dc.ExpiryDate, dc.Status
FROM DriverCertification dc
JOIN Driver dr ON dr.DriverID = dc.DriverID
JOIN DriverCertificationType dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
WHERE dc.Status = 'Expired'
   OR (dc.Status IN ('Active', 'Reinstated') AND dc.ExpiryDate < CURDATE())
ORDER BY dc.ExpiryDate DESC;


-- Q13a: AUDIT -- vehicle assignments now illegal due to a Voided driver certification.
-- "Drivers operating outside their authorised vehicle categories". The BeforeInsert/
-- BeforeUpdate gates on VehicleAssignment stop this going forward, so this only ever
-- surfaces retroactive breaks: a cert that nominally covered the assignment's StartDate
-- has since been marked Voided, which per schema.sql invalidates ALL past transactions
-- that relied on it.
SELECT
    va.AssignmentID, va.VIN, va.DriverID, dr.FullName, va.StartDate, va.AssignmentStatus,
    dct.DriverCertificationType, dc.DriverCertificationID, dc.IssueDate, dc.ExpiryDate, dc.StatusNotes
FROM VehicleAssignment va
JOIN Vehicle v ON v.VIN = va.VIN
JOIN VehicleCertificationRequirement vcr ON vcr.VehicleCategoryID = v.CategoryID
JOIN DriverCertification dc
    ON dc.DriverID = va.DriverID
   AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
JOIN DriverCertificationType dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
JOIN Driver dr ON dr.DriverID = va.DriverID
WHERE va.StartDate IS NOT NULL
  AND dc.Status = 'Voided'
  AND dc.IssueDate <= va.StartDate
  AND dc.ExpiryDate >= va.StartDate
ORDER BY va.StartDate;

-- Q13b: AUDIT -- mechanic work sessions now illegal due to a Voided mechanic certification.
-- Same pattern applied to MechanicWorkSession / MechanicCertification, per your note that
-- the Voided-invalidates-past-work logic applies to mechanics too.
SELECT
    mws.SessionID, mws.MechanicID, me.FullName, mws.ActivityID, mws.StartTime,
    mct.MechanicCertificationType, mc.MechanicCertificationID, mc.IssueDate, mc.ExpiryDate, mc.StatusNotes
FROM MechanicWorkSession mws
JOIN MaintenanceActivity ma ON ma.ActivityID = mws.ActivityID
JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
JOIN MechanicCertification mc
    ON mc.MechanicID = mws.MechanicID
   AND mc.MechanicCertificationTypeID = at.RequiredMechanicCertification
JOIN MechanicCertificationType mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
JOIN Mechanic me ON me.MechanicID = mws.MechanicID
WHERE mc.Status = 'Voided'
  AND mc.IssueDate <= mws.StartTime
  AND mc.ExpiryDate >= mws.StartTime
ORDER BY mws.StartTime;


-- ==========================================
-- SECTION B: WORKSHOP MANAGEMENT STAFF
-- ==========================================

-- Q14: Predictive alert monitor -- "Monitor predictive maintenance alerts"
SELECT pa.AlertID, pa.VIN, v.Model, at.AlertType, pa.DateGenerated, pa.AlertStatus
FROM PredictiveAlert pa
JOIN Vehicle v ON v.VIN = pa.VIN
JOIN AlertType at ON at.AlertTypeID = pa.AlertTypeID
ORDER BY pa.DateGenerated DESC;


-- Q15: Vehicles requiring urgent repair -- "Identify vehicles requiring urgent repair"
SELECT pa.AlertID, pa.VIN, v.Model, v.Manufacturer, at.AlertType, pa.DateGenerated
FROM PredictiveAlert pa
JOIN Vehicle v ON v.VIN = pa.VIN
JOIN AlertType at ON at.AlertTypeID = pa.AlertTypeID
WHERE pa.AlertStatus = 'Urgent Repair Standby'
ORDER BY pa.DateGenerated ASC;


-- Q16: Workshop workload -- "Track workshop workload"
SELECT
    w.WorkshopID, w.Name,
    SUM(CASE WHEN mj.DateClosed IS NULL THEN 1 ELSE 0 END) AS OpenJobs,
    COUNT(mj.JobID) AS TotalJobsAllTime,
    AVG(CASE WHEN mj.DateClosed IS NOT NULL
             THEN TIMESTAMPDIFF(HOUR, mj.DateOpened, mj.DateClosed) END) AS AvgTurnaroundHours
FROM Workshop w
LEFT JOIN MaintenanceJob mj ON mj.WorkshopID = w.WorkshopID
GROUP BY w.WorkshopID, w.Name
ORDER BY OpenJobs DESC;


-- Q17: Eligible mechanics for a given activity type -- "Allocate mechanics to jobs" (param: ActivityTypeID)
-- Mirrors the TRG_MechanicWorkSession_BeforeInsert gate, but as a lookup BEFORE the session exists.
-- NOTE: Nice to enforce both on the app layer and the database layer
SELECT m.MechanicID, m.FullName, m.WorkshopID, mc.ExpiryDate
FROM Mechanic m
JOIN MechanicCertification mc ON mc.MechanicID = m.MechanicID
JOIN ActivityType at ON at.RequiredMechanicCertification = mc.MechanicCertificationTypeID
WHERE at.ActivityTypeID = ?
  AND m.EmploymentStatus = 'Active'
  AND mc.Status IN ('Active', 'Reinstated')
  AND mc.ExpiryDate > CURDATE()
ORDER BY m.WorkshopID, m.FullName;


-- Q18: Parts usage report -- "Record parts usage"
SELECT
    mj.JobID, ma.ActivityID, at.ActivityType, p.PartNumber, p.PartName,
    ap.QuantityUsed, ap.UnitCost, (ap.QuantityUsed * ap.UnitCost) AS LineCost
FROM ActivityPart ap
JOIN Part p ON p.PartNumber = ap.PartNumber
JOIN MaintenanceActivity ma ON ma.ActivityID = ap.ActivityID
JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
JOIN MaintenanceJob mj ON mj.JobID = ma.JobID
ORDER BY mj.JobID, ma.ActivityID;


-- Q19: Supplier performance -- "Monitor supplier performance"
-- NOTE / SCHEMA GAP: ActivityPart records which PART was used, not which SUPPLIER
-- fulfilled that specific unit -- there's no FK path from WarrantyClaim to Supplier.
-- SupplierWarrantyClaims below is therefore an INFERENCE: it counts Parts-Supplier
-- claims on parts where this supplier is the PRIMARY supplier, assuming primary is
-- who normally fulfils the order. Flag as an estimate, not a hard fact, in any UI.
-- NOTE: May need extra checking in the schema.sql
-- SUGGESTION: a proper PartReceipt/lot table (PartNumber, SupplierID, QuantityReceived, DateReceived, ...), with ActivityPart referencing a specific receipt/lot instead of just a bare SupplierID.
-- SUGGESTION: I'm now wondering how people are supposed to know what parts from what supplier from what order are they from if the table just shows the whole stock, like a does a mechanic have to find the parts, look it up as to where it's from (possibly another table), and then log it?
SELECT
    s.SupplierID, s.SupplierName, s.DeliveryLeadTime,
    COUNT(DISTINCT ps.PartNumber) AS PartsSupplied,
    SUM(CASE WHEN ps.IsPrimary THEN 1 ELSE 0 END) AS PrimaryPartCount,
    COUNT(DISTINCT wc.ClaimID) AS SupplierWarrantyClaims_Estimated
FROM Supplier s
LEFT JOIN PartSupplier ps ON ps.SupplierID = s.SupplierID
LEFT JOIN ActivityPart ap ON ap.PartNumber = ps.PartNumber AND ps.IsPrimary = TRUE
LEFT JOIN WarrantyClaim wc ON wc.ClaimID = ap.ClaimID AND wc.ClaimSource = 'Parts Supplier'
GROUP BY s.SupplierID, s.SupplierName, s.DeliveryLeadTime
ORDER BY SupplierWarrantyClaims_Estimated DESC;


-- Q20: Vehicle downtime review -- "Review vehicle downtime"
-- TODO: For vehicles still under maintenance, maybe we can calculate the downtime using CURDATE()?
SELECT
    v.VIN, v.Model, v.Manufacturer, d.DepotName,
    COUNT(mj.JobID) AS JobCount,
    SUM(mj.Downtime) AS TotalDowntimeHours,
    ROUND(AVG(mj.Downtime), 2) AS AvgDowntimeHoursPerJob
FROM MaintenanceJob mj
JOIN Vehicle v ON v.VIN = mj.VIN
JOIN Depot d ON d.DepotID = v.DepotID
GROUP BY v.VIN, v.Model, v.Manufacturer, d.DepotName
ORDER BY TotalDowntimeHours DESC;


-- Q21: Maintenance cost comparison by Manufacturer + Model -- "Compare maintenance costs
-- between vehicle models". Manufacturer here = the factory/plant (per clarification), not
-- the marketed brand, so grouping by Manufacturer+Model doubles as a plant-quality audit:
-- a factory whose vehicles consistently cost more to maintain is a real signal, distinct
-- from a model-only view where the same model built at different plants gets blended.
-- TODO: sort by model/manufacturer
SELECT
    v.Manufacturer, v.Model,
    COUNT(DISTINCT v.VIN) AS FleetCount,
    COUNT(mj.JobID) AS JobCount,
    SUM(mj.TotalCost) AS TotalCost,
    ROUND(AVG(mj.TotalCost), 2) AS AvgCostPerJob,
    ROUND(SUM(mj.TotalCost) / COUNT(DISTINCT v.VIN), 2) AS AvgCostPerVehicle
FROM Vehicle v
JOIN MaintenanceJob mj ON mj.VIN = v.VIN
WHERE mj.TotalCost IS NOT NULL
GROUP BY v.Manufacturer, v.Model
ORDER BY AvgCostPerVehicle DESC;


-- Q22: Vehicles overdue for service -- "Vehicles overdue for service"
SELECT
    ss.ScheduleID, ss.VIN, v.Model, ss.ScheduledDate, ss.Status, ss.Reason,
    DATEDIFF(CURDATE(), ss.ScheduledDate) AS DaysOverdue
FROM ScheduledService ss
JOIN Vehicle v ON v.VIN = ss.VIN
WHERE ss.Status IN ('Scheduled', 'In Progress') AND ss.ScheduledDate <= CURDATE()
ORDER BY DaysOverdue DESC;


-- Q23: Vehicles with repeated component failures -- "Vehicles with repeated component failures"
SELECT mj.VIN, v.Model, at.ActivityType, COUNT(*) AS RepeatFaultCount
FROM MaintenanceActivity ma
JOIN MaintenanceJob mj ON mj.JobID = ma.JobID
JOIN Vehicle v ON v.VIN = mj.VIN
JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
WHERE ma.RepeatedFaultFlag = TRUE
GROUP BY mj.VIN, v.Model, at.ActivityType
ORDER BY RepeatFaultCount DESC;


-- Q24: Parts below reorder threshold -- "Parts below reorder thresholds"
SELECT PartNumber, PartName, CurrentStock, ReorderThreshold,
       (ReorderThreshold - CurrentStock) AS UnitsBelowThreshold
FROM Part
WHERE CurrentStock < ReorderThreshold
ORDER BY UnitsBelowThreshold DESC;


-- Q25: Vehicles awaiting inspection -- "Vehicles awaiting inspection"
SELECT v.VIN, v.Model, v.Manufacturer, d.DepotName, v.Odometer
FROM Vehicle v
JOIN VehicleStatus vs ON vs.VehicleStatusID = v.OperationalStatus
JOIN Depot d ON d.DepotID = v.DepotID
WHERE vs.VehicleStatus = 'Awaiting Inspection';


-- Q26: Mechanics with required certifications, roster by cert type -- "Mechanics with
-- required certifications"
SELECT mct.MechanicCertificationType, m.MechanicID, m.FullName, m.WorkshopID,
       mc.ExpiryDate, mc.Status
FROM MechanicCertification mc
JOIN Mechanic m ON m.MechanicID = mc.MechanicID
JOIN MechanicCertificationType mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
WHERE mc.Status IN ('Active', 'Reinstated') AND mc.ExpiryDate > CURDATE()
ORDER BY mct.MechanicCertificationType, m.FullName;


-- Q27: Vehicle maintenance / diagnostic / repair history -- "Mechanics need access to:
-- vehicle maintenance history, diagnostic records, previous repair information" (param: VIN)
-- All three bullets are really one drill-down at different grain, so one query serves them.
SELECT
    mj.JobID, mj.DateOpened, mj.DateClosed, w.Name AS WorkshopName,
    ma.ActivityID, at.ActivityType, ma.DiagnosticResult, ma.RepeatedFaultFlag, ma.WarrantyFlag,
    pa.AlertID, aty.AlertType AS LinkedAlertType
FROM MaintenanceJob mj
JOIN Workshop w ON w.WorkshopID = mj.WorkshopID
JOIN MaintenanceActivity ma ON ma.JobID = mj.JobID
JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
LEFT JOIN PredictiveAlert pa ON pa.AlertID = ma.LinkedAlertID
LEFT JOIN AlertType aty ON aty.AlertTypeID = pa.AlertTypeID
WHERE mj.VIN = ?
ORDER BY mj.DateOpened DESC, ma.ActivityID;


-- ==========================================
-- SECTION C: EXTENSION-SCOPE QUERIES
-- ==========================================

-- Q28: Warranty claim tracking -- "Warranty claims linked to specific parts"
-- TODO: sort by claim source
SELECT
    wc.ClaimID, wc.ActivityID, mj.JobID, mj.VIN, wc.ClaimSource, wc.ClaimDate,
    wc.Status, wc.ResolutionDate,
    GROUP_CONCAT(p.PartName SEPARATOR ', ') AS PartsCovered
FROM WarrantyClaim wc
JOIN MaintenanceActivity ma ON ma.ActivityID = wc.ActivityID
JOIN MaintenanceJob mj ON mj.JobID = ma.JobID
LEFT JOIN ActivityPart ap ON ap.ClaimID = wc.ClaimID
LEFT JOIN Part p ON p.PartNumber = ap.PartNumber
GROUP BY wc.ClaimID, wc.ActivityID, mj.JobID, mj.VIN, wc.ClaimSource, wc.ClaimDate,
         wc.Status, wc.ResolutionDate
ORDER BY wc.ClaimDate DESC;


-- Q29: Primary vs. backup supplier pricing comparison -- "Supplier management"
-- One row per (part, backup supplier) pairing; a part can have several backups so the
-- primary columns repeat across those rows -- expected, not a duplication bug.
-- TODO: Maybe seperate the 2 into by IsPrimary?
-- TODO: search by part
SELECT
    p.PartNumber, p.PartName,
    sp.SupplierID AS PrimarySupplierID, sup.SupplierName AS PrimarySupplierName, sp.UnitCost AS PrimaryUnitCost,
    sb.SupplierID AS BackupSupplierID, subp.SupplierName AS BackupSupplierName, sb.UnitCost AS BackupUnitCost
FROM Part p
LEFT JOIN PartSupplier sp ON sp.PartNumber = p.PartNumber AND sp.IsPrimary = TRUE
LEFT JOIN Supplier sup ON sup.SupplierID = sp.SupplierID
LEFT JOIN PartSupplier sb ON sb.PartNumber = p.PartNumber AND sb.IsPrimary = FALSE
LEFT JOIN Supplier subp ON subp.SupplierID = sb.SupplierID
ORDER BY p.PartName;


-- Q30: Mechanic certification renewal history, full history not just current -- "the full
-- renewal history retained so past job assignments can be verified against qualifications
-- held at the time" (param: MechanicID)
-- NOTE: partly coverved by Q13b
SELECT m.MechanicID, m.FullName, mct.MechanicCertificationType,
       mc.IssueDate, mc.ExpiryDate, mc.Status, mc.RevocationDate
FROM MechanicCertification mc
JOIN Mechanic m ON m.MechanicID = mc.MechanicID
JOIN MechanicCertificationType mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
WHERE m.MechanicID = ?
ORDER BY mct.MechanicCertificationType, mc.IssueDate;


-- Q31: Labour hours per mechanic per activity -- "Labour hours per mechanic". Not a stored
-- column: MechanicWorkSession supports multiple sessions per activity (shifts/breaks) per
-- the schema comment, so this SUM is the only correct source of truth.
-- TODO: search by mechanic
-- TODO: would be great if managers could sort by their depot or location
SELECT
    mws.MechanicID, m.FullName, mws.ActivityID, at.ActivityType,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, mws.StartTime, IFNULL(mws.EndTime, NOW()))) / 60.0, 2) AS TotalLabourHours,
    COUNT(*) AS SessionCount
FROM MechanicWorkSession mws
JOIN Mechanic m ON m.MechanicID = mws.MechanicID
JOIN MaintenanceActivity ma ON ma.ActivityID = mws.ActivityID
JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
GROUP BY mws.MechanicID, m.FullName, mws.ActivityID, at.ActivityType
ORDER BY mws.ActivityID, mws.MechanicID;


-- ==========================================
-- SECTION D: GENERAL FLEET OVERVIEW
-- ==========================================

-- Q32: Vehicle availability by depot/status -- "Managers have reported difficulty tracking
-- vehicle availability"
-- TODO: sort by depot and "availible" vehicles.
SELECT d.DepotName, vs.VehicleStatus, COUNT(*) AS VehicleCount
FROM Vehicle v
JOIN Depot d ON d.DepotID = v.DepotID
JOIN VehicleStatus vs ON vs.VehicleStatusID = v.OperationalStatus
GROUP BY d.DepotName, vs.VehicleStatus
ORDER BY d.DepotName, vs.VehicleStatus;


-- Q33: Currently active driver assignments -- "...driver assignments"
-- TODO: maybe also sort by depot.
SELECT
    va.AssignmentID, va.DriverID, dr.FullName, va.VIN, v.Model, d.DepotName,
    va.IssueDate, va.StartDate, va.AssignmentStatus
FROM VehicleAssignment va
JOIN Driver dr ON dr.DriverID = va.DriverID
JOIN Vehicle v ON v.VIN = va.VIN
JOIN Depot d ON d.DepotID = va.DepotID
WHERE va.AssignmentStatus = 'In Operation'
ORDER BY d.DepotName, dr.FullName;
