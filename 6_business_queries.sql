-- ==========================================================
-- BUSINESS QUERIES  (6 of 6)
-- ==========================================================
-- Scope: read-only reporting/search queries satisfying every bullet in
-- "Use of Fleet Database" (brief p.12-13), plus the extension-scope needs
-- implied by the Part/Supplier/WarrantyClaim/MechanicCertification tables.
--
-- Depends on: schema.sql. No DDL/DML side effects -- pure SELECTs.
--
-- FLEXIBILITY PASS: every query below that takes a `?` is meant to be called
-- with every optional filter available, not just the ones a given screen
-- happens to use that day -- "search by X" requests turned out to cover most
-- of this file, not just the ones originally built that way. Each optional
-- filter uses the `(col = ? OR ? IS NULL)` idiom: bind the same value twice
-- per filter (once for the equality check, once for the NULL check), so
-- "don't filter on this" is just passing NULL for that pair. MySQL prepared
-- statements can't bind a column name into ORDER BY, only values -- dynamic
-- sort-by-column is therefore an app-layer concern (an allow-listed set of
-- sortable columns, string-built after validation), not something these
-- queries attempt to solve themselves.
-- ==========================================================


-- ==========================================
-- SECTION A: FLEET SAFETY OPERATIONS STAFF
-- ==========================================

-- Q1: Incident review feed -- "Review driver incidents". Optional ReviewState /
-- DriverID / DepotID / VIN filters.
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
WHERE (se.ReviewState = ? OR ? IS NULL)
  AND (se.DriverID = ? OR ? IS NULL)
  AND (se.DepotID = ? OR ? IS NULL)
  AND (se.VIN = ? OR ? IS NULL)
ORDER BY se.EventTimestamp DESC;


-- Q2a: High-risk drivers, worst score first -- "Monitor high-risk drivers".
-- Month/Year now optional, defaulting to the current month when not supplied
-- -- previously hardcoded to "this month only".
SELECT
    dr.DriverID, dr.FullName, d.DepotName, dms.Month, dms.Year, dms.Score,
    (SELECT COUNT(*) FROM SafetyEvent se
     WHERE se.DriverID = dr.DriverID
       AND MONTH(se.EventTimestamp) = dms.Month
       AND YEAR(se.EventTimestamp) = dms.Year) AS EventsThisMonth
FROM DriverMonthlySafetyScore dms
JOIN Driver dr ON dr.DriverID = dms.DriverID
JOIN Depot d ON d.DepotID = dms.DepotID
WHERE dms.Month = COALESCE(?, MONTH(CURDATE()))
  AND dms.Year = COALESCE(?, YEAR(CURDATE()))
ORDER BY dms.Score ASC;

-- Q2b: Penalty breakdown for one driver's month -- the "why" behind Q2's
-- score. Separate query rather than folding into Q2 since it's a different
-- grain (per-penalty, not per-driver-month) -- would multiply Q2's rows per
-- driver instead of adding a column. Param: DriverMonthlySafetyScoreID (from Q2).
SELECT pr.RuleType, pr.RuleDescription, dsp.EventID, dsp.PointsDeducted, dsp.DateApplied
FROM DriverScorePenalty dsp
JOIN PenaltyRule pr ON pr.PenaltyRuleID = dsp.PenaltyRuleID
WHERE dsp.DriverMonthlySafetyScoreID = ?
ORDER BY dsp.DateApplied;


-- Q3: Safety trends by depot, month-on-month -- "Compare safety trends
-- between depots". EventType added as its own breakdown dimension
-- (previously only broken out by severity), and every dimension is now
-- also an optional drill-down filter.
SELECT
    d.DepotName, YEAR(se.EventTimestamp) AS Yr, MONTH(se.EventTimestamp) AS Mo,
    et.EventType, sev.SeverityLevel, COUNT(*) AS EventCount
FROM SafetyEvent se
JOIN Depot d ON d.DepotID = se.DepotID
JOIN EventType et ON et.EventTypeID = se.EventTypeID
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE (se.DepotID = ? OR ? IS NULL)
  AND (se.EventTypeID = ? OR ? IS NULL)
  AND (se.SeverityID = ? OR ? IS NULL)
