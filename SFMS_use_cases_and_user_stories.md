# SFMS Use Cases & User Stories

**Context:** Companion to the Physical Model (schema) and Trigger Layer (business logic) documentation. This document maps the brief's stakeholder needs to specific read queries (`Q#`) and documents the write-side transactional workflows governed by the trigger layer (`D#`, `R#`).

---

## 1. Documentation Standards

### Use Case Template
Every use case follows this structure:
* **ID:** `UC-A#` / `UC-B#` / `UC-C#` / `UC-D#` (Read); `UC-W#.#` (Write, mapped to trigger file).
* **Story:** "As a [actor], I want to [goal], so that [benefit]."
* **Actor(s):** Primary actor; System noted as secondary when triggers execute hidden work.
* **Preconditions:** Required system state before execution.
* **Main Flow:** Happy-path steps.
* **Guards / Exceptions:** Failure paths. **For write use cases, these explicitly cite the trigger rule (`R#`) or design decision (`D#`) that blocks the action.**
* **Postconditions:** Guaranteed state after success.
* **Trace:** Read: `Q#`. Write: Trigger/Procedure name + `D#`.

### Staging Plan
1. **Read:** Fleet Safety Operations Staff (14 UCs)
2. **Read:** Workshop Management Staff (15 UCs)
3. **Read:** Extension-Scope + General Overview (5 UCs)
4. **Write:** Vehicle Assignment lifecycle (File 1) (7 UCs)
5. **Write:** Maintenance Job + Alert lifecycle (File 2) (5 UCs)
6. **Write:** Safety Event lifecycle (File 3) (3 UCs)
7. **Write:** Review/Coaching/Scoring lifecycle (File 4) (5 UCs)
8. **Write:** Workshop Operations lifecycle (File 5) (6 UCs)

---

## 2. Stage 1: Read — Fleet Safety Operations Staff

> **Scope Clarification:** `Q13b` (mechanic-side Voided-cert audit) physically sits in the query file's Section A, but it is a Workshop Management need, not a Fleet Safety need. It is documented in Stage 2 (`UC-B15`) instead.

### UC-A1 — Review Driver Incidents
* **Story:** As Fleet Safety Staff, I want to browse and filter the incident feed, so that I can work through safety events needing review.
* **Actor:** Fleet Safety Staff
* **Preconditions:** Authenticated as `Safety Staff`, `Fleet Manager`, or `Admin`. ≥1 `SafetyEvent` exists.
* **Flow:** 
  1. Open incident feed. 
  2. Apply filters (review state, driver, depot, VIN). 
  3. System runs `Q1` (unset filters passed as `NULL`). 
  4. Display events + review details (via `LEFT JOIN`), newest first.
* **Guards/Exceptions:** 
  * 3a. No matches → empty state. 
  * 4a. No review assigned → review columns display blank.
* **Trace:** `Q1`.

### UC-A2 — Monitor High-Risk Drivers
* **Story:** As Fleet Safety Staff, I want to see drivers ranked by monthly safety score and drill into their penalty breakdown, so that I can prioritize intervention.
* **Actor:** Fleet Safety Staff
* **Preconditions:** Authenticated as above. `sp_InitializeMonthlyScores` has run for the target month.
* **Flow:** 
  1. Open high-risk report (specify month/year). 
  2. System runs `Q2a` (defaults to current month via `COALESCE`). 
  3. Display scores, worst first. 
  4. Select driver to drill down. 
  5. System runs `Q2b` using `DriverMonthlySafetyScoreID`. 
  6. Display penalty breakdown.
* **Guards/Exceptions:** 
  * 2a. No month/year supplied → defaults to current month. 
  * 3a. No score rows exist → empty result.
* **Trace:** `Q2a`, `Q2b`.

### UC-A3 — Compare Safety Trends Between Depots
* **Story:** As Fleet Safety Staff, I want to compare incident counts across depots by month, type, and severity, so that I can spot targeted safety needs.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open trends report. 2. Filter by depot/type/severity. 3. System runs `Q3`. 4. Display counts grouped by depot → year → month → type → severity.
* **Trace:** `Q3`.

### UC-A4 — Track Licence Expiry Dates
* **Story:** As Fleet Safety Staff, I want to see which driver certifications are expiring within 30 days, so that I can follow up before non-compliance.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open expiry tracker. 2. Filter by driver/type. 3. System runs `Q4` (`Status IN ('Active', 'Reinstated') AND ExpiryDate <= CURDATE() + 30`). 4. Display days-until-expiry, soonest first.
* **Guards/Exceptions:** 3b. `Expired`/`Revoked`/`Voided` certs excluded (see `UC-A13` for lapsed certs).
* **Trace:** `Q4`.

### UC-A5 — Monitor Unresolved Incidents
* **Story:** As Fleet Safety Staff, I want a single view of every open safety-event review and unresolved predictive alert, so that nothing falls through the cracks.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open unresolved view. 2. System runs `Q5a` (Reviews: `ReviewState NOT IN ('Completed', 'No Review Required')`) and `Q5b` (Alerts: `AlertStatus <> 'Resolved'`). 3. Display both lists, oldest first.
* **Trace:** `Q5a`, `Q5b`.

