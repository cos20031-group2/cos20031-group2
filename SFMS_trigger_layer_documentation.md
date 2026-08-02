# SFMS Trigger Layer Documentation

**Context:** This document is the companion to `SFMS_physical_model_and_data_dictionary.md`. While the schema document covers the base tables and constraints, this document details the **five trigger files** that enforce the system's dynamic business logic. 

Each file section includes:
1. **Object Reference:** A complete map of triggers, functions, and procedures.
2. **Key Design Decisions:** The architectural choices and their rationales.
3. **Business Rules Enforced:** How the file maps to the 17 core business rules (R1–R17).

A consolidated traceability table for all 17 rules (both schema-enforced and trigger-enforced) is provided at the end.

---

## File 1: Vehicle Assignment Triggers (`1_vehicle_assignment_triggers.sql`)
Manages the lifecycle of assigning a vehicle to a driver, ensuring safety and compliance checks occur at the exact moment of physical transition.

### Object Reference
| Object | Type | Fires On | Purpose |
| :--- | :--- | :--- | :--- |
| `fn_NextVehicleStatus` | Function | (Called by triggers) | Determines a vehicle's status when released. Checks priority: (1) Open MaintenanceJob, (2) Open VehicleAssignment, (3) Due ScheduledService. |
| `TRG_..._BeforeInsert` | Trigger | `BEFORE INSERT` | Runs the full safety/eligibility gate, but **only** if the assignment is born `'In Operation'` (walk-up). |
| `TRG_..._BeforeUpdate` | Trigger | `BEFORE UPDATE` | Blocks edits to closed trips, enforces legal status transitions, locks core facts once a trip leaves `Pending`, and re-runs safety checks on `Pending → In Operation`. |
| `TRG_..._AfterInsert` | Trigger | `AFTER INSERT` | Flips vehicle to `Active` only if born `'In Operation'`. |
| `TRG_..._AfterUpdate` | Trigger | `AFTER UPDATE` | Flips vehicle to `Active` on `Pending → In Operation`; re-triages via `fn_NextVehicleStatus` on trip completion/cancellation. |

### Key Design Decisions
* **D1.1 — Validation runs at physical transition, not at booking time.**
  * **Decision:** `BeforeInsert` only validates when `AssignmentStatus = 'In Operation'`. `Pending` inserts skip validation.
  * **Rationale:** `Pending` is just a booking. Validating it checks today's rules against a future date (which may change before pickup). Historical backfills landing directly in `Completed` also skip validation so they aren't rejected by current rules.
* **D1.2 — The gate re-runs when a booked trip actually starts.**
  * **Decision:** `BeforeUpdate` re-runs the full validation gate on the `Pending → In Operation` transition.
  * **Rationale:** Time passes between booking and pickup. A cert could expire, or a vehicle could enter maintenance. This transition is the first time the gate runs for an advanced booking.
* **D1.3 — Two distinct levels of historical-fact locking.**
  * **Decision:** Once `Completed`/`Cancelled`, *all* columns are locked. Once leaving `Pending`, only core facts (`VIN`, `DriverID`, `DepotID`, `IssueDate`, `StartDate`) are locked; `Status` and `EndDate` remain open.
  * **Rationale:** Protects the "who/what/when" once the trip is no longer provisional, while still allowing the lifecycle status to progress.
* **D1.4 — Legal transitions are a strict whitelist.**
  * **Decision:** Hardcodes exactly two legal transitions: `Pending → {In Operation, Cancelled}` and `In Operation → {Completed, Cancelled}`.
  * **Rationale:** Enforces a true state machine. Prevents skipping steps (e.g., `Pending → Completed`), which would bypass the pickup gate.
* **D1.7 — Employment status is checked alongside driving eligibility.**
  * **Decision:** Requires `Driver.EmploymentStatus = 'Active'` in addition to `DrivingEligibility = 'Eligible'`.
  * **Rationale:** Aligns with the schema's separation of employment and driving status. A fully eligible driver who is `On Leave` still shouldn't be handed a company vehicle.

### Business Rules Enforced
| Rule | Statement | Mechanism |
| :--- | :--- | :--- |
| **R1** | Vehicles under maintenance cannot be assigned. | Checks `v_VehicleStatus <> 'Available'` at both entry points. |
| **R2** | Drivers must hold *all* required vehicle certs. | `v_MissingCerts` counts missing requirements; any missing cert blocks assignment. |
| **R3** | Expired certs don't count. | Cert-validity subquery explicitly requires `ExpiryDate > CURDATE()`. |
| **R9** | Score ≤ 50 blocks assignment until training. | Reads the cached `DrivingEligibility` flag to enforce the block. |
| **R17** | Historical records survive depot transfers. | Locks `VIN`, `DriverID`, `DepotID`, `IssueDate`, `StartDate` once the assignment leaves `Pending`. |