GROUP BY d.DepotName, YEAR(se.EventTimestamp), MONTH(se.EventTimestamp), et.EventType, sev.SeverityLevel
ORDER BY d.DepotName, Yr, Mo, et.EventType, sev.SeverityLevel;


-- Q4: Licence expiry tracker -- "Track licence expiry dates". Optional
-- DriverID / DriverCertificationTypeID filters on top of the existing
-- expiring-within-30-days window.
SELECT
    dr.DriverID, dr.FullName, dct.DriverCertificationType,
    dc.IssueDate, dc.ExpiryDate, dc.Status,
    DATEDIFF(dc.ExpiryDate, CURDATE()) AS DaysUntilExpiry
FROM DriverCertification dc
JOIN Driver dr ON dr.DriverID = dc.DriverID
JOIN DriverCertificationType dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
WHERE dc.Status IN ('Active', 'Reinstated')
  AND dc.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
  AND (dr.DriverID = ? OR ? IS NULL)
  AND (dc.DriverCertificationTypeID = ? OR ? IS NULL)
ORDER BY dc.ExpiryDate ASC;


-- Q5a: Unresolved SAFETY EVENT reviews -- "Monitor unresolved incidents"
-- (review side). Optional VIN / SeverityID filters.
SELECT se.EventID, se.EventTimestamp, se.DriverID, se.VIN, sev.SeverityLevel, se.ReviewState
FROM SafetyEvent se
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE se.ReviewState NOT IN ('Completed', 'No Review Required')
  AND (se.VIN = ? OR ? IS NULL)
  AND (se.SeverityID = ? OR ? IS NULL)
ORDER BY se.EventTimestamp ASC;

-- Q5b: Unresolved PREDICTIVE ALERTS -- "Monitor unresolved incidents"
-- (maintenance-telemetry side). Optional VIN filter.
SELECT pa.AlertID, pa.VIN, at.AlertType, pa.DateGenerated, pa.AlertStatus, pa.ActionTaken
FROM PredictiveAlert pa
JOIN AlertType at ON at.AlertTypeID = pa.AlertTypeID
WHERE pa.AlertStatus <> 'Resolved'
  AND (pa.VIN = ? OR ? IS NULL)
ORDER BY pa.DateGenerated ASC;


-- Q6: Coaching outcomes report -- "Record coaching outcomes". Optional
-- DriverID / Outcome filters.
SELECT cr.CoachingRecordID, cr.DriverID, dr.FullName, cr.CoachingType,
       cr.CoachingDate, cr.CompletionDate, cr.Outcome
FROM CoachingRecord cr
JOIN Driver dr ON dr.DriverID = cr.DriverID
WHERE (cr.DriverID = ? OR ? IS NULL)
  AND (cr.Outcome = ? OR ? IS NULL)
ORDER BY cr.CoachingDate DESC;


-- Q7: Drivers requiring retraining -- "Identify drivers requiring
-- retraining". Same predicate sp_RecomputeDriverEligibility uses
-- internally, exposed as a report. Deliberately Retraining-only: that's the
-- one that actually blocks DrivingEligibility (see
-- 3.driver_eligibility_and_safety_event_triggers.sql). The <=75 Safety
-- Coaching cases -- non-blocking -- already surface through Q6.
SELECT DISTINCT cr.DriverID, dr.FullName, cr.CoachingDate, cr.Outcome
FROM CoachingRecord cr
JOIN Driver dr ON dr.DriverID = cr.DriverID
WHERE cr.CoachingType = 'Retraining' AND cr.Outcome <> 'Passed';


-- Q8: Flexible incident search -- filter by driver, vehicle, depot, event type,
-- severity, date range (all optional). 14 positional params, each bound twice.
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