### UC-A6 — Record Coaching Outcomes
* **Story:** As Fleet Safety Staff, I want to review coaching/retraining records and outcomes, so that I can track if corrective action is working.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open coaching report. 2. Filter by driver/outcome. 3. System runs `Q6`. 4. Display records, most recent first.
* **Trace:** `Q6`. *(Note: Recording the outcome is a write use case, Stage 7).*

### UC-A7 — Identify Drivers Requiring Retraining
* **Story:** As Fleet Safety Staff, I want a list of every driver with an open retraining requirement, so that I know who is currently blocked from driving.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open retraining report. 2. System runs `Q7` (`CoachingType = 'Retraining' AND Outcome <> 'Passed'`). 3. Display blocked drivers.
* **Trace:** `Q7`. *Mirrors the predicate in `sp_RecomputeDriverEligibility` (File 3, D3.1).*

### UC-A8 — Search and Filter Incident Records
* **Story:** As Fleet Safety Staff, I want to search incidents by any combination of parameters, so that I can investigate specific patterns.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open flexible search. 2. Set filters (driver, VIN, depot, type, severity, dates). 3. System runs `Q8` (14 positional parameters). 4. Display matches, newest first.
* **Trace:** `Q8`.

### UC-A9 — View Own Safety History
* **Story:** As a Driver, I want to view my own logged safety incidents, so that I understand my record.
* **Actor:** Driver
* **Preconditions:** Authenticated as `Driver`, linked via `AppUser.DriverID`.
* **Flow:** 1. Open safety history. 2. System runs `Q9a` using the actor's own `DriverID`. 3. Display events, newest first.
* **Guards/Exceptions:** 2b. Row-level scoping is app-layer, not DB-layer. The app must supply the actor's `DriverID`; the DB `GRANT` is table-wide.
* **Trace:** `Q9a`.

### UC-A10 — Compare Own Monthly Safety Scores Over Time
* **Story:** As a Driver, I want to see how my monthly safety score has changed over time, so that I can tell if I'm improving.
* **Actor:** Driver
* **Flow:** 1. Open score history. 2. System runs `Q9b` using actor's `DriverID`. 3. Display chronological scores.
* **Trace:** `Q9b`.

### UC-A11 — Identify Drivers With Repeated Speeding Incidents
* **Story:** As Fleet Safety Staff, I want to rank drivers by how many times they've committed a specific infraction, so that I can identify repeat offenders.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open repeated-incidents report. 2. Specify event type (defaults to `'Excessive speeding'`). 3. System runs `Q10`. 4. Display drivers ranked by count descending.
* **Trace:** `Q10`.

### UC-A12 — Identify Vehicles Associated With Severe Incidents
* **Story:** As Fleet Safety Staff, I want to see which vehicles keep showing up in high-severity incidents, so that I can investigate vehicle-level factors.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open severe-incident report. 2. Filter by VIN/severity/type. 3. System runs `Q11` (`SeverityLevel IN ('High', 'Critical')`). 4. Display vehicle/type/severity counts, worst first.
* **Trace:** `Q11`.

### UC-A13 — Identify Drivers With Expired Certifications
* **Story:** As Fleet Safety Staff, I want to see every driver whose certification has already lapsed, so that I can stop them from operating vehicles.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open expired-certs report. 2. System runs `Q12` (`Status = 'Expired' OR (Status IN ('Active', 'Reinstated') AND ExpiryDate < CURDATE())`). 3. Display lapsed certs.
* **Trace:** `Q12`.