---

## File 2: Maintenance & Predictive Alerts (`2_maintenance_and_alert_triggers.sql`)
Handles workshop jobs and automatically schedules maintenance based on predictive alerts.

### Object Reference
| Object | Type | Fires On | Purpose |
| :--- | :--- | :--- | :--- |
| `TRG_..._BeforeInsert` | Trigger | `BEFORE INSERT` | Rejects a new job if one is already open (`DateClosed IS NULL`) on this VIN. |
| `TRG_..._BeforeUpdate` | Trigger | `BEFORE UPDATE` | Locks founding facts; blocks un-closing a job (`DateClosed` cannot revert to `NULL`). |
| `TRG_..._AfterInsert` | Trigger | `AFTER INSERT` | If genuinely open: forces `Under Maintenance`. If born closed (historical): completes linked `ScheduledService` and re-triages. |
| `TRG_..._AfterUpdate` | Trigger | `AFTER UPDATE` | On close: completes linked `ScheduledService` and re-triages via `fn_NextVehicleStatus`. |
| `sp_AutoScheduleFromAlert`| Procedure | (Called by triggers) | Inserts a `ScheduledService` row unless one is already open for this alert. |
| `TRG_PredictiveAlert_...` | Triggers | `AFTER INSERT/UPDATE` | Calls `sp_AutoScheduleFromAlert` when an alert escalates to `Scheduled For Inspection` or `Urgent Repair Standby`. |

### Key Design Decisions
* **D2.1 — One open job per VIN: Root-cause gate + defense-in-depth.**
  * **Decision:** `BeforeInsert` rejects overlapping jobs. `fn_NextVehicleStatus` also independently checks for open jobs.
  * **Rationale:** The insert trigger prevents the root cause. The function acts as a backstop if the gate is ever bypassed (e.g., bulk imports).
* **D2.2 — `DateClosed` is irreversible.**
  * **Decision:** Blocks `DateClosed` from reverting from `NOT NULL` to `NULL`.
  * **Rationale:** Un-closing a job would silently bypass the one-open-job gate, potentially leaving two open jobs on the same VIN.