-- Q10: Drivers ranked by incident count for a given event type, worst first, no
-- cutoff -- "Drivers with repeated speeding incidents". Defaults to speeding when
-- no EventType is given, but now takes an override so any event type can be ranked
-- the same way. NOTE: single param here (not the usual x2 OR-IS-NULL pair) --
-- COALESCE means "NULL = use the default (speeding)", not this file's usual
-- "NULL = don't filter at all" -- there's no "all event types at once" mode here,
-- same as Q32's Status default below. Say if that's wanted too.
SELECT dr.DriverID, dr.FullName, COUNT(*) AS EventCount
FROM SafetyEvent se
JOIN Driver dr ON dr.DriverID = se.DriverID
JOIN EventType et ON et.EventTypeID = se.EventTypeID
WHERE et.EventType = COALESCE(?, 'Excessive speeding')
GROUP BY dr.DriverID, dr.FullName
ORDER BY EventCount DESC;


-- Q11: Vehicles associated with severe incidents -- "Vehicles associated
-- with severe incidents". EventType added as a breakdown dimension, plus
-- optional VIN / SeverityID / EventTypeID drill-down filters.
SELECT v.VIN, v.Model, v.Manufacturer, et.EventType, sev.SeverityLevel, COUNT(*) AS EventCount
FROM SafetyEvent se
JOIN Vehicle v ON v.VIN = se.VIN
JOIN EventType et ON et.EventTypeID = se.EventTypeID
JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
WHERE sev.SeverityLevel IN ('High', 'Critical')
  AND (se.VIN = ? OR ? IS NULL)
  AND (se.SeverityID = ? OR ? IS NULL)
  AND (se.EventTypeID = ? OR ? IS NULL)
GROUP BY v.VIN, v.Model, v.Manufacturer, et.EventType, sev.SeverityLevel
ORDER BY EventCount DESC;


-- Q12: Drivers with expired certifications -- "Drivers with expired
-- certifications". Optional DriverID filter.
SELECT dr.DriverID, dr.FullName, dct.DriverCertificationType, dc.ExpiryDate, dc.Status
FROM DriverCertification dc
JOIN Driver dr ON dr.DriverID = dc.DriverID
JOIN DriverCertificationType dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
WHERE (dc.Status = 'Expired'
       OR (dc.Status IN ('Active', 'Reinstated') AND dc.ExpiryDate < CURDATE()))
  AND (dr.DriverID = ? OR ? IS NULL)
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
-- Mirrors the TRG_MechanicWorkSession_BeforeInsert gate, but as a lookup BEFORE the
-- session exists -- intentional defense-in-depth, same "root-cause fix + backstop"
-- pattern as TRG_MaintenanceJob_BeforeInsert: this steers staff toward eligible
-- mechanics up front, the trigger is what actually guarantees it either way.
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


-- Q19: (removed) -- "Monitor supplier performance", scoped to price competitiveness,
-- is fully covered by Q29 below using the original schema alone (PartSupplier's
-- current price per supplier per part). An earlier version of this query used a
-- separate PartReceipt table for historical price-paid trends; that table was built,
-- tested, and rolled back as unnecessary -- see CHANGELOG_part_receipt.md.


-- Q20: Vehicle downtime review -- "Review vehicle downtime". Recorded Downtime
-- (a job-level fact per the brief, not simply DateClosed - DateOpened) is shown
-- separately from a live elapsed-time ESTIMATE for still-open jobs, since a job
-- that hasn't closed yet may not have its final Downtime figure entered. Both are
-- surfaced rather than one replacing the other, plus a combined total for sorting.
-- Downtime is in hours.
SELECT
    v.VIN, v.Model, v.Manufacturer, d.DepotName,
    COUNT(mj.JobID) AS JobCount,
    SUM(CASE WHEN mj.DateClosed IS NOT NULL THEN mj.Downtime ELSE 0 END) AS RecordedDowntimeHours,
    SUM(CASE WHEN mj.DateClosed IS NULL
             THEN TIMESTAMPDIFF(HOUR, mj.DateOpened, NOW()) ELSE 0 END) AS InProgressEstimateHours,
    SUM(CASE WHEN mj.DateClosed IS NOT NULL
             THEN mj.Downtime ELSE TIMESTAMPDIFF(HOUR, mj.DateOpened, NOW()) END) AS TotalDowntimeHours