### UC-A14 — Audit Assignments Against Voided Certifications
* **Story:** As Fleet Safety Staff, I want to audit past vehicle assignments against certifications that have since been voided, so that I can catch retroactively-illegal assignments.
* **Actor:** Fleet Safety Staff
* **Flow:** 1. Open audit report. 2. System runs `Q13a` (joins `VehicleAssignment` to `Voided` certs spanning the assignment's dates). 3. Display affected assignments.
* **Trace:** `Q13a`. *Relies on schema doc §1.15 (Voided vs. Revoked).*

---

## 3. Stage 2: Read — Workshop Management Staff

> **Scope Clarification:** `Q29` (Supplier performance) is a Workshop need but lives in the query file's Section C. `Q13b` (Mechanic Voided-cert audit) is a team extension, not a literal brief bullet. Both are grouped here by stakeholder need.

### UC-B1 — Monitor Predictive Maintenance Alerts
* **Story:** As a Workshop Manager, I want to see every predictive maintenance alert across the fleet, so that I have a single view of vehicle telemetry.
* **Actor:** Workshop Manager
* **Flow:** 1. Open alert monitor. 2. System runs `Q14` (global, no filters). 3. Display all alerts, newest first.
* **Trace:** `Q14`.

### UC-B2 — Identify Vehicles Requiring Urgent Repair
* **Story:** As a Workshop Manager, I want to see which alerts have been escalated to urgent status, oldest first, so that I can prioritize time-critical repairs.
* **Actor:** Workshop Manager
* **Flow:** 1. Open urgent-repair view. 2. System runs `Q15` (`AlertStatus = 'Urgent Repair Standby'`). 3. Display alerts, oldest first.
* **Trace:** `Q15`. *Relies on `sp_AutoScheduleFromAlert` trigger path (File 2, D2.5).*

### UC-B3 — Track Workshop Workload
* **Story:** As a Workshop Manager, I want to compare open-job counts and turnaround times across workshops, so that I can spot overloaded locations.
* **Actor:** Workshop Manager
* **Flow:** 1. Open workload report. 2. System runs `Q16` (aggregates per workshop via `LEFT JOIN`). 3. Display open jobs, total jobs, avg turnaround, busiest first.
* **Trace:** `Q16`.

### UC-B4 — Allocate Mechanics to Jobs
* **Story:** As a Workshop Manager, I want to look up which mechanics are certified for a given activity type before assigning them, so that I don't attempt an assignment the system will reject.
* **Actor:** Workshop Manager
* **Flow:** 1. Select activity type. 2. System runs `Q17`. 3. Display eligible mechanics (active + valid cert), grouped by workshop.
* **Trace:** `Q17`. *Mirrors `TRG_MechanicWorkSession_BeforeInsert` gate (File 5, D5.1).*

### UC-B5 — Record Parts Usage
* **Story:** As a Workshop Manager, I want to review what parts have been used across every job, so that I can track consumption and cost.
* **Actor:** Workshop Manager
* **Flow:** 1. Open parts usage report. 2. System runs `Q18` (global). 3. Display line-item usage and computed costs.
* **Trace:** `Q18`.

### UC-B6 — Monitor Supplier Performance
* **Story:** As a Workshop Manager, I want to compare suppliers per part on price and lead time, so that I can choose the most competitive supplier.
* **Actor:** Workshop Manager
* **Flow:** 1. Open supplier comparison. 2. Filter by part/primary status. 3. System runs `Q29`. 4. Display suppliers sorted by price.
* **Trace:** `Q29`. *Scope limited to price/lead time per schema doc §1.19 (PartReceipt rollback).*

### UC-B7 — Review Vehicle Downtime
* **Story:** As a Workshop Manager, I want to see total downtime per vehicle, including live estimates for open jobs, so that I can identify vehicles out of service too long.
* **Actor:** Workshop Manager
* **Flow:** 1. Open downtime report. 2. System runs `Q20`. 3. Display recorded downtime (closed jobs) + live estimate (open jobs via `TIMESTAMPDIFF`).
* **Trace:** `Q20`.

### UC-B8 — Compare Maintenance Costs Between Vehicle Models
* **Story:** As a Workshop Manager, I want to compare maintenance costs by manufacturer and model, so that I can identify costly vehicles/plants.
* **Actor:** Workshop Manager
* **Flow:** 1. Open cost comparison. 2. Filter by manufacturer/model. 3. System runs `Q21` (only closed jobs with `TotalCost IS NOT NULL`). 4. Display fleet count, total/avg cost.
* **Trace:** `Q21`.

### UC-B9 — Identify Vehicles Overdue for Service
* **Story:** As a Workshop Manager, I want to see every scheduled service that's already past its date, so that I can chase down overdue maintenance.
* **Actor:** Workshop Manager
* **Flow:** 1. Open overdue report. 2. System runs `Q22` (`Status IN ('Scheduled', 'In Progress') AND ScheduledDate <= CURDATE()`). 3. Display days overdue, worst first.
* **Trace:** `Q22`. *Mirrors `fn_NextVehicleStatus` Tier 3 logic (File 1, D1.5).*

### UC-B10 — Identify Vehicles With Repeated Component Failures
* **Story:** As a Workshop Manager, I want to see which vehicles keep failing the same component, so that I can flag a possible lemon.
* **Actor:** Workshop Manager
* **Flow:** 1. Open repeated-failures report. 2. System runs `Q23` (`RepeatedFaultFlag = TRUE`). 3. Display vehicle/activity combinations, worst first.
* **Trace:** `Q23`.

### UC-B11 — Identify Parts Below Reorder Threshold
* **Story:** As a Workshop Manager, I want to see which parts are running low, so that I can reorder before a job is held up.
* **Actor:** Workshop Manager
* **Flow:** 1. Open reorder report. 2. System runs `Q24` (`CurrentStock < ReorderThreshold`). 3. Display parts, worst first.
* **Trace:** `Q24`. *Relies on 3-trigger stock-integrity cycle (File 5, D5.3).*

### UC-B12 — Identify Vehicles Awaiting Inspection
* **Story:** As a Workshop Manager, I want to see every vehicle currently sitting at `Awaiting Inspection`, so that I can schedule the inspection.
* **Actor:** Workshop Manager
* **Flow:** 1. Open awaiting-inspection view. 2. System runs `Q25` (`VehicleStatus = 'Awaiting Inspection'`). 3. Display vehicles.
* **Trace:** `Q25`.

### UC-B13 — Identify Mechanics With Required Certifications
* **Story:** As a Workshop Manager, I want a roster of every mechanic's valid certifications, so that I know who's qualified for what.
* **Actor:** Workshop Manager
* **Flow:** 1. Open cert roster. 2. System runs `Q26` (`Status IN ('Active', 'Reinstated') AND ExpiryDate > CURDATE()`). 3. Display valid certs grouped by type.
* **Trace:** `Q26`.

### UC-B14 — Access Vehicle Maintenance History
* **Story:** As a Mechanic, I want to pull up a vehicle's full maintenance history before working on it, so that I understand what's already been tried.
* **Actor:** Mechanic / Workshop Manager
* **Flow:** 1. Select VIN. 2. System runs `Q27`. 3. Display all jobs, activities, diagnostics, and linked alerts for that VIN, newest first.
* **Trace:** `Q27`.

### UC-B15 — Audit Mechanic Work Sessions Against Voided Certifications
* **Story:** As a Workshop Manager, I want to audit past work sessions against certifications that have since been voided, so that I can catch retroactively-invalid work.
* **Actor:** Workshop Manager
* **Flow:** 1. Open mechanic audit report. 2. System runs `Q13b` (joins `MechanicWorkSession` to `Voided` certs spanning the session's `StartTime`). 3. Display affected sessions.
* **Trace:** `Q13b`. *Team extension, mirror of UC-A14.*

---

## 4. Stage 3: Read — Extension-Scope + General Overview

### UC-C1 — Track Warranty Claims Linked to Specific Parts
* **Story:** As a Workshop Manager, I want to track warranty claims and which parts they cover, so that I can recover costs.
* **Actor:** Workshop Manager
* **Flow:** 1. Open warranty report. 2. Filter by claim source. 3. System runs `Q28` (groups by claim, `GROUP_CONCAT`s parts). 4. Display claims + covered parts.
* **Trace:** `Q28`.

### UC-C2 — Review a Mechanic's Full Certification Renewal History
* **Story:** As a Workshop Manager, I want to see a mechanic's complete certification history, so that I can verify qualifications held at the time of past jobs.
* **Actor:** Workshop Manager
* **Flow:** 1. Select mechanic. 2. System runs `Q30`. 3. Display all cert records (including expired/voided), grouped by type, then issue date.
* **Trace:** `Q30`. *Payoff of schema doc §1.15 (full renewal history retained).*

### UC-C3 — Review Labour Hours Per Mechanic Per Activity
* **Story:** As a Workshop Manager, I want to see total labour hours per mechanic per activity, so that I can track productivity.
* **Actor:** Workshop Manager
* **Flow:** 1. Open labour report. 2. Filter by mechanic/depot. 3. System runs `Q31` (sums `TIMESTAMPDIFF` across sessions). 4. Display hours per mechanic/activity.
* **Trace:** `Q31`.

### UC-D1 — View Vehicle Availability by Depot
* **Story:** As a Fleet Manager, I want to see how many vehicles are available at each depot, so that I can answer "how many vehicles are free right now".
* **Actor:** Fleet Manager
* **Flow:** 1. Open availability view. 2. Specify status (defaults to `'Available'`). 3. System runs `Q32`. 4. Display counts per depot.
* **Trace:** `Q32`.

### UC-D2 — View Currently Active Driver Assignments
* **Story:** As a Fleet Manager, I want to see every vehicle currently out with a driver, so that I know what's in operation right now.
* **Actor:** Fleet Manager
* **Flow:** 1. Open active assignments view. 2. Filter by depot. 3. System runs `Q33` (`AssignmentStatus = 'In Operation'`). 4. Display assignments grouped by depot/driver.
* **Trace:** `Q33`.

---

## 5. Stage 4: Write — Vehicle Assignment Lifecycle (File 1)

*Design Note: In write use cases, the "System" is a secondary actor executing trigger logic. Exception flows document the exact trigger guards (`D#`, `R#`).*

### UC-W1.1 — Book a Vehicle Assignment in Advance
* **Story:** As a Fleet Manager, I want to book a vehicle assignment in advance, so that the vehicle and driver are reserved without running the eligibility gate yet.
* **Actor:** Fleet Manager
* **Preconditions:** Authenticated as `Fleet Manager`/`Admin`. `VIN` and `DriverID` exist.
* **Flow:** 
  1. Select vehicle, driver, depot, issue date. 
  2. Submit with `AssignmentStatus = 'Pending'` (Dates `NULL`). 
  3. `TRG_VehicleAssignment_BeforeInsert` takes no action (gate skips `Pending` per D1.1). 
  4. System confirms; vehicle/driver state untouched.
* **Guards/Exceptions:** 
  * 2a. `CHK_VA_StatusConsistency` requires Dates `NULL` for `Pending`.
* **Trace:** `TRG_VehicleAssignment_BeforeInsert` (no-op), D1.1.

### UC-W1.2 — Create a Walk-Up Assignment
* **Story:** As a Fleet Manager, I want to assign a vehicle immediately, so that I can handle a walk-up request on the spot.
* **Actor:** Fleet Manager, System
* **Preconditions:** Authenticated as above. `StartDate` provided.
* **Flow:** 
  1. Select vehicle, driver, depot, dates. Submit with `Status = 'In Operation'`. 
  2. `BeforeInsert` runs full gate: Vehicle `Available`, Driver `Active` + `Eligible`, all required certs held & unexpired. 
  3. System inserts row. 
  4. `AfterInsert` flips `Vehicle.OperationalStatus` to `Active`.
* **Guards/Exceptions:** 
  * 3a. Vehicle not `Available` → `SIGNAL` (R1). 
  * 3b. Driver not `Active` → `SIGNAL` (D1.7). 
  * 3c. Driver `Suspended` → `SIGNAL` (R9). 
  * 3d. Missing/expired certs → `SIGNAL` (R2, R3).
* **Trace:** `BeforeInsert`, `AfterInsert`. D1.1, D1.7. R1, R2, R3, R9.

### UC-W1.3 — Start a Pending Assignment (Pickup)
* **Story:** As a Fleet Manager, I want to convert a pending booking into an active assignment when the driver arrives, so that the system re-confirms validity at pickup.
* **Actor:** Fleet Manager, System
* **Preconditions:** Assignment exists at `Pending`.
* **Flow:** 
  1. Set `Status = 'In Operation'`, supply `StartDate`. 
  2. `BeforeUpdate` Rule 1 confirms transition. Rule 3 re-runs full gate (D1.2). 
  3. System updates. 
  4. `AfterUpdate` flips vehicle to `Active`.
* **Guards/Exceptions:** 
  * 2a. `StartDate` missing → `SIGNAL`. 
  * 3a. Illegal transition → `SIGNAL` (D1.4). 
  * 4a-d. Gate failures (vehicle in maintenance, driver on leave/suspended, cert expired) → `SIGNAL` (D1.2; R1, R2, R3, R9).
* **Trace:** `BeforeUpdate` (Rules 1, 3), `AfterUpdate`. D1.2, D1.4.

### UC-W1.4 — Complete an Assignment
* **Story:** As a Fleet Manager, I want to mark an assignment as completed, so that the vehicle becomes available or gets routed to maintenance/inspection.
* **Actor:** Fleet Manager, System
* **Preconditions:** Assignment exists at `In Operation`.
* **Flow:** 
  1. Set `Status = 'Completed'`, supply `EndDate`. 
  2. `BeforeUpdate` Rule 1 confirms transition; Rule 2 confirms founding facts (`VIN`, `DriverID`, etc.) unchanged. 
  3. System updates. 
  4. `AfterUpdate` calls `fn_NextVehicleStatus` to re-triage vehicle (D1.5).
* **Guards/Exceptions:** 
  * 2a. `EndDate < StartDate` → `SIGNAL`. 
  * 3a. Founding facts changed → `SIGNAL` (D1.3). 
  * 5a. Open `MaintenanceJob` exists → vehicle goes `Under Maintenance` (D1.5).
* **Trace:** `BeforeUpdate` (Rules 1, 2), `AfterUpdate`, `fn_NextVehicleStatus`. D1.3, D1.5.

### UC-W1.5 — Cancel a Pending Assignment
* **Story:** As a Fleet Manager, I want to cancel a booking that was never picked up, so that the reservation is cleared.
* **Actor:** Fleet Manager
* **Flow:** 
  1. Set `Status = 'Cancelled'`, supply `EndDate`. 
  2. `BeforeUpdate` Rule 1 confirms transition. 
  3. System updates. 
  4. `AfterUpdate` takes no action on vehicle (explicit no-op, D1.6).
* **Trace:** `BeforeUpdate` (Rule 1), `AfterUpdate` (no-op). D1.6.

### UC-W1.6 — Cancel an In-Operation Assignment (Abort)
* **Story:** As a Fleet Manager, I want to cancel an active assignment, so that I can record an early return and get the vehicle back into rotation.
* **Actor:** Fleet Manager, System
* **Flow:** Identical to UC-W1.4, but sets `Status = 'Cancelled'`. Vehicle is re-triaged via `fn_NextVehicleStatus` exactly as if it were completed.
* **Trace:** `BeforeUpdate`, `AfterUpdate`, `fn_NextVehicleStatus`. D1.3, D1.5, D1.6.

### UC-W1.7 — Attempt to Modify a Terminal Assignment (System Guard)
* **Story:** As a Fleet Manager, I want the system to refuse any edit to a completed/cancelled assignment, so that the historical record is immutable.
* **Actor:** System (Enforcer)
* **Guards/Exceptions:** 
  * Any `UPDATE` on a terminal row → `BeforeUpdate` Rule 0 `SIGNAL`s immediately. No "undo" exists; corrections require a new assignment. (D1.3).
* **Trace:** `BeforeUpdate` (Rule 0). D1.3.

---

## 6. Stage 5: Write — Maintenance Job + Alert Lifecycle (File 2)

### UC-W2.1 — Open a Maintenance Job
* **Story:** As a Workshop Manager, I want to open a new maintenance job, so that I can track work and mark the vehicle unavailable.
* **Actor:** Workshop Manager, System
* **Preconditions:** No other job open on this VIN.
* **Flow:** 
  1. Select vehicle, workshop, optional `ScheduleID`. Submit with `DateClosed = NULL`. 
  2. `BeforeInsert` confirms no other job is open (D2.1). 
  3. System inserts. 
  4. `AfterInsert` forces `Vehicle.OperationalStatus = 'Under Maintenance'`.
* **Guards/Exceptions:** 
  * 3a. Another job already open → `SIGNAL` (D2.1).
* **Trace:** `BeforeInsert`, `AfterInsert`. D2.1.

### UC-W2.2 — Backfill a Historical Maintenance Job
* **Story:** As a Workshop Manager, I want to insert a job that's already closed, so that I can record historical work without falsely parking the vehicle in maintenance.
* **Actor:** Workshop Manager, System
* **Flow:** 
  1. Submit complete historical record (`DateClosed` set). 
  2. `BeforeInsert` confirms no other job is open. 
  3. System inserts. 
  4. `AfterInsert` detects `DateClosed IS NOT NULL`: completes linked `ScheduledService` (if any), re-triages vehicle via `fn_NextVehicleStatus` (skips `Under Maintenance` flip) (D2.3).
* **Guards/Exceptions:** 
  * 2a. Another job open → `SIGNAL` (D2.1). 
  * 4b. `DateClosed` set but `TotalCost` missing → `SIGNAL` (`CHK_MJ_ClosedHasCost`).
* **Trace:** `BeforeInsert`, `AfterInsert` (pre-closed branch). D2.1, D2.3, D2.4.

### UC-W2.3 — Close a Maintenance Job
* **Story:** As a Workshop Manager, I want to close out a job, so that the vehicle is released and the scheduled service is marked done.
* **Actor:** Workshop Manager, System
* **Preconditions:** Job exists with `DateClosed IS NULL`.
* **Flow:** 
  1. Set `DateClosed` and `TotalCost`. 
  2. `BeforeUpdate` confirms founding facts unchanged. 
  3. System updates. 
  4. `AfterUpdate` detects `NULL → NOT NULL`: completes linked `ScheduledService`, re-triages vehicle via `fn_NextVehicleStatus`.
* **Guards/Exceptions:** 
  * 3a. Founding facts changed → `SIGNAL`.
* **Trace:** `BeforeUpdate`, `AfterUpdate`, `fn_NextVehicleStatus`. D2.4.

### UC-W2.4 — Attempt to Re-Open a Closed Job (System Guard)
* **Story:** As a Workshop Manager, I want the system to refuse un-closing a job, so that the one-open-job guarantee isn't silently broken.
* **Actor:** System (Enforcer)
* **Guards/Exceptions:** 
  * Attempt to set `DateClosed` back to `NULL` → `BeforeUpdate` `SIGNAL`s. Closing is one-directional (D2.2).
* **Trace:** `BeforeUpdate`. D2.2.

### UC-W2.5 — Escalate a Predictive Alert to Trigger Auto-Scheduling
* **Story:** As a Workshop Manager, I want an escalated alert to automatically create a scheduled service, so that I don't have to manually schedule follow-up work.
* **Actor:** Workshop Manager, System
* **Flow:** 
  1. Update `AlertStatus` to `'Scheduled For Inspection'` or `'Urgent Repair Standby'` (or insert directly at this status). 
  2. `AfterUpdate`/`AfterInsert` detects escalation, calls `sp_AutoScheduleFromAlert`. 
  3. Procedure checks for existing open schedule; if none, inserts new `ScheduledService` at `'Scheduled'`.
* **Guards/Exceptions:** 
  * 2a. Status left at `Unresolved`/`Acknowledged` → no scheduling call (D2.5). 
  * 4a. Open schedule already exists for this alert → no duplicate created (D2.6).
* **Trace:** `AfterInsert`/`AfterUpdate`, `sp_AutoScheduleFromAlert`. D2.5, D2.6.

---

## 7. Stage 6: Write — Safety Event Lifecycle (File 3)

### UC-W3.1 — Log a Safety Event
* **Story:** As Fleet Safety Staff, I want to log a safety event, so that it is recorded, routed for review if serious, and reflected in the driver's score.
* **Actor:** Fleet Safety Staff / Telematics, System
* **Preconditions:** `DriverMonthlySafetyScore` row exists for the event's month/year (via `sp_InitializeMonthlyScores`).
* **Flow:** 
  1. Submit event details. 
  2. `BeforeInsert` checks severity: High/Critical forces `ReviewState = 'Pending'` (D3.4). 
  3. System inserts. 
  4. `AfterInsert` checks severity: Critical only calls `sp_RecomputeDriverEligibility` (D3.5). 
  5. `AfterInsert_EvaluatePenalties` calls `sp_EvaluatePenaltiesForEvent`: matches `PenaltyRule`s, inserts `DriverScorePenalty` rows (Base/Conditional logic).
* **Guards/Exceptions:** 
  * 5a. No monthly score row exists → `SIGNAL`, entire insert rolls back (D3.7). 
  * 5b. `Conditional` rule has `TimeWindowMonths <> 1` → `SIGNAL` (D3.8).
* **Trace:** `BeforeInsert`, `AfterInsert`, `EvaluatePenalties`, `sp_Recompute...`, `sp_Evaluate...`. D3.1–D3.10. R4, R5, R6, R7, R9.

### UC-W3.2 — Attempt to Modify a Logged Safety Event (System Guard)
* **Story:** As Fleet Safety Staff, I want the system to refuse changes to an event's core facts or direct edits to its review state.
* **Actor:** System (Enforcer)
* **Guards/Exceptions:** 
  * Change core facts (`DriverID`, `VIN`, `SeverityID`, etc.) → `SIGNAL` unconditionally (D3.11). 
  * Change `ReviewState` directly without session flag → `SIGNAL` (D3.3). Must use `EventReview` workflow.
* **Trace:** `BeforeUpdate`. D3.11, D3.3.

### UC-W3.3 — Attempt to Directly Write Driver Eligibility (System Guard)
* **Story:** As a developer/DBA, I want the system to refuse a direct write to a driver's eligibility flag, so that the cache doesn't drift.
* **Actor:** System (Enforcer)
* **Guards/Exceptions:** 
  * `UPDATE Driver SET DrivingEligibility = ...` without `@sfms_allow_eligibility_write` → `SIGNAL` (D3.3).
* **Trace:** `TRG_Driver_BeforeUpdate`. D3.3.

---

## 8. Stage 7: Write — Review, Coaching & Scoring Lifecycle (File 4)

### UC-W4.1 — Assign and Progress an Event Review
* **Story:** As Fleet Safety Staff, I want to progress a review from unread to closed, so that serious incidents are investigated and driver eligibility is resolved.
* **Actor:** Fleet Safety Staff, System
* **Flow:** 
  1. Insert `EventReview` at `Unread`. `AfterInsert` computes aggregate → `SafetyEvent.ReviewState = 'Assigned'`. 
  2. Update to `Read` (supply `DateReviewed`). Aggregate → `'In Review'`. 
  3. Update to `Commented` (supply `Comments`). Aggregate stays `'In Review'`. 
  4. Update to `Closed`. If last reviewer, aggregate → `'Completed'`. System calls `sp_RecomputeDriverEligibility`.
* **Guards/Exceptions:** 
  * 1a. Multiple reviewers → `'Completed'` only reported when *all* reach `Closed` (D4.1).
* **Trace:** `AfterInsert`/`AfterUpdate`, `fn_EventReviewState`, `sp_Recompute...`. D4.1, D4.3, D4.4. R5.

### UC-W4.2 — Attempt to Close a Review Without Reading It (System Guard)
* **Story:** As Fleet Safety Staff, I want the system to prevent closing a review without reading it, and prevent editing a closed review.
* **Actor:** System (Enforcer)
* **Guards/Exceptions:** 
  * Insert review already `Closed` → `SIGNAL` (D4.2). 
  * Update `Unread → Closed` → `SIGNAL` (D4.2). 
  * Update any column on a `Closed` review → `SIGNAL` (D4.2).
* **Trace:** `BeforeInsert`, `BeforeUpdate`. D4.2.

### UC-W4.3 — Apply a Penalty and Trigger the Score Cascade
* **Story:** As the automated penalty engine, I want a new penalty to immediately decrement the score and create coaching/retraining requirements if thresholds are crossed.
* **Actor:** System
* **Flow:** 
  1. Insert `DriverScorePenalty`. 
  2. `AfterInsert` decrements `DriverMonthlySafetyScore.Score`. 
  3. If score ≤ 75: ensures open `Safety Coaching` record exists. 
  4. If score ≤ 50: ensures open `Retraining` record exists. 
  5. Unconditionally calls `sp_RecomputeDriverEligibility`.
* **Guards/Exceptions:** 
  * 4a/5a. Open record already exists → no duplicate created (D4.6).
* **Trace:** `TRG_DriverScorePenalty_AfterInsert`, `sp_Recompute...`. D4.5, D4.6. R7, R8, R9, R6.

### UC-W4.4 — Record a Coaching or Retraining Outcome
* **Story:** As Fleet Safety Staff, I want to record the outcome of a retraining assignment, so that a driver who passed gets their eligibility cleared.
* **Actor:** Fleet Safety Staff, System
* **Flow:** 
  1. Update `CoachingRecord.Outcome` to `'Passed'`, supply `CompletionDate`. 
  2. `BeforeUpdate` confirms founding facts unchanged. 
  3. `AfterUpdate` detects `Retraining` + `Outcome` changed → calls `sp_RecomputeDriverEligibility`.
* **Guards/Exceptions:** 
  * 2a. Founding facts changed → `SIGNAL` (D4.8). 
  * 3a. `Outcome = 'Failed'` → recompute runs, but driver remains `Suspended` (D3.1).
* **Trace:** `BeforeUpdate`, `AfterUpdate`, `AfterInsert`, `sp_Recompute...`. D4.7, D4.8, D4.9. R9.

### UC-W4.5 — Initialize Monthly Driver Scores
* **Story:** As a system administrator, I want to initialize this month's safety score for every eligible driver, so that the penalty engine has a row to attach deductions to.
* **Actor:** System Admin / Scheduled Job
* **Flow:** 
  1. Call `sp_InitializeMonthlyScores(Month, Year)`. 
  2. For every driver `<> 'Terminated'` with a `CurrentDepotID` and no existing row: insert `DriverMonthlySafetyScore` at 100.
* **Guards/Exceptions:** 
  * 2b. Driver has no `CurrentDepotID` → skipped (D4.11). 
  * 2c. Called again for same month → `NOT EXISTS` guard prevents duplicates (D4.10).
* **Trace:** `sp_InitializeMonthlyScores`. D4.10, D4.11. R7.

---

## 9. Stage 8: Write — Workshop Operations Lifecycle (File 5)

### UC-W5.1 — Log a Mechanic Work Session
* **Story:** As a Mechanic, I want to log a work session, so that labour time is tracked and only certified mechanics get credited.
* **Actor:** Mechanic / Workshop Manager, System
* **Flow:** 
  1. Select mechanic, activity, `StartTime`. 
  2. `BeforeInsert` checks: Mechanic `Active` + holds specific cert required by `ActivityType`. 
  3. System inserts.
* **Guards/Exceptions:** 
  * 2a. Mechanic not `Active` → `SIGNAL` (D5.7). 
  * 2b. Lacks specific cert / cert expired → `SIGNAL` (R13).
* **Trace:** `BeforeInsert`. D5.1, D5.7. R13.

### UC-W5.2 — Close Out a Work Session
* **Story:** As a Mechanic, I want to clock out of a work session, so that actual time spent is recorded.
* **Actor:** Mechanic
* **Preconditions:** Session exists with `EndTime IS NULL`.
* **Flow:** 
  1. Set `EndTime`. 
  2. `BeforeUpdate` confirms `MechanicID`, `ActivityID`, `StartTime` unchanged. 
  3. System updates.
* **Guards/Exceptions:** 
  * 3a. Founding facts changed → `SIGNAL`. Correction requires closing and logging a new session (D5.2).
* **Trace:** `BeforeUpdate`. D5.2.

### UC-W5.3 — Record Parts Usage on an Activity
* **Story:** As a Mechanic, I want to record parts used, so that inventory stays accurate.
* **Actor:** Mechanic / Workshop Manager, System
* **Flow:** 
  1. Select activity, part, quantity, cost. Optional `ClaimID`. 
  2. `BeforeInsert` checks `CurrentStock >= QuantityUsed`; validates `ClaimID` belongs to this activity. 
  3. System inserts. 
  4. `AfterInsert` decrements `Part.CurrentStock`.
* **Guards/Exceptions:** 
  * 2a. Exceeds stock → `SIGNAL` (D5.3). 
  * 2b. `ClaimID` belongs to different activity → `SIGNAL` (D5.5).
* **Trace:** `BeforeInsert`, `AfterInsert`. D5.3, D5.5.

### UC-W5.4 — Update the Warranty Claim Link on a Parts-Usage Record
* **Story:** As a Workshop Manager, I want to attach a warranty claim to a parts-usage record after the fact.
* **Actor:** Workshop Manager
* **Flow:** 
  1. Set/change `ClaimID`. 
  2. `BeforeUpdate` confirms `ActivityID`, `PartNumber`, `QuantityUsed`, `UnitCost` unchanged; re-validates new `ClaimID`. 
  3. System updates.
* **Guards/Exceptions:** 
  * 3a. Founding facts (Quantity/Cost) changed → `SIGNAL`. Correction requires delete + re-insert to preserve stock math (D5.4).
* **Trace:** `BeforeUpdate`. D5.4, D5.5.

### UC-W5.5 — Remove a Parts-Usage Record
* **Story:** As a Workshop Manager, I want to delete an incorrect parts-usage record, so that the stock count is restored.
* **Actor:** Workshop Manager, System
* **Flow:** 
  1. Delete `ActivityPart` row. 
  2. `AfterDelete` restores `Part.CurrentStock` by `QuantityUsed`. 
  3. Actor records correct usage as new row (UC-W5.3).
* **Trace:** `AfterDelete`. D5.3.

### UC-W5.6 — File and Progress a Warranty Claim
* **Story:** As a Workshop Manager, I want to file a warranty claim and track it to resolution.
* **Actor:** Workshop Manager
* **Flow:** 
  1. Insert claim (`Status` defaults to `'Pending'`). 
  2. Later, update `Status` to `Approved`/`Rejected`/`Settled`, supply `ResolutionDate`. 
  3. `BeforeUpdate` confirms `ActivityID`, `ClaimSource`, `ClaimDate` unchanged.
* **Guards/Exceptions:** 
  * 4a. Founding facts changed → `SIGNAL` (D5.6).
* **Trace:** `BeforeUpdate`. D5.6.

---

## 10. Summary Tally

| Stage | Scope | Use Cases |
| :--- | :--- | :--- |
| **1** | Read — Fleet Safety Operations Staff | 14 |
| **2** | Read — Workshop Management Staff | 15 |
| **3** | Read — Extension-scope + General Overview | 5 |
| **4** | Write — Vehicle Assignment (File 1) | 7 |
| **5** | Write — Maintenance Job + Alert (File 2) | 5 |
| **6** | Write — Safety Event (File 3) | 3 |
| **7** | Write — Review/Coaching/Scoring (File 4) | 5 |
| **8** | Write — Workshop Operations (File 5) | 6 |
| **Total** | | **60** |

* Every read use case traces to a specific `Q#` in `6_business_queries.sql`.
* Every write use case traces to specific trigger(s)/procedure(s) and design decision(s) (`D#`) in the Trigger Layer documentation.
* Every business rule from R1–R17 is referenced from at least one use case in this document.