* **D2.3 — Branching on insert prevents historical data bugs.**
  * **Decision:** `AfterInsert` checks if `DateClosed` is already `NOT NULL`. If so, it skips the maintenance flip and just completes linked services.
  * **Rationale:** Prevents historical backfills from permanently locking vehicles in `Under Maintenance` (since the `AfterUpdate` release logic wouldn't fire for a pre-closed insert).
* **D2.4 — Alert-linked jobs back-write their `ScheduledService`.**
  * **Decision:** When a job closes, it marks the linked `ScheduledService` as completed.
  * **Rationale:** Prevents a scheduled service from sitting in "overdue" status forever after the actual work satisfying it has been completed.
* **D2.6 — Duplicate guard is keyed on open status, not mere existence.**
  * **Decision:** `sp_AutoScheduleFromAlert` checks for existing *open* scheduled services, not just *any* service.
  * **Rationale:** Allows an alert to legitimately get a second auto-scheduled service later if the issue recurs after the first service was completed.

### Business Rules Enforced
| Rule | Statement | Mechanism |
| :--- | :--- | :--- |
| **R1** | Vehicles under maintenance cannot be assigned. | **Write side:** This file actually sets `Under Maintenance` when a job opens and clears it when it closes, giving File 1 something to check. |

---

## File 3: Driver Eligibility & Safety Events (`3_driver_eligibility_and_safety_event_triggers.sql`)
Tracks safety incidents, forces reviews for severe events, and calculates penalty points.

### Object Reference
| Object | Type | Fires On | Purpose |
| :--- | :--- | :--- | :--- |
| `sp_RecomputeDriverEligibility`| Procedure | (Called by triggers) | Sole authorized writer of `DrivingEligibility`. Re-derives the full answer from scratch on every call. |
| `TRG_Driver_BeforeUpdate` | Trigger | `BEFORE UPDATE` | Rejects writes to `DrivingEligibility` unless `@sfms_allow_eligibility_write` is set. |
| `TRG_SafetyEvent_BeforeInsert`| Trigger | `BEFORE INSERT` | Forces `ReviewState = 'Pending'` for High/Critical severity. |
| `TRG_SafetyEvent_AfterInsert` | Trigger | `AFTER INSERT` | Calls `sp_RecomputeDriverEligibility` for **Critical** severity only. |
| `sp_EvaluatePenalties...` | Procedure | (Called by trigger) | Cursors through `PenaltyRule` and inserts `DriverScorePenalty` rows for matching rules. |
| `TRG_SafetyEvent_AfterInsert_EvaluatePenalties`| Trigger | `AFTER INSERT` | Calls `sp_EvaluatePenaltiesForEvent`. |
| `TRG_SafetyEvent_BeforeUpdate`| Trigger | `BEFORE UPDATE` | Locks all core incident facts. `ReviewState` can only change via session-flag. |

### Key Design Decisions
* **D3.1 — Eligibility is recomputed from scratch, never patched incrementally.**
  * **Decision:** `sp_RecomputeDriverEligibility` evaluates all disqualifying reasons fresh on every call.
  * **Rationale:** Prevents a scenario where clearing one suspension reason accidentally clears another. The answer is always derived from the current, complete state.
* **D3.2 — "AND-to-Clear" logic for multiple suspension reasons.**
  * **Decision:** A driver becomes `Eligible` only when *all* open disqualifying reasons (e.g., open review AND open retraining) are cleared.
  * **Rationale:** Treats the reasons as independent. A critical-event review and a score-driven retraining have different causes; fixing one shouldn't clear the other.
* **D3.3 — Session-variable guard protects cached columns.**
  * **Decision:** `DrivingEligibility` and `ReviewState` can only be updated if a specific session variable is set to `1` by the authorized trigger/procedure.
  * **Rationale:** MySQL lacks column-level routine permissions. This prevents developers/DBAs from accidentally manually overriding automated safety checks.
* **D3.4 — Severity routing is forced at insert.**
  * **Decision:** `BeforeInsert` unconditionally sets `ReviewState = 'Pending'` for High/Critical events.
  * **Rationale:** Makes it structurally impossible for the app to forget to queue a review for a severe incident.
* **D3.5 — Only Critical severity suspends the driver immediately.**
  * **Decision:** `AfterInsert` calls the eligibility recompute for `Critical` only, even though both High and Critical force a review.
  * **Rationale:** Matches the brief exactly. High events get a review queued but don't immediately suspend the driver.
* **D3.7 — Fails loudly if monthly scores are missing.**
  * **Decision:** `sp_EvaluatePenaltiesForEvent` throws a `SIGNAL` error if the driver's monthly score row doesn't exist.
  * **Rationale:** Forces the monthly initialization job to run first, preventing silent data corruption or incorrect score creation.

### Business Rules Enforced
| Rule | Statement | Mechanism |
| :--- | :--- | :--- |
| **R4** | High/Critical events trigger a review. | `BeforeInsert` forces `ReviewState = 'Pending'`. |
| **R5** | Critical events suspend driver until review/training. | `AfterInsert` triggers recompute; `sp_Recompute...` implements the AND-to-clear logic. |
| **R7** | Scores start at 100, reduced by penalties. | Determines *which* penalties apply and inserts the penalty rows. |
| **R9** | Score ≤ 50 blocks assignment. | The "open retraining" check in the recompute procedure is the mechanism this rule routes through. |
| **R6** | Repeated incidents may require coaching. | `Conditional` penalty rules accrue extra points for repeated incidents, feeding the score that triggers coaching. |

---

## File 4: Event Review, Coaching & Scoring (`4_review_coaching_and_scoring_triggers.sql`)
Manages the downstream consequences of safety events: closing reviews, deducting scores, and mandating coaching/retraining.

### Object Reference
| Object | Type | Fires On | Purpose |
| :--- | :--- | :--- | :--- |
| `fn_EventReviewState` | Function | (Called by triggers) | Aggregates `EventReview` rows to determine `SafetyEvent.ReviewState`. Returns `NULL` if no reviews exist. |
| `TRG_EventReview_BeforeInsert`| Trigger | `BEFORE INSERT` | Blocks a review being born already `Closed`. |
| `TRG_EventReview_BeforeUpdate`| Trigger | `BEFORE UPDATE` | Blocks `Unread → Closed` transition; blocks any edit once `Closed`. |
| `TRG_EventReview_After...` | Triggers | `AFTER INSERT/UPDATE` | Recomputes and back-writes `SafetyEvent.ReviewState`. Calls recompute if fully `Completed`. |
| `TRG_DriverScorePenalty_AfterInsert`| Trigger | `AFTER INSERT` | **The Score Cascade:** Deducts score, creates Coaching (≤75) / Retraining (≤50) records, recomputes eligibility. |
| `TRG_CoachingRecord_...` | Triggers | `AFTER INSERT/UPDATE` | Locks founding facts. Recomputes eligibility if a `Retraining` record's `Outcome` changes to `Passed`. |
| `sp_InitializeMonthlyScores`| Procedure | (Called externally) | Creates a `DriverMonthlySafetyScore` row at 100 for eligible drivers. Idempotent. |

### Key Design Decisions
* **D4.2 — Read-before-close is strictly enforced.**
  * **Decision:** Blocks `Closed` on insert. Blocks `Unread → Closed` on update.
  * **Rationale:** Fulfills the schema's promise that reviewers must actually look at an incident before closing it.
* **D4.5 — The "Score Cascade" handles everything automatically.**
  * **Decision:** When a penalty is inserted, the trigger automatically deducts the score, checks thresholds (≤75 for coaching, ≤50 for retraining), creates those records if needed, and unconditionally recalculates eligibility.
  * **Rationale:** Ensures that the moment a score drops, the correct administrative and safety actions are triggered without relying on the app.
* **D4.6 — Coaching duplicate-guards check for *open* status.**
  * **Decision:** Checks for existing open coaching/retraining records, not just historical existence.
  * **Rationale:** Allows a driver to legitimately be re-enrolled later if a prior requirement was completed.
* **D4.10 — `sp_InitializeMonthlyScores` is safely re-runnable.**
  * **Decision:** Guarded by `NOT EXISTS` and `UNIQUE` constraints; designed to be called multiple times for the same month.
  * **Rationale:** Catches drivers returning from leave mid-month without duplicating rows, ensuring they have a score row before penalties are applied.
* **D4.11 — Drivers without a depot are skipped in monthly scores.**
  * **Decision:** Excludes drivers with `CurrentDepotID IS NULL` from initialization.
  * **Rationale:** They cannot be assigned vehicles or generate safety events yet. Skipping them prevents orphaned score rows.

### Business Rules Enforced
| Rule | Statement | Mechanism |
| :--- | :--- | :--- |
| **R5** | Release valves for Critical event suspension. | Triggers recompute when a review is `Completed` or retraining `Outcome` is `Passed`. |
| **R7** | Score starts at 100, reduced by penalties. | `sp_InitializeMonthlyScores` sets 100; Penalty trigger applies the actual arithmetic deduction. |
| **R8** | Score ≤ 75 requires coaching. | Score cascade creates a non-blocking `Safety Coaching` record. |
| **R9** | Score ≤ 50 requires retraining & blocks assignment. | Score cascade creates blocking `Retraining` record; releases it when `Outcome = 'Passed'`. |
| **R6** | Repeated incidents consequence. | Converts the accumulated low score (from File 3's conditional rules) into a real coaching/retraining record. |

---

## File 5: Workshop Operations (`5_workshop_operations_triggers.sql`)
Manages mechanic work sessions, parts inventory, and warranty claims.

### Object Reference
| Object | Type | Fires On | Purpose |
| :--- | :--- | :--- | :--- |
| `TRG_MechanicWorkSession_BeforeInsert`| Trigger | `BEFORE INSERT` | Requires mechanic to be `Active` and hold the specific cert for the activity. |
| `TRG_MechanicWorkSession_BeforeUpdate`| Trigger | `BEFORE UPDATE` | Locks Mechanic/Activity/StartTime. Only `EndTime` is mutable. |
| `TRG_ActivityPart_BeforeInsert` | Trigger | `BEFORE INSERT` | Rejects usage exceeding `CurrentStock`. Validates `ClaimID` belongs to this activity. |
| `TRG_ActivityPart_AfterInsert` | Trigger | `AFTER INSERT` | Applies the stock deduction. |
| `TRG_ActivityPart_BeforeUpdate` | Trigger | `BEFORE UPDATE` | Locks Activity/Part/Quantity/Cost. Only `ClaimID` may change. |
| `TRG_ActivityPart_AfterDelete` | Trigger | `AFTER DELETE` | Restores the stock deduction. |
| `TRG_WarrantyClaim_BeforeUpdate` | Trigger | `BEFORE UPDATE` | Locks Activity/Source/Date. Status/Resolution stay open. |

### Key Design Decisions
* **D5.1 — Mechanic gate checks employment + specific cert.**
  * **Decision:** Requires `EmploymentStatus = 'Active'` and the exact cert named by `ActivityType.RequiredMechanicCertification`.
  * **Rationale:** Mirrors driver logic. Simpler than the driver gate because an activity requires exactly *one* specific cert, not a set of many.
* **D5.3 — Inventory math is protected by a 3-trigger cycle.**
  * **Decision:** `BeforeInsert` gates sufficient stock. `AfterInsert` deducts stock. `AfterDelete` restores stock.
  * **Rationale:** Checking first prevents negative stock errors. Tying the deduction to the insert ensures the math is perfectly synced. No `AfterUpdate` is needed because quantity is locked (see below).
* **D5.4 — Correcting parts usage means Delete + Re-insert.**
  * **Decision:** Locks `QuantityUsed` and `UnitCost`. If there's a mistake, the row must be deleted and recreated.
  * **Rationale:** Because inventory was already deducted based on the original numbers, silently editing the quantity would break the inventory math.
* **D5.5 — `ClaimID` is validated against the specific activity.**
  * **Decision:** When linking a warranty claim, verifies `WarrantyClaim.ActivityID` matches the current `ActivityID`.
  * **Rationale:** A standard Foreign Key only checks if the claim *exists*. This prevents cross-job data corruption by ensuring it belongs to the *correct job*.

### Business Rules Enforced
| Rule | Statement | Mechanism |
| :--- | :--- | :--- |
| **R13** | Mechanics must hold the required activity cert. | `BeforeInsert` checks the specific cert before allowing a work session. |

---

## Consolidated Business Rule Traceability (R1–R17)

This table maps all 17 business rules to their enforcement layer. 

* **Schema-Only:** 7 rules are handled entirely by database constraints (Foreign Keys, UNIQUE, ENUMs).
* **Trigger-Enforced:** 10 rules require the trigger layer. Some are contained in a single file, while others require coordinated logic across multiple files.

| Rule | The Business Rule | Enforced In | How it Works |
| :--- | :--- | :--- | :--- |
| **R1** | Vehicles under maintenance can't be assigned. | File 1 & File 2 | File 2 sets/clears `Under Maintenance` status; File 1 blocks assignments based on it. |
| **R2** | Drivers must hold *all* required vehicle certs. | File 1 | Checks for missing certs before allowing an assignment. |
| **R3** | Expired certs don't count. | File 1 | The cert check explicitly filters out expired dates. |
| **R4** | High/Critical events trigger a review. | File 3 | Forces the event into a `Pending` review state on insert. |
| **R5** | Critical events suspend driver until review/training. | File 3 & File 4 | File 3 calculates the suspension logic; File 4 triggers the release when review/training is completed. |
| **R6** | Repeated incidents may require coaching/retraining. | File 3 & File 4 | File 3 applies extra points for repeated incidents; File 4 converts low scores into coaching records. |
| **R7** | Scores start at 100 and are reduced by penalties. | File 3 & File 4 | File 4 initializes the 100 score; File 3 determines penalties; File 4 deducts the points. |
| **R8** | Score ≤ 75 requires coaching. | File 4 | Automatically creates a non-blocking coaching record. |
| **R9** | Score ≤ 50 requires retraining & blocks assignment. | File 1, 3, & 4 | File 4 creates the retraining record; File 3 suspends the driver; File 1 blocks the vehicle assignment. |
| **R10** | Alerts don't always create jobs, but stay linked if they do. | **Schema Only** | Handled by nullable Foreign Keys (`LinkedAlertID`). |
| **R11** | Jobs can exist without an alert. | **Schema Only** | Handled by nullable Foreign Keys. |
| **R12** | One workshop per depot. | **Schema Only** | Enforced by a `UNIQUE` constraint on `Workshop.DepotID`. |
| **R13** | Mechanics must hold the required activity cert. | File 5 | Checks the specific cert before allowing a work session. |
| **R14** | Parts have one primary supplier, unlimited backups. | **Schema Only** | Enforced by generated columns and `UNIQUE` constraints. |
| **R15** | Warranty claims record manufacturer vs. parts supplier. | **Schema Only** | Enforced by an `ENUM` constraint on `ClaimSource`. |
| **R16** | Full certification renewal history is retained. | **Schema Only** | Enforced by non-destructive rows and date constraints. |
| **R17** | Historical records survive depot transfers. | Schema & File 1 | Core assignment facts are frozen at write time by triggers. |