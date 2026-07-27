# Smart Fleet Management System Database — Physical Model Write-Up & Full Data Dictionary

Scope: `schema.sql` only. Trigger-enforced behavior (state-machine guards,
cascading recomputation) is documented separately in the trigger-layer docs;
this document references it only where needed to explain a physical design
choice.

This document has four parts:

- **Part 1** — the non-obvious conceptual → physical translation decisions,
  for both the team and evaluators, grouped by theme.
- **Part 2** — business rule → schema traceability: every brief requirement
  mapped to the specific constraint or design decision that enforces it.
- **Part 3** — the full data dictionary: every table, every column.
- **Part 4** — DBMS-level security (the `CREATE USER` / `GRANT` layer).

---

# Part 1: Key Architectural & Physical Design Decisions

### Key & Identity Strategy

## 1.1 Primary Key Strategy: Surrogate vs. Natural Keys


**Chosen:** two patterns coexist deliberately.

- **Surrogate `AUTO_INCREMENT` PKs** for every lookup/reference table and every
  pure transaction/event table with no pre-existing business code.
- **Natural (business) keys** as the PK for five entities: `Vehicle.VIN`,
  `Driver.DriverID`, `Mechanic.MechanicID`, `SafetyEvent.EventID`,
  `MaintenanceJob.JobID` — all `VARCHAR`, all format-constrained
  (`CHK_Vehicle_VIN_Length`, `CHK_Driver_DriverID_Prefix`,
  `CHK_Mechanic_MechanicID_Prefix`, `CHK_SE_EventID_Prefix`,
  `CHK_MJ_JobID_Prefix`).

**Why:** the brief's own example data (the paper-form Driver Safety Event Log,
p.8, and the maintenance job records, p.10) already presents these identifiers
as meaningful codes staff use operationally — `E091`, `D-112`, `M1021`,
`ME-12`, plate-style vehicle references — not arbitrary row numbers. These are
also exactly the entities looked up, filtered, and cross-referenced *by that
code* throughout `6_business_queries.sql`. Making the business code the PK
avoids a redundant surrogate-id + unique-code pair where the code is already
unique, stable, and what everyone actually searches by.

**Alternative considered:** pure-surrogate everywhere. Rejected for these five
tables — it would double every FK/join path for no integrity benefit, since
the natural key is already guaranteed unique.

## 1.2 Composite Keys vs. Surrogate Key + UNIQUE Constraint


**The rule applied consistently across the schema:** how many columns make up
a table's natural uniqueness determines whether it gets a composite PK or a
surrogate PK with the uniqueness enforced separately.

- **2 columns → composite PK.** `PartSupplier (PartNumber, SupplierID)`,
  `ActivityPart (ActivityID, PartNumber)`, `VehicleCertificationRequirement
  (VehicleCategoryID, DriverCertificationTypeID)` — pure M:N junction tables
  where the pair *is* the natural identity of the association, and nothing
  else references "this specific pairing" by a single id. A composite PK
  here is simple to reference and simple to reason about.

- **3+ columns → surrogate PK, uniqueness enforced via `UNIQUE`.**
  `DriverCertification` (`UNIQUE(DriverID, DriverCertificationTypeID,
  IssueDate, ExpiryDate)`), `MechanicCertification` (same pattern), and
  `DriverMonthlySafetyScore` (`UNIQUE(DriverID, Month, Year)`) all have a
  natural key wide enough that using it as the actual PK would be painful:
  every table that needs to reference one specific certification or one
  specific monthly score (`DriverScorePenalty` → `DriverMonthlySafetyScoreID`,
  for instance) would otherwise have to carry 3–4 FK columns instead of one.
  The surrogate PK keeps those downstream FKs to a single column, while the
  `UNIQUE` constraint still fully guarantees the business rule ("one score row
  per driver per month," "no duplicate overlapping certification record").

**Alternative considered:** a surrogate PK on the 2-column junction tables
too, for consistency. Rejected — none of those relationships is itself
referenced by any other table's FK, so a surrogate key there would add a
column with no purpose; the composite PK is strictly simpler and loses
nothing.

## 1.3 Integer Type Sizing


**Chosen:** PK/FK width scaled to each table's realistic row-count ceiling
instead of defaulting to `INT` everywhere:

| Width | Used for | Reasoning |
|---|---|---|
| `SMALLINT UNSIGNED` | `Location`, `VehicleCategory`, `VehicleStatus`, `EventType`, `EventSeverity`, `AlertType`, `MechanicCertificationType`, `Depot`, `Workshop`, `ActivityType`, `PenaltyRule`, `Supplier` | Small, slow-growing reference sets |
| `MEDIUMINT UNSIGNED` | `SafetyStaff.ReviewStaffID`, `Vehicle.Odometer` | Mid-range volume |
| `INT UNSIGNED` | `VehicleAssignment`, `Part`, `PredictiveAlert`, `DriverCertification`, `MechanicCertification`, `EventReview`, `DriverMonthlySafetyScore`, `DriverScorePenalty`, `ScheduledService`, `MaintenanceActivity`, `WarrantyClaim`, `CoachingRecord`, `AppUser` | Higher-cardinality operational tables |
| `BIGINT UNSIGNED` | `MechanicWorkSession.SessionID` | Highest-volume — one `ActivityID` can accumulate many shift/break sessions |

**Alternative considered:** `INT UNSIGNED` uniformly. Rejected — column width
is self-documentation of expected scale; hiding that behind a uniform `INT`
makes every table look equally high-volume when they aren't.

### Value Representation & Type Choices

## 1.4 Monetary Value Representation


**Chosen:** `BIGINT UNSIGNED` for `Part.UnitPrice`, `MaintenanceJob.TotalCost`,
`PartSupplier.UnitCost`, `ActivityPart.UnitCost` — whole-number VND, not
`DECIMAL`.

**Why:** VND has no minor currency unit, so these amounts are always whole
numbers. `BIGINT` (not `INT`) because an aggregated `TotalCost` or
`UnitCost × QuantityUsed` sum can exceed a signed `INT`'s ~2.1 billion ceiling
at VND scale.

**Alternative considered:** `DECIMAL(12,2)`, the conventional default for
money. Rejected as unnecessary generality — nothing in the brief or seed data
introduces a second currency or fractional units.

*Note:* score fields (`DriverMonthlySafetyScore.Score`,
`PenaltyRule.PenaltyPoints`, `DriverScorePenalty.PointsDeducted`) correctly
stay `DECIMAL(5,2)` — those are genuinely fractional.

## 1.5 ENUM vs. Lookup Table


**Chosen:** a deliberate split.

- **Lookup tables** for values referenced by more than one table, carrying
  attached metadata, or named in the brief as something managers report on
  directly: `VehicleStatus`, `VehicleCategory`, `EventType`, `EventSeverity`,
  `AlertType`, `DriverCertificationType`, `MechanicCertificationType`,
  `ActivityType`.
- **Inline `ENUM`** for values scoped to one table, small and closed, and
  primarily used to drive that table's own state-machine `CHECK` logic:
  `VehicleAssignment.AssignmentStatus`, `Driver.EmploymentStatus` /
  `DrivingEligibility`, `Mechanic.EmploymentStatus`, `SafetyEvent.ReviewState`,
  `CoachingRecord.CoachingType` / `Outcome`, `DriverCertification.Status`,
  `MechanicCertification.Status`, `EventReview.Status`,
  `PredictiveAlert.AlertStatus`, `ScheduledService.Status`,
  `WarrantyClaim.ClaimSource` / `Status`.

**Why:** two reasons for the lookup-table group, not one. First, the values are
joined to and grouped/reported on by name in `6_business_queries.sql`. Second,
several of them are open to legitimately growing over time —
`ActivityType`, `AlertType`, and `EventType` in particular are plausible
candidates for new values being added post-launch (a new telematics event
type, a new maintenance activity), and a lookup table lets that happen with an
`INSERT` instead of an `ALTER TABLE ... MODIFY ENUM`.

The `ENUM` group, by contrast, is used where the value is scoped to a single
table and exists mainly to be evaluated *inside* that table's own `CHECK`
constraints and trigger `IF` branches — an `ENUM` keeps that a plain string
comparison, not a join, on logic that fires on every `INSERT`/`UPDATE`.
`CoachingRecord.CoachingType` is the clearest example: it's read and written
only within `CoachingRecord` itself, nothing else joins to it, so there's no
normalization benefit to pulling it into its own table.

**Alternative considered:** route every status through a lookup table for
textbook normalization. Rejected for the state-`ENUM` group — it would force
every `CHECK` and trigger `IF` to add a subquery just to read a status name.

## 1.6 `WarrantyClaim.ClaimSource` — Free Text to ENUM (and a Known Gap)


**Chosen:** `ClaimSource ENUM('Vehicle Manufacturer', 'Parts Supplier',
'Internal Claim') NOT NULL`, replacing an earlier free-text `VARCHAR(100)`.

**Why:** the original intent was for `ClaimSource` to point at something more
specific — in particular, a `Parts Supplier` claim ideally identifies *which*
supplier. That got simplified to a plain `ENUM` for scope reasons, which does
close off typos and inconsistent free-text values (the same ENUM-vs-lookup
reasoning as §1.5 applies — three fixed values, used only within this table).

**Known gap, accepted:** there is no `SupplierID` column on `WarrantyClaim`,
so a `Parts Supplier`-sourced claim can't be traced to the specific supplier
directly — only indirectly, by going through `ActivityPart` → `PartSupplier`
and inferring it. Documented here as an accepted limitation, not a bug. A
nullable `SupplierID` FK (populated only when `ClaimSource = 'Parts
Supplier'`) is the natural follow-up if supplier-level warranty accountability
becomes a real requirement later.

### Constraints & Integrity Enforcement

## 1.7 CHECK Constraints as Business-Rule Translation


Two kinds appear throughout `schema.sql`:

- **Format-level:** `CHK_Vehicle_VIN_Length`, `CHK_Vehicle_RegPlate`, and the
  ID-prefix checks from §1.1.
- **State-machine-level:** `CHK_VA_StatusConsistency`,
  `CHK_ER_StatusConsistency`, `CHK_DC_StatusConsistency` /
  `CHK_MC_StatusConsistency`, `CHK_PA_AlertStatusConsistency`,
  `CHK_SS_StatusConsistency`, `CHK_WC_StatusConsistency`,
  `CHK_CR_OutcomeConsistency`, `CHK_MJ_ClosedHasCost`.

**Why:** the conceptual model just says "an Assignment has a Status" — not
"`Completed` requires both `StartDate` and `EndDate`, with `EndDate ≥
StartDate`." Encoding that as a `CHECK` at the physical layer makes an invalid
row structurally impossible, rather than depending on every piece of app or
trigger code independently getting the state logic right.

**Alternative considered:** enforce these rules only in triggers/application
code. Rejected as the sole mechanism — `CHECK` constraints catch violations
regardless of entry point, matching the "fail loudly" principle used
throughout.

*Aside: the constraint-hardening pass that added most of these also caught a
latent bug — `EventReview.DateReviewed` was originally `NOT NULL`, which made
it impossible to correctly represent a freshly-created `'Unread'` review (no
review date exists yet). It's `NULL` in the current schema, consistent with
how every other status/date pairing in this section is handled.*

## 1.8 Generated Column for a Group-Level Uniqueness Rule (`PartSupplier`)


**Chosen:**
```sql
PrimaryPartNumber INT UNSIGNED GENERATED ALWAYS AS (IF(IsPrimary, PartNumber, NULL)) VIRTUAL,
CONSTRAINT UC_PS_OnePrimaryPerPart UNIQUE (PrimaryPartNumber)
```

**Why:** exploits MySQL's `UNIQUE` index allowing unlimited `NULL`s. The
generated column collapses to `NULL` for every non-primary row, so only the
(at most one) `IsPrimary = TRUE` row per part participates in the uniqueness
check — "exactly one primary supplier per part, unlimited backups," enforced
at the DB layer.

**Alternatives considered:**
- `UNIQUE(PartNumber, IsPrimary)` — the more obvious first attempt. Rejected:
  a plain composite unique index would cap *both* values of `IsPrimary` at one
  row per part, meaning at most one backup supplier per part too — not what
  we want, since a part can have any number of backup suppliers.
- A `CHECK` constraint counting `IsPrimary = TRUE` rows per part. Rejected —
  structurally impossible, since MySQL `CHECK` constraints evaluate one row
  at a time, not an aggregate across a group.

The generated-column pattern is the standard MySQL workaround for "at most one
row per group matches condition X, but unlimited rows may not."

## 1.9 Optional (Nullable) Foreign Keys


Several FKs are nullable because the relationship is genuinely optional in the
business: `MaintenanceJob.ScheduleID`, `MaintenanceActivity.LinkedAlertID`,
`ScheduledService.AlertID`, `ActivityPart.ClaimID`, `Driver.CurrentDepotID`.

**Why:** the brief states this explicitly — *"An alert does not always result
in a maintenance job... A maintenance job may also be created independently of
any alert."* Making any of these `NOT NULL` would misrepresent that rule.

## 1.10 Referential Integrity Posture: No Cascading Deletes


**Chosen:** no `ON DELETE CASCADE` anywhere — every FK defaults to
`RESTRICT`.

**Why:** matches the project-wide principle that a record, once written, is a
historical fact. `CASCADE` anywhere would let, e.g., deleting a `Driver`
silently wipe their entire event/assignment/coaching history —
contradicting the brief's *"Historical Records must remain available even when
drivers transfer depots..."* (p.13).

**Alternative considered:** `CASCADE` on obviously-owned children (e.g.
`MaintenanceJob` → `MaintenanceActivity`) for convenience. Rejected — the
schema has no soft-delete mechanism, so any `DELETE` on a fact table is
already an unusual, manual operation; `RESTRICT` forces that to be deliberate.

### Structural / Entity Modeling

## 1.11 Weak Entity / 1:1 Specialization — `Workshop`


**Chosen:** `Workshop` is a separate table, linked to `Depot` by
`Workshop.DepotID SMALLINT UNSIGNED NOT NULL UNIQUE` (physical 1:1), per the
brief's *"the company operates one workshop per depot."*

**Why not merge into Depot:** `Depot` is referenced by many tables unrelated
to workshop operations (`Vehicle`, `Driver`, `VehicleAssignment`,
`SafetyEvent`, `DriverMonthlySafetyScore`). Merging would force all of those
to carry mostly-`NULL` workshop-only columns, and would conflate "a physical
company site" with "a maintenance facility" — concepts the brief treats as
related but distinct.

## 1.12 `Workshop.Address`


**Chosen:** `Workshop.Address VARCHAR(255) NOT NULL`, added alongside
`Depot.Address` (which already existed).

**Why:** consistency — every other physical-location entity in the schema
(`Depot`, `Supplier`) carries its own `Address` column, so `Workshop` follows
the same pattern rather than being a special case that requires joining to
`Depot` just to answer "where is this workshop." Not driven by a specific
business rule — a workshop's address is expected to match its depot's in
practice, given the 1:1 relationship in §1.11 — purely a modeling-consistency
call.

## 1.13 Alert-to-Job Linkage: FK on `MaintenanceActivity`, Not `MaintenanceJob`


**Chosen:** `MaintenanceActivity.LinkedAlertID INT UNSIGNED NULL`, FK to
`PredictiveAlert` — placed at the *activity* level, not the job level.

**Why:** the brief states two things that only work together if the FK sits
here: *"An alert does not always result in a maintenance job... when a job is
created in response to an alert, the alert must be linked to that job so the
outcome can be tracked. A maintenance job may also be created independently
of any alert."* A single `MaintenanceJob` can bundle multiple
`MaintenanceActivity` rows (per the brief: *"A job may consist of one or more
maintenance activities"*), and different activities within the same job can
be addressing different alerts — or none at all, if the job also includes
routine work alongside alert-driven repair. A `MaintenanceJob`-level FK could
only ever capture *one* alert per job, which breaks as soon as a single
workshop visit addresses two separate predictive alerts at once (e.g. a
brake-wear alert and a battery-degradation alert on the same visit, each
resolved by a different activity). Placing the FK on `MaintenanceActivity`
instead lets each activity independently link to the specific alert it
resolves, while the job as a whole stays a container. `NULL` is what
satisfies the second half of the rule — an activity performed as routine or
scheduled work has no alert to link to at all.

**Alternative considered:** the FK on `MaintenanceJob`, with a job-level
`Reason` distinguishing alert-driven from routine work. Rejected — it can't
represent "this job addresses two different alerts across two of its
activities" without either picking one alert arbitrarily or adding a second
junction table, when placing the FK one level down solves it directly.

## 1.14 `MaintenanceJob.ScheduleID` — Closing the Loop with `ScheduledService`


**Chosen:** `MaintenanceJob.ScheduleID INT UNSIGNED NULL`, FK to
`ScheduledService`, added after the fact — this column didn't exist in an
earlier version of this schema at all.

**Why:** without it, a `MaintenanceJob` had no way to declare "I'm the job
that's fulfilling this specific scheduled service." That link is what lets
`TRG_MaintenanceJob_AfterInsert`/`AfterUpdate` automatically flip the matching
`ScheduledService` row to `Completed` (with a `CompletionDate`) the moment the
job closes — without it, a satisfied service would sit at `Scheduled` forever,
permanently "overdue" as far as `fn_NextVehicleStatus` is concerned, even
after the work was actually done. This is a rare case in the schema of the
*trigger* design driving a schema change, rather than the schema constraining
what the triggers could do.

### Historical Accuracy & Derived State

## 1.15 Voided vs. Revoked Certification Status


The brief requires that *"past job assignments can be verified against
qualifications held at the time."* `DriverCertification` and
`MechanicCertification` therefore carry two distinct terminal-ish statuses:

- **`Revoked`** — the certification is no longer valid *going forward* (e.g.
  expired early, administrative cancellation). Past assignments made while it
  was active remain legal.
- **`Voided`** — the certification is *retroactively* invalid (e.g. fraud,
  falsified documents, severe incompetence discovered after the fact). A
  `Voided` status renders all past *and* future operations that relied on it
  illegal.

**Why this matters:** triggers already block new assignments against an
invalid cert going forward. But if a cert is *later* marked `Voided`, the
system needs a way to audit assignments that already happened and are now
retroactively illegal. `Voided` is what makes the audit queries `Q13a`/`Q13b`
in `6_business_queries.sql` possible, without corrupting the meaning of the
ordinary `Revoked` timeline.

**Full renewal history, retained by design:** the brief also requires that
*"the full renewal history [be] retained so past job assignments can be
verified against qualifications held at the time"* (p.11). This is why
`UC_DriverCertification` / `UC_MechanicCertification` are unique on
`(DriverID/MechanicID, CertificationTypeID, IssueDate, ExpiryDate)` —
including the *dates* in the unique key, not just the person and cert type —
rather than one row per person-per-cert-type. A renewal creates a new row
with a new `IssueDate`/`ExpiryDate` pair instead of overwriting the old
one's dates, so every past certification period for a given driver or
mechanic coexists in the table permanently. Nothing here is ever deleted or
updated in place to reflect a renewal — that's what makes "verify against
qualifications held at the time" (as used by `6_business_queries.sql`
Q13a/Q13b) possible at all.

## 1.16 Derived State / "Cache, Not a Record" Pattern


`Driver.DrivingEligibility` and `SafetyEvent.ReviewState` are treated as
**caches, not independent records of truth**.

- **The problem:** computing these live via `JOIN`s on every `SELECT` would
  hurt read performance; letting the application write them directly risks
  silent drift if app logic has a bug.
- **The solution:** both are updated only through centralized logic —
  `Driver.DrivingEligibility` exclusively by the stored procedure
  `sp_RecomputeDriverEligibility`; `SafetyEvent.ReviewState` by
  `TRG_EventReview_AfterInsert`/`AfterUpdate`, which call the function
  `fn_EventReviewState` to compute the new value and write it back.
- **Enforcement:** `BEFORE UPDATE` triggers on `Driver` and `SafetyEvent`
  block any direct write to these columns unless a specific session flag
  (`@sfms_allow_eligibility_write`, `@sfms_allow_reviewstate_write`) is set by
  the authorized caller.
- **Benefit:** read performance of a physical column, with the write-safety
  of a derived view — full mechanism detail lives in the trigger docs.

## 1.17 `VehicleAssignment.DepotID` — Denormalized for Historical Accuracy


**Chosen:** `VehicleAssignment.DepotID SMALLINT UNSIGNED NOT NULL`, stored
directly on the assignment row, rather than being derived at query time from
`Driver.CurrentDepotID` or `Vehicle.DepotID`.

**Why:** the brief's Historical Records requirement is explicit — *"Historical
records must remain available even when: Drivers transfer depots..."* Both
`Driver.CurrentDepotID` and `Vehicle.DepotID` are live, current-state columns
that can change after an assignment is written. If `VehicleAssignment` didn't
store its own `DepotID` and instead relied on joining to `Driver` or
`Vehicle` for "which depot was this assignment through," that answer would
silently change retroactively every time the driver transferred depots —
exactly what the brief says must not happen. Storing `DepotID` directly
freezes it as a fact about the assignment itself, at the moment the
assignment was made.

**This is a deliberate 2NF-style choice over strict 3NF.** In a
pure-3NF read of the schema, `DepotID` might look transitively derivable from
`DriverID` (via `Driver.CurrentDepotID`) — a non-key attribute depending on
another non-key attribute rather than directly on the row's own key. But that
derivation is only valid *at a single point in time*; for a transactional/event
table recording something that happened, the derived value and the frozen
value diverge the moment the underlying "current" data moves on. Trading
strict normalization for point-in-time accuracy is the standard, deliberate
pattern for this kind of table — the same reasoning applies to
`SafetyEvent.DepotID` and `DriverMonthlySafetyScore.DepotID` elsewhere in the
schema, though this entry focuses on `VehicleAssignment` specifically per
scope.

**Alternative considered:** omit `DepotID` from `VehicleAssignment` and
derive it via `JOIN` to `Driver`/`Vehicle` when needed. Rejected — it
directly violates the brief's historical-availability requirement, and would
also become ambiguous *which* table's depot should even be authoritative once
they disagree (a driver assigned from Depot A to a vehicle currently parked
at Depot B).

**Scope note:** `DepotID` is the *denormalization* half of what keeps a
`VehicleAssignment` historically accurate. The other half — preventing
`DriverID`, `IssueDate`, and `StartDate` from being edited once the
assignment leaves `Pending`, and `EndDate` from being set more than once — is
enforced by `TRG_VehicleAssignment_BeforeUpdate`, not by schema design, and
is documented in the trigger-layer docs rather than here.

---

## 1.18 Precision Over Ambiguity: Splitting Single Fields to Avoid Conflated Concepts


A recurring theme across several otherwise-unrelated tables: a single field
quietly conflating two distinct real-world facts was split into two explicit
ones. The underlying reasoning is the same every time — **managers need
specific, unambiguous information, and a single vague field can't give it to
them.**

- **`VehicleAssignment.IsActive` (boolean) → `AssignmentStatus` ENUM +
  `StartDate`.** A boolean can only say "currently out or not" — it can't
  distinguish a booking that's been made but not yet picked up (`Pending`)
  from one actually out on the road (`In Operation`), and it can't distinguish
  a normal completion from a cancellation. The four-state `AssignmentStatus`
  plus a separate `StartDate` (booking time vs. actual pickup time) makes each
  of those a first-class, queryable fact instead of something inferred from
  whether `EndDate` happens to be set.
- **`Driver.EmploymentStatus` / `DrivingEligibility`.** Folding "are they
  still employed" and "are they currently allowed to drive" into one
  `EmploymentStatus` value (which used to include a `Suspended` state) was
  ambiguous about *which kind* of suspension was meant. Splitting them means a
  driver can be `Active` (employed) but `Suspended` (not currently allowed to
  drive) at the same time — a real, common state the single-field version
  couldn't represent at all. See §1.16 for how `DrivingEligibility` is kept in
  sync as a derived cache.
- **Terminal status + explicit resolution timestamp**, applied consistently
  once the pattern was recognized: `CoachingRecord.CompletionDate` (alongside
  the renamed `CoachingDate`), `PredictiveAlert.ResolutionDate`,
  `WarrantyClaim.ResolutionDate`, `ScheduledService.CompletionDate` — each
  paired with a `CHECK` tying the date's presence to the status. Without
  these, "when was this actually resolved" was either unanswerable or had to
  be approximated from an unrelated column.
- **`MechanicWorkSession.StartTime`/`EndTime`**, rather than a single stored
  total-hours field — a mechanic can log multiple sessions against one
  activity across shifts and breaks, so total labour hours has to be a `SUM`
  over sessions (see business query Q31), not a single field that would
  silently overwrite itself on a second shift.

**Alternative considered, in each case:** keep the single, more ambiguous
field and let the application layer infer the missing distinction from
context. Rejected throughout — an inferred distinction is exactly the kind of
thing that drifts out of sync or gets interpreted inconsistently across
different parts of an application, whereas a first-class column can be
validated by a `CHECK` and queried directly.

### Scope Decisions & Application Layer

## 1.19 Supplier Performance & the `PartReceipt` Rollback


The brief asks the system to *"monitor supplier performance."* During design,
a `PartReceipt` table (plus `ActivityPart.ReceiptID`) was built and fully
tested to trace which physical shipment a part came from, for quality/defect
auditing.

**The rollback:** deliberately reverted. The design assumed the mechanic
logging part usage knew which physical shipment a part came from — but once
two shipments sit on the same shelf, they're indistinguishable in practice.
Fixing that properly would require a FIFO auto-allocation procedure and
relaxing the `(ActivityID, PartNumber)` primary key on `ActivityPart`.

**The decision:** "supplier performance" is scoped strictly to price
competitiveness and delivery lead time, both already covered by
`PartSupplier` (see `6_business_queries.sql` Q29). Quality/defect-rate
auditing and lot-traceability are explicitly out of scope for this iteration.
If required later, the rolled-back FIFO design is the documented starting
point (see `CHANGELOG_part_receipt.md`).

## 1.20 Application Layer: `Role`/`AppUser` and DBMS-Level Security


Two distinct, easy-to-conflate mechanisms live in schema.sql Section 7.

**`Role`/`AppUser`** is the application-level login model — **Option A** from
the team's design discussion: nullable FKs (`DriverID`, `MechanicID`,
`ReviewStaffID`) on `AppUser` rather than a full `Person` supertype redesign,
chosen to avoid touching `Driver`/`Mechanic`/`SafetyStaff` and their
already-tested trigger logic this late in the project.
`CHK_AppUser_FK_Consistency` enforces "exactly one role-linking FK populated,
or all three `NULL`" (the latter for Fleet Manager / Workshop Manager /
Admin).

**The `CREATE USER`/`GRANT` block** (six MySQL accounts, detailed in Part 4)
is a separate, lower layer — it governs what a raw DB connection can do,
independent of `AppUser`/`Role`. Neither table knows about the other by FK;
the mapping between a `Role` row and a DB account is currently implicit
(naming convention only).

**Open question, worth deciding before the dashboard build starts:** will the
web app connect using one of the six shared per-role DB accounts (with
`AppUser`/`Role` handling authentication only), or as a single service account
enforcing everything through `AppUser`/`Role` in app logic (making the six DB
accounts vestigial)? Neither approach gives row-level filtering (e.g. "this
`DriverID` sees only their own rows") for free either way — MySQL's `GRANT`
system can't express that, so it's an application-layer concern regardless.

# Part 2: Business Rule → Schema Traceability

Every rule below is stated explicitly in the project brief. This table maps
each one to the specific schema mechanism that enforces it, scoped to
**schema-only** enforcement (`CHECK`/`UNIQUE` constraints and table/column
design decisions). Rules primarily enforced by trigger logic — driver/vehicle
assignment eligibility, certification-expiry gating, safety-score
calculation, review-state cascades, mechanic-certification gating on work
sessions, and similar — are out of scope here and belong in the trigger-layer
documentation instead.

| # | Rule (brief) | Table(s) / Column(s) | Mechanism | Detail |
|---|---|---|---|---|
| R10 | "An alert does not always result in a maintenance job... when a job is created in response to an alert, the alert must be linked to that job." | `MaintenanceActivity.LinkedAlertID` | Table design — FK placement | FK sits on `MaintenanceActivity`, not `MaintenanceJob`, since a job can bundle multiple activities addressing different alerts. See §1.13. |
| R11 | "A maintenance job may also be created independently of any alert." | `MaintenanceActivity.LinkedAlertID` | Table design — nullable FK | Same column as R10; `NULL` is what allows routine/scheduled activities with no alert behind them. See §1.13. |
| R12 | "The company operates one workshop per depot." | `Workshop.DepotID` | Constraint — `UNIQUE` | `Workshop.DepotID SMALLINT UNSIGNED NOT NULL UNIQUE` makes a second workshop on the same depot structurally impossible. See §1.11. |
| R14 | "Each part has a designated primary supplier and an optional backup supplier." | `PartSupplier.PrimaryPartNumber` (generated column) | Constraint — generated column + `UNIQUE` | `UC_PS_OnePrimaryPerPart` enforces at most one `IsPrimary = TRUE` row per part, unlimited backups. See §1.8. |
| R15 | "The database must record whether the warranty is with the vehicle manufacturer or the parts supplier." | `WarrantyClaim.ClaimSource` | Table design — `ENUM` | `ENUM('Vehicle Manufacturer','Parts Supplier','Internal Claim')`. Known gap: no `SupplierID` to identify *which* supplier — see §1.6. |
| R16 | "The full renewal history retained so past job assignments can be verified against qualifications held at the time." | `DriverCertification`, `MechanicCertification` | Table design — `UNIQUE` spans dates + non-destructive rows | Uniqueness includes `IssueDate`/`ExpiryDate`, not just person + cert type, so renewals add rows rather than overwrite them. `Voided` vs `Revoked` status distinguishes ordinary expiry from retroactive invalidation. See §1.15. |
| R17 | "Historical records must remain available even when: Drivers transfer depots..." | `VehicleAssignment.DepotID`, `DriverID`, `IssueDate`, `StartDate`, `EndDate` | `DepotID`: table design — denormalized (2NF, not 3NF). The rest: trigger-enforced immutability. | `DepotID` is frozen on the assignment row at write time rather than derived via `Driver.CurrentDepotID` — the schema-design half of the guarantee, see §1.17. `DriverID`, `IssueDate`, and `StartDate` are additionally locked against edits once an assignment leaves `Pending`, and `EndDate` is only ever set once (at Completion/Cancellation) — this half is trigger-enforced (`TRG_VehicleAssignment_BeforeUpdate`), out of scope for schema-only detail here but included since it's the same underlying rule. The `DepotID`-denormalization pattern also applies to `SafetyEvent.DepotID` and `DriverMonthlySafetyScore.DepotID`, not detailed here per current scope. |

**Rules intentionally excluded from this table** (trigger-enforced, documented
separately): R1 (vehicle-under-maintenance assignment block), R2/R3 (driver
certification/expiry gating), R4/R5 (critical-event review + eligibility
suspension), R6/R8/R9 (score-driven coaching/retraining/suspension), R7
(monthly score calculation), R13 (mechanic certification gating on work
sessions).
# Part 3: Full Data Dictionary

Unless noted, all surrogate ID columns are `AUTO_INCREMENT`, and all IDs and
quantities are `UNSIGNED` to prevent negative values.

## 2.1 Lookup & Reference Tables

No foreign keys — controlled vocabularies.

### Location
| Column | Type | Constraints |
|---|---|---|
| LocationID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| LocationName | VARCHAR(100) | NOT NULL, UNIQUE |

### VehicleCategory
| Column | Type | Constraints |
|---|---|---|
| VehicleCategoryID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| VehicleCategory | VARCHAR(100) | NOT NULL, UNIQUE |

### VehicleStatus
| Column | Type | Constraints |
|---|---|---|
| VehicleStatusID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| VehicleStatus | VARCHAR(100) | NOT NULL, UNIQUE |

### DriverCertificationType
| Column | Type | Constraints |
|---|---|---|
| DriverCertificationTypeID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| DriverCertificationType | VARCHAR(100) | NOT NULL, UNIQUE |
| Description | TEXT | NULL |

### EventType
| Column | Type | Constraints |
|---|---|---|
| EventTypeID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| EventType | VARCHAR(100) | NOT NULL, UNIQUE |

### EventSeverity
| Column | Type | Constraints |
|---|---|---|
| SeverityID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| SeverityLevel | VARCHAR(100) | NOT NULL, UNIQUE |

### AlertType
| Column | Type | Constraints |
|---|---|---|
| AlertTypeID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| AlertType | VARCHAR(100) | NOT NULL, UNIQUE |

### MechanicCertificationType
| Column | Type | Constraints |
|---|---|---|
| MechanicCertificationTypeID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| MechanicCertificationType | VARCHAR(255) | NOT NULL, UNIQUE |

### SafetyStaff
| Column | Type | Constraints |
|---|---|---|
| ReviewStaffID | MEDIUMINT UNSIGNED | PK, AUTO_INCREMENT |
| FullName | VARCHAR(255) | NOT NULL |
| ContactInfo | VARCHAR(255) | NOT NULL |

### Supplier
| Column | Type | Constraints |
|---|---|---|
| SupplierID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| SupplierName | VARCHAR(100) | NOT NULL, UNIQUE |
| ContactInfo | VARCHAR(255) | NOT NULL |
| Address | VARCHAR(255) | NOT NULL |
| DeliveryLeadTime | SMALLINT UNSIGNED | NOT NULL, CHK > 0 |

### Part
| Column | Type | Constraints |
|---|---|---|
| PartNumber | INT UNSIGNED | PK, AUTO_INCREMENT |
| PartName | VARCHAR(100) | NOT NULL |
| Description | TEXT | NULL |
| CurrentStock | SMALLINT UNSIGNED | NOT NULL (decremented/restored by `ActivityPart` triggers) |
| ReorderThreshold | SMALLINT UNSIGNED | NOT NULL, CHK > 0 |
| UnitPrice | BIGINT UNSIGNED | NOT NULL, CHK > 0 (whole VND — see §1.4) |

## 2.2 Core Entities & Level 1 Dependencies

### Depot
| Column | Type | Constraints |
|---|---|---|
| DepotID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| DepotName | VARCHAR(100) | NOT NULL, UNIQUE |
| Address | VARCHAR(255) | NOT NULL |
| LocationID | SMALLINT UNSIGNED | NOT NULL, FK → Location |

### ActivityType
| Column | Type | Constraints |
|---|---|---|
| ActivityTypeID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| ActivityType | VARCHAR(255) | NOT NULL, UNIQUE |
| RequiredMechanicCertification | SMALLINT UNSIGNED | NOT NULL, FK → MechanicCertificationType |

### VehicleCertificationRequirement
| Column | Type | Constraints |
|---|---|---|
| VehicleCategoryID | SMALLINT UNSIGNED | PK (composite), FK → VehicleCategory |
| DriverCertificationTypeID | SMALLINT UNSIGNED | PK (composite), FK → DriverCertificationType |

### Workshop
| Column | Type | Constraints |
|---|---|---|
| WorkshopID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| DepotID | SMALLINT UNSIGNED | NOT NULL, UNIQUE, FK → Depot (1 workshop per depot — see §1.11) |
| Name | VARCHAR(100) | NOT NULL |
| Address | VARCHAR(255) | NOT NULL |

### Vehicle
| Column | Type | Constraints |
|---|---|---|
| VIN | VARCHAR(17) | PK, CHK regex (17 chars, excludes I/O/Q) |
| RegistrationNumber | VARCHAR(20) | NOT NULL, UNIQUE, CHK regex (VN plate format) |
| CategoryID | SMALLINT UNSIGNED | NOT NULL, FK → VehicleCategory |
| Model | VARCHAR(100) | NOT NULL |
| Manufacturer | VARCHAR(100) | NOT NULL |
| YearOfManufacture | YEAR | NOT NULL, CHK ≥ 1980 |
| Odometer | MEDIUMINT UNSIGNED | NOT NULL |
| DepotID | SMALLINT UNSIGNED | NOT NULL, FK → Depot |
| OperationalStatus | SMALLINT UNSIGNED | NOT NULL, FK → VehicleStatus |

### Driver
| Column | Type | Constraints |
|---|---|---|
| DriverID | VARCHAR(20) | PK, CHK prefix `D-` |
| FullName | VARCHAR(255) | NOT NULL |
| ContactInfo | VARCHAR(255) | NOT NULL |
| CurrentDepotID | SMALLINT UNSIGNED | NULL (optional — see §1.9), FK → Depot |
| EmploymentStatus | ENUM('Active','On Leave','Terminated') | NOT NULL |
| EmergencyContactDetails | VARCHAR(255) | NOT NULL |
| DrivingEligibility | ENUM('Eligible','Suspended') | NOT NULL, DEFAULT 'Eligible' — **derived cache, see §1.16** |

### Mechanic
| Column | Type | Constraints |
|---|---|---|
| MechanicID | VARCHAR(20) | PK, CHK prefix `ME-` |
| FullName | VARCHAR(255) | NOT NULL |
| ContactInfo | VARCHAR(255) | NOT NULL |
| WorkshopID | SMALLINT UNSIGNED | NOT NULL, FK → Workshop |
| EmploymentStatus | ENUM('Active','Inactive','Suspended','Terminated') | NOT NULL |

## 2.3 Assignments, Events & Maintenance

### VehicleAssignment
| Column | Type | Constraints |
|---|---|---|
| AssignmentID | INT UNSIGNED | PK, AUTO_INCREMENT |
| VIN | VARCHAR(17) | NOT NULL, FK → Vehicle |
| DriverID | VARCHAR(20) | NOT NULL, FK → Driver |
| DepotID | SMALLINT UNSIGNED | NOT NULL, FK → Depot |
| IssueDate | DATETIME | NOT NULL |
| StartDate | DATETIME | NULL |
| EndDate | DATETIME | NULL |
| AssignmentStatus | ENUM('Pending','In Operation','Completed','Cancelled') | NOT NULL, DEFAULT 'Pending'; `CHK_VA_StatusConsistency` ties Start/EndDate presence to status |

### SafetyEvent
| Column | Type | Constraints |
|---|---|---|
| EventID | VARCHAR(100) | PK, CHK prefix `E` |
| DriverID | VARCHAR(20) | NOT NULL, FK → Driver |
| VIN | VARCHAR(17) | NOT NULL, FK → Vehicle |
| DepotID | SMALLINT UNSIGNED | NOT NULL, FK → Depot |
| EventTimestamp | DATETIME | NOT NULL |
| EventTypeID | SMALLINT UNSIGNED | NOT NULL, FK → EventType |
| SeverityID | SMALLINT UNSIGNED | NOT NULL, FK → EventSeverity |
| Odometer | MEDIUMINT UNSIGNED | NOT NULL |
| ReviewState | ENUM('Pending','Assigned','In Review','Completed','No Review Required') | NOT NULL, DEFAULT 'No Review Required' — **derived cache, see §1.16** |

### CoachingRecord
| Column | Type | Constraints |
|---|---|---|
| CoachingRecordID | INT UNSIGNED | PK, AUTO_INCREMENT |
| DriverID | VARCHAR(20) | NOT NULL, FK → Driver |
| CoachingType | ENUM('Safety Coaching','Retraining','Licence Review') | NOT NULL |
| CoachingDate | DATE | NOT NULL |
| CompletionDate | DATE | NULL |
| Outcome | ENUM('Passed','Failed','In Progress','Pending') | NOT NULL, DEFAULT 'Pending'; `CHK_CR_OutcomeConsistency` ties CompletionDate to Outcome |

### PredictiveAlert
| Column | Type | Constraints |
|---|---|---|
| AlertID | INT UNSIGNED | PK, AUTO_INCREMENT |
| VIN | VARCHAR(17) | NOT NULL, FK → Vehicle |
| AlertTypeID | SMALLINT UNSIGNED | NOT NULL, FK → AlertType |
| DateGenerated | DATETIME | NOT NULL |
| ActionTaken | TEXT | NULL |
| AlertStatus | ENUM('Unresolved','Acknowledged','Scheduled For Inspection','Urgent Repair Standby','Resolved') | NOT NULL, DEFAULT 'Unresolved' |
| ResolutionDate | DATETIME | NULL; `CHK_PA_AlertStatusConsistency` ties ResolutionDate to status |

### MaintenanceJob
| Column | Type | Constraints |
|---|---|---|
| JobID | VARCHAR(255) | PK, CHK prefix `M` |
| VIN | VARCHAR(17) | NOT NULL, FK → Vehicle |
| WorkshopID | SMALLINT UNSIGNED | NOT NULL, FK → Workshop |
| ScheduleID | INT UNSIGNED | NULL (optional — see §1.9; added specifically to support trigger-driven auto-completion, see §1.14), FK → ScheduledService |
| DateOpened | DATETIME | NOT NULL |
| DateClosed | DATETIME | NULL, CHK ≥ DateOpened |
| Downtime | DECIMAL(12,4) | NOT NULL, CHK ≥ 0 (hours) |
| TotalCost | BIGINT UNSIGNED | NULL; CHK: if DateClosed set, TotalCost must be NOT NULL |

### MaintenanceActivity
| Column | Type | Constraints |
|---|---|---|
| ActivityID | INT UNSIGNED | PK, AUTO_INCREMENT |
| JobID | VARCHAR(255) | NOT NULL, FK → MaintenanceJob |
| ActivityTypeID | SMALLINT UNSIGNED | NOT NULL, FK → ActivityType |
| DiagnosticResult | TEXT | NULL |
| RepeatedFaultFlag | BOOLEAN | NOT NULL |
| WarrantyFlag | BOOLEAN | NOT NULL |
| LinkedAlertID | INT UNSIGNED | NULL (optional — see §1.9), FK → PredictiveAlert |

## 2.4 Certifications & Reviews

### DriverCertification
| Column | Type | Constraints |
|---|---|---|
| DriverCertificationID | INT UNSIGNED | PK, AUTO_INCREMENT |
| DriverID | VARCHAR(20) | NOT NULL, FK → Driver |
| DriverCertificationTypeID | SMALLINT UNSIGNED | NOT NULL, FK → DriverCertificationType |
| IssueDate | DATE | NOT NULL |
| ExpiryDate | DATE | NOT NULL, CHK > IssueDate |
| RevocationDate | DATE | NULL, CHK between IssueDate and ExpiryDate when set |
| Status | ENUM('Active','Revoked','Expired','Voided','Reinstated') | NOT NULL, DEFAULT 'Active' — see §1.15 for Voided vs Revoked |
| StatusNotes | TEXT | NULL |
| — | — | UNIQUE(DriverID, DriverCertificationTypeID, IssueDate, ExpiryDate) |

### MechanicCertification
| Column | Type | Constraints |
|---|---|---|
| MechanicCertificationID | INT UNSIGNED | PK, AUTO_INCREMENT |
| MechanicID | VARCHAR(20) | NOT NULL, FK → Mechanic |
| MechanicCertificationTypeID | SMALLINT UNSIGNED | NOT NULL, FK → MechanicCertificationType |
| IssueDate | DATE | NOT NULL |
| ExpiryDate | DATE | NOT NULL, CHK > IssueDate |
| RevocationDate | DATE | NULL, CHK between IssueDate and ExpiryDate when set |
| Status | ENUM('Active','Revoked','Expired','Voided','Reinstated') | NOT NULL, DEFAULT 'Active' — same semantics as §1.15 |
| StatusNotes | TEXT | NULL |
| — | — | UNIQUE(MechanicID, MechanicCertificationTypeID, IssueDate, ExpiryDate) |

### EventReview
| Column | Type | Constraints |
|---|---|---|
| ReviewID | INT UNSIGNED | PK, AUTO_INCREMENT |
| EventID | VARCHAR(100) | NOT NULL, FK → SafetyEvent |
| ReviewerStaffID | MEDIUMINT UNSIGNED | NOT NULL, FK → SafetyStaff |
| Comments | TEXT | NULL |
| Recommendations | TEXT | NULL |
| Status | ENUM('Unread','Read','Commented','Closed') | NOT NULL, DEFAULT 'Unread'; CHK: Commented requires Comments, Closed requires DateReviewed (trigger additionally blocks closing without reading first) |
| DateReviewed | DATETIME | NULL |

## 2.5 Penalties, Scores & Schedules

### PenaltyRule
| Column | Type | Constraints |
|---|---|---|
| PenaltyRuleID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| RuleType | ENUM('Base','Conditional') | NOT NULL |
| RuleDescription | TEXT | NULL |
| EventTypeID | SMALLINT UNSIGNED | NULL, FK → EventType |
| SeverityID | SMALLINT UNSIGNED | NULL, FK → EventSeverity |
| MinEventCount | TINYINT UNSIGNED | NOT NULL, CHK > 0 |
| TimeWindowMonths | TINYINT UNSIGNED | NOT NULL, CHK > 0 |
| PenaltyPoints | DECIMAL(5,2) | NOT NULL, CHK ≥ 0 |
| — | — | CHK: at least one of EventTypeID/SeverityID must be set |

### DriverMonthlySafetyScore
| Column | Type | Constraints |
|---|---|---|
| DriverMonthlySafetyScoreID | INT UNSIGNED | PK, AUTO_INCREMENT |
| DriverID | VARCHAR(20) | NOT NULL, FK → Driver |
| Month | TINYINT UNSIGNED | NOT NULL, CHK 1–12 |
| Year | YEAR | NOT NULL |
| DepotID | SMALLINT UNSIGNED | NOT NULL, FK → Depot |
| Score | DECIMAL(5,2) | NOT NULL, CHK ≤ 100 (can go negative) |
| — | — | UNIQUE(DriverID, Month, Year) |

### DriverScorePenalty
| Column | Type | Constraints |
|---|---|---|
| ScorePenaltyID | INT UNSIGNED | PK, AUTO_INCREMENT |
| DriverMonthlySafetyScoreID | INT UNSIGNED | NOT NULL, FK → DriverMonthlySafetyScore |
| PenaltyRuleID | SMALLINT UNSIGNED | NOT NULL, FK → PenaltyRule |
| EventID | VARCHAR(100) | NOT NULL, FK → SafetyEvent |
| PointsDeducted | DECIMAL(5,2) | NOT NULL, CHK > 0 |
| DateApplied | DATETIME | NOT NULL |

### ScheduledService
| Column | Type | Constraints |
|---|---|---|
| ScheduleID | INT UNSIGNED | PK, AUTO_INCREMENT |
| VIN | VARCHAR(17) | NOT NULL, FK → Vehicle |
| ScheduledDate | DATE | NOT NULL |
| Reason | TEXT | NULL |
| AlertID | INT UNSIGNED | NULL (optional — see §1.9), FK → PredictiveAlert |
| CompletionDate | DATE | NULL |
| Status | ENUM('Scheduled','In Progress','Completed','Cancelled') | NOT NULL, DEFAULT 'Scheduled'; CHK ties CompletionDate to Status |

*Note: `MaintenanceJob.ScheduleID` FK is added via a post-creation `ALTER
TABLE`, since `MaintenanceJob` and `ScheduledService` reference each other and
one must exist first.*

## 2.6 Workshop Operations & Parts Tracking

### MechanicWorkSession
| Column | Type | Constraints |
|---|---|---|
| SessionID | BIGINT UNSIGNED | PK, AUTO_INCREMENT |
| MechanicID | VARCHAR(20) | NOT NULL, FK → Mechanic |
| ActivityID | INT UNSIGNED | NOT NULL, FK → MaintenanceActivity |
| StartTime | DATETIME | NOT NULL |
| EndTime | DATETIME | NULL, CHK ≥ StartTime when set |

*Multiple sessions per activity are expected — shifts/breaks; total labour
hours is a `SUM`, not a stored column (see business query Q31).*

### WarrantyClaim
| Column | Type | Constraints |
|---|---|---|
| ClaimID | INT UNSIGNED | PK, AUTO_INCREMENT |
| ActivityID | INT UNSIGNED | NOT NULL, FK → MaintenanceActivity |
| ClaimSource | ENUM('Vehicle Manufacturer','Parts Supplier','Internal Claim') | NOT NULL — see §1.6 for the known gap (no supplier-level traceability) |
| ClaimDate | DATE | NOT NULL |
| Status | ENUM('Pending','Approved','Rejected','Settled') | NOT NULL, DEFAULT 'Pending' |
| ResolutionDate | DATE | NULL; CHK ties ResolutionDate to Status |

### PartSupplier
| Column | Type | Constraints |
|---|---|---|
| PartNumber | INT UNSIGNED | PK (composite), FK → Part |
| SupplierID | SMALLINT UNSIGNED | PK (composite), FK → Supplier |
| IsPrimary | BOOLEAN | NOT NULL |
| UnitCost | BIGINT UNSIGNED | NOT NULL, CHK > 0 |
| PrimaryPartNumber | INT UNSIGNED | GENERATED ALWAYS AS (IF(IsPrimary, PartNumber, NULL)) VIRTUAL; UNIQUE — enforces exactly one primary supplier per part (see §1.8) |

### ActivityPart
| Column | Type | Constraints |
|---|---|---|
| ActivityID | INT UNSIGNED | PK (composite), FK → MaintenanceActivity |
| PartNumber | INT UNSIGNED | PK (composite), FK → Part |
| ClaimID | INT UNSIGNED | NULL (optional — see §1.9), FK → WarrantyClaim |
| QuantityUsed | SMALLINT UNSIGNED | NOT NULL, CHK > 0 |
| UnitCost | BIGINT UNSIGNED | NOT NULL, CHK > 0 |

## 2.7 Application Authentication (Dashboard)

### Role
| Column | Type | Constraints |
|---|---|---|
| RoleID | SMALLINT UNSIGNED | PK, AUTO_INCREMENT |
| RoleName | VARCHAR(50) | NOT NULL, UNIQUE |

Seeded values: `Driver`, `Mechanic`, `Safety Staff`, `Fleet Manager`,
`Workshop Manager`, `Admin`.

### AppUser
| Column | Type | Constraints |
|---|---|---|
| UserID | INT UNSIGNED | PK, AUTO_INCREMENT |
| Username | VARCHAR(100) | NOT NULL, UNIQUE |
| PasswordHash | VARCHAR(255) | NOT NULL |
| RoleID | SMALLINT UNSIGNED | NOT NULL, FK → Role |
| DriverID | VARCHAR(20) | NULL, FK → Driver |
| MechanicID | VARCHAR(20) | NULL, FK → Mechanic |
| ReviewStaffID | MEDIUMINT UNSIGNED | NULL, FK → SafetyStaff |
| — | — | `CHK_AppUser_FK_Consistency`: exactly one of DriverID/MechanicID/ReviewStaffID populated (operational roles), or all three NULL (Managers/Admin) — see §1.20 |

---

# Part 4: Database Security & User Privileges (DBMS Level)

To satisfy least-privilege, security isn't left solely to the application
layer — dedicated MySQL accounts exist per role, each granted only the
table-level permissions its dashboard needs.

| DB User | Application Role | Access Scope |
|---|---|---|
| `admin_db` | Admin | `ALL PRIVILEGES` on `SmartFleet.*`, `WITH GRANT OPTION` — full DDL/DML |
| `fleet_manager_db` | Fleet Manager | Full CRUD on `Vehicle`, `Driver`, `VehicleAssignment`, `DriverCertification`, `SafetyEvent`, `EventReview`, `CoachingRecord`. Read-only on `DriverMonthlySafetyScore` and reference tables (`Depot`, `VehicleCategory`, `VehicleStatus`, `EventType`, `EventSeverity`). No grants on any workshop/maintenance table (denied by omission). |
| `workshop_manager_db` | Workshop Manager | Full CRUD on `MaintenanceJob`, `MaintenanceActivity`, `MechanicWorkSession`, `Mechanic`, `MechanicCertification`, `Part`, `Supplier`, `ActivityPart`, `WarrantyClaim`. Read-only on `Vehicle`, `PredictiveAlert`. No grants on driver/safety tables. |
| `safety_staff_db` | Safety Staff | `SELECT, UPDATE` on `SafetyEvent`. `SELECT, INSERT, UPDATE` on `EventReview` (**not** full CRUD — no `DELETE` granted, so a review can never be removed once created, only progressed). Read-only on `Driver`, `DriverMonthlySafetyScore`, `CoachingRecord`. |
| `driver_db` | Driver | Read-only on `DriverMonthlySafetyScore`, `VehicleAssignment`, `SafetyEvent`, `DriverCertification`. Row-level filtering ("only *my* rows") is **not** expressible via `GRANT` and must be enforced in the application layer. |
| `mechanic_db` | Mechanic | Read-only on `MaintenanceJob`, `MaintenanceActivity`. `INSERT, UPDATE` only on their own `MechanicWorkSession` rows (again, row-scoping is app-layer, not DB-layer). |

**Relationship to `Role`/`AppUser` (§1.20):** these six accounts are a
separate enforcement layer from the `Role`/`AppUser` tables above — there is
currently no schema-level link between "a `Role` row" and "a `CREATE USER`
account," only a naming convention. See §1.20 for the open decision on how the
dashboard should actually connect.

---