FROM MaintenanceJob mj
JOIN Vehicle v ON v.VIN = mj.VIN
JOIN Depot d ON d.DepotID = v.DepotID
GROUP BY v.VIN, v.Model, v.Manufacturer, d.DepotName
ORDER BY TotalDowntimeHours DESC;


-- Q21: Maintenance cost comparison by Manufacturer + Model -- "Compare maintenance costs
-- between vehicle models". Manufacturer here = the factory/plant, not the marketed
-- brand, so grouping by Manufacturer+Model doubles as a plant-quality audit: a factory
-- whose vehicles consistently cost more to maintain is a real signal, distinct from a
-- model-only view where the same model built at different plants gets blended. Optional
-- Manufacturer / Model filters for drilling into one plant or one model specifically.
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
  AND (v.Manufacturer = ? OR ? IS NULL)
  AND (v.Model = ? OR ? IS NULL)
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

-- Q28: Warranty claim tracking -- "Warranty claims linked to specific parts".
-- Optional ClaimSource filter.
SELECT
    wc.ClaimID, wc.ActivityID, mj.JobID, mj.VIN, wc.ClaimSource, wc.ClaimDate,
    wc.Status, wc.ResolutionDate,
    GROUP_CONCAT(p.PartName SEPARATOR ', ') AS PartsCovered
FROM WarrantyClaim wc
JOIN MaintenanceActivity ma ON ma.ActivityID = wc.ActivityID
JOIN MaintenanceJob mj ON mj.JobID = ma.JobID
LEFT JOIN ActivityPart ap ON ap.ClaimID = wc.ClaimID
LEFT JOIN Part p ON p.PartNumber = ap.PartNumber
WHERE (wc.ClaimSource = ? OR ? IS NULL)
GROUP BY wc.ClaimID, wc.ActivityID, mj.JobID, mj.VIN, wc.ClaimSource, wc.ClaimDate,
         wc.Status, wc.ResolutionDate
ORDER BY wc.ClaimDate DESC;


-- Q29: Supplier list per part, primary and backup together as a flat list --
-- "Supplier management" AND "Monitor supplier performance" (price competitiveness --
-- see Q19's note above and CHANGELOG_part_receipt.md). Replaces an earlier pivoted
-- primary-vs-backup layout that broke down once a part had 2+ backups (the primary
-- columns just repeated across rows). Flat is simpler, sorts cleanly by price, and
-- makes "search by part" trivial. Optional PartNumber / IsPrimary filters.
--
-- ON PrimaryPartNumber: PartSupplier.PrimaryPartNumber (schema.sql) is a generated
-- column that exists only so UC_PS_OnePrimaryPerPart can enforce "at most one
-- primary supplier per part" (NULL when IsPrimary=FALSE, since MySQL's UNIQUE
-- allows unlimited NULLs). It CAN be queried -- `WHERE PrimaryPartNumber = ?` is
-- equivalent to `WHERE PartNumber = ? AND IsPrimary = TRUE`, same unique index --
-- but it only ever answers "give me the primary row for part X"; it can't isolate
-- "just the backups" the way a plain IsPrimary filter can. Filtering directly on
-- IsPrimary below instead, since one filter then covers both cases.
SELECT p.PartNumber, p.PartName, s.SupplierID, s.SupplierName, s.DeliveryLeadTime, ps.IsPrimary, ps.UnitCost
FROM PartSupplier ps
JOIN Part p ON p.PartNumber = ps.PartNumber
JOIN Supplier s ON s.SupplierID = ps.SupplierID
WHERE (p.PartNumber = ? OR ? IS NULL)
  AND (ps.IsPrimary = ? OR ? IS NULL)
ORDER BY p.PartName, ps.IsPrimary DESC, ps.UnitCost ASC;


-- Q30: Mechanic certification renewal history, full history not just current -- "the full
-- renewal history retained so past job assignments can be verified against qualifications
-- held at the time". Related to, but not redundant with, Q13b: this is "show me
-- everything about this mechanic's certs", Q13b is "which already-logged work sessions
-- does a Voided cert retroactively break" -- different grain, both earn their keep.
-- Optional Status filter (params: MechanicID, Status).
SELECT m.MechanicID, m.FullName, mct.MechanicCertificationType,
       mc.IssueDate, mc.ExpiryDate, mc.Status, mc.RevocationDate
FROM MechanicCertification mc
JOIN Mechanic m ON m.MechanicID = mc.MechanicID
JOIN MechanicCertificationType mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
WHERE m.MechanicID = ?
  AND (mc.Status = ? OR ? IS NULL)
ORDER BY mct.MechanicCertificationType, mc.IssueDate;


-- Q31: Labour hours per mechanic per activity -- "Labour hours per mechanic". Not a
-- stored column: MechanicWorkSession supports multiple sessions per activity
-- (shifts/breaks) per the schema comment, so this SUM is the only correct source of
-- truth. Optional MechanicID filter, and optional DepotID filter/breakdown -- reached
-- via Mechanic -> Workshop -> Depot, since Mechanic itself only has WorkshopID.
SELECT
    mws.MechanicID, m.FullName, dep.DepotID, dep.DepotName, mws.ActivityID, at.ActivityType,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, mws.StartTime, IFNULL(mws.EndTime, NOW()))) / 60.0, 2) AS TotalLabourHours,
    COUNT(*) AS SessionCount
FROM MechanicWorkSession mws
JOIN Mechanic m ON m.MechanicID = mws.MechanicID
JOIN Workshop w ON w.WorkshopID = m.WorkshopID
JOIN Depot dep ON dep.DepotID = w.DepotID
JOIN MaintenanceActivity ma ON ma.ActivityID = mws.ActivityID
JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
WHERE (mws.MechanicID = ? OR ? IS NULL)
  AND (dep.DepotID = ? OR ? IS NULL)
GROUP BY mws.MechanicID, m.FullName, dep.DepotID, dep.DepotName, mws.ActivityID, at.ActivityType
ORDER BY dep.DepotName, mws.ActivityID, mws.MechanicID;


-- ==========================================
-- SECTION D: GENERAL FLEET OVERVIEW
-- ==========================================

-- Q32: Vehicle availability by depot -- "Managers have reported difficulty tracking
-- vehicle availability". One row per depot per status (reverted from an earlier
-- pivoted dashboard layout with a column per status). Optional DepotID / Status
-- filters; Status defaults to 'Available' when not supplied, since "how many
-- vehicles are free right now" is the actual recurring question -- pass an
-- explicit Status to see any other one. Same COALESCE-default convention as Q10
-- above (NULL = "use the default", not "no filter") -- there's currently no way
-- to get every status back unfiltered in one call. Say if that's wanted too.
SELECT d.DepotName, vs.VehicleStatus, COUNT(*) AS VehicleCount
FROM Vehicle v
JOIN Depot d ON d.DepotID = v.DepotID
JOIN VehicleStatus vs ON vs.VehicleStatusID = v.OperationalStatus
WHERE (d.DepotID = ? OR ? IS NULL)
  AND vs.VehicleStatus = COALESCE(?, 'Available')
GROUP BY d.DepotName, vs.VehicleStatus
ORDER BY d.DepotName, vs.VehicleStatus;


-- Q33: Currently active driver assignments -- "...driver assignments". Already
-- depot-first in sort order; added an optional DepotID filter on top so a
-- depot manager can scope the view to just their own depot.
SELECT
    va.AssignmentID, va.DriverID, dr.FullName, va.VIN, v.Model, d.DepotName,
    va.IssueDate, va.StartDate, va.AssignmentStatus
FROM VehicleAssignment va
JOIN Driver dr ON dr.DriverID = va.DriverID
JOIN Vehicle v ON v.VIN = va.VIN
JOIN Depot d ON d.DepotID = va.DepotID
WHERE va.AssignmentStatus = 'In Operation'
  AND (d.DepotID = ? OR ? IS NULL)
ORDER BY d.DepotName, dr.FullName;
