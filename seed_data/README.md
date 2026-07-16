# Smart Fleet Management System — Seed Data Generator

Modular Python generator that produces realistic, trigger-consistent seed
data for the Smart Fleet Management System database. Built stage-by-stage
against the actual schema, triggers, and stored procedures rather than
guessing at plausible values — every stage was validated against the real
CHECK constraints and trigger guards before being accepted.

## How to run

```
pip install faker python-dateutil --break-system-packages
python3 run.py
```

Produces `output/01_reference.sql` … `output/09_reviews_coaching.sql`, plus
`output/seed_data_full.sql` (all nine concatenated in run order).

**Execution order**: `schema.sql` → all 5 trigger/procedure files → the
seed data (either the 9 files in order, or `seed_data_full.sql`). Do not
reorder the 9 stages relative to each other — later stages depend on
earlier ones (FKs, trigger cascades, and the `sp_InitializeMonthlyScores`
prerequisite for any `SafetyEvent` insert).

## Scale & scope

- 8 depots, 60 vehicles, 45 drivers, 25 mechanics
- 6-month window ending 2026-07-13 (touches 7 calendar months, since it
  starts and ends mid-month)
- Some records deliberately left mid-lifecycle "as of today" — `Pending`/
  `In Operation` assignments, open `PredictiveAlert`s, a couple of open
  `MaintenanceJob`s — rather than everything resolved into tidy history.

## Key design decisions & assumptions

**Reference data**: `schema.sql` already seeds `Location`, `VehicleCategory`,
`VehicleStatus`, `DriverCertificationType`, `EventType`, `EventSeverity`,
`AlertType`, `MechanicCertificationType`, `ActivityType`,
`VehicleCertificationRequirement`, and `PenaltyRule`. The generator never
re-inserts these — `config.py` hardcodes their exact seeded IDs (matching
`schema.sql`'s INSERT order) and every later stage references them directly.
8 depots share the 4 existing `Location` rows (multiple depots per city).

**`Vehicle.OperationalStatus`** is seeded `Available` for every vehicle and
never touched directly again. Only real trigger-firing transitions (a live
`In Operation` `VehicleAssignment` insert, an open `MaintenanceJob`) change
it afterward — matching how the triggers actually behave, since historical
`Completed`/`Cancelled` assignments never touch `Vehicle` at all.

**Certification coverage** is randomly assigned per driver/mechanic, then
topped up with a guaranteed-minimum pass so every vehicle category and
activity type has at least a handful of eligible staff — otherwise a single
unlucky RNG draw on a combination requirement (e.g. Refrigerated Truck
needing Standard + Heavy + Refrigerated certs together) could leave a
category with only 1 eligible driver out of 45.

**`VehicleAssignment`**: historical rows insert directly as
`Completed`/`Cancelled`, which skips `TRG_VehicleAssignment_BeforeInsert`'s
eligibility gate entirely (it only fires for a row born `In Operation`) —
per the trigger file's own documented assumption. Both vehicle and driver
timelines are still kept non-overlapping in the generator, even though nothing
in the schema enforces it, because a double-booked vehicle/driver would be a
real data-quality bug regardless of what the database catches.

**`PredictiveAlert` / `ScheduledService`**: `sp_AutoScheduleFromAlert` (fired
when an alert is escalated) hardcodes `ScheduledService.ScheduledDate =
CURDATE()` — the real wall-clock date when this SQL is executed, not the
alert's historical date. Historical alerts that led to real maintenance are
therefore inserted `Resolved` directly (skipping that trigger) with their
`ScheduledService` row created manually alongside them, fully under the
generator's own historical-date control. Only a handful of alerts meant to
be genuinely live "as of today" are inserted at an escalated status, letting
the real trigger fire — which is correct there, since `CURDATE()` being "now"
matches the narrative.

**`MaintenanceJob`**: `TotalCost` is a randomized, plausible figure
independent of the actual `ActivityPart` sum — no labour-cost model, per
the explicit decision that labour is a company-side calculation this
project doesn't attempt. This also removes any ordering dependency between
`MaintenanceJob` and its downstream `MaintenanceActivity`/`ActivityPart`
rows, since cost no longer needs to be computed from parts data that doesn't
exist yet at insert time.

Job rows for the same VIN are always appended in chronological/open-last
order within the single multi-row `INSERT` statement, because
`TRG_MaintenanceJob_BeforeInsert`'s one-open-job-per-VIN gate checks for
*any* existing open job on that VIN regardless of the new row's own
`DateClosed` — inserting an open job before that VIN's other historical
rows in the same statement would incorrectly block them.

One vehicle already `In Operation` (from stage 05) is deliberately given a
concurrent open `MaintenanceJob`, exercising the documented "emergency
repair on an In Operation vehicle" scenario from the trigger comments —
`fn_NextVehicleStatus`'s Tier 1 (open job) overriding Tier 2 (open
assignment) until the job closes.

Part stock is tracked locally starting from stage 01's seeded
`CurrentStock` and decremented as `ActivityPart` rows are generated, so the
script never generates a quantity that would violate the stock gate.

**`SafetyEvent`**: only drivers currently `EmploymentStatus != 'Terminated'`
are used. `sp_InitializeMonthlyScores` only creates score rows for
non-Terminated drivers, and `sp_EvaluatePenaltiesForEvent` hard-rejects an
event with no matching score row — since employment status has no history
in this schema, excluding currently-Terminated drivers entirely is the only
safe option. `VIN`/`DepotID` per event are cross-referenced against the
driver's actual `VehicleAssignment` history where possible, falling back to
a random vehicle from their home depot otherwise. Both Conditional
`PenaltyRule`s (>3 speeding events/month, >2 fatigue warnings/month) are
deliberately topped up with a few guaranteed-qualifying driver-months, since
natural random draws at this volume rarely cross either threshold on their
own. Only `SafetyEvent` rows are inserted — `DriverScorePenalty`,
`CoachingRecord` (at the 75/50 score thresholds), and `DrivingEligibility`
suspension all cascade automatically via the existing triggers.

**`EventReview`**: generated only for High/Critical events (Low/Medium never
get reviewed under the schema's own design). All rows insert at `Unread` in
one bulk statement, then progress through sequential `UPDATE`s — Read, then
optionally Commented and/or Closed — respecting
`TRG_EventReview_BeforeUpdate`'s ordering rules. Progression likelihood is
age-weighted (older events are more likely fully Closed by "today"). One
reviewer per event chain, for simplicity — the AND-to-clear multi-reviewer
case isn't exercised here.

**Manual `CoachingRecord`**: a few `Licence Review` rows (never automated by
any trigger) plus a few `Retraining` rows enrolled directly "by staff"
outside the `DriverScorePenalty` cascade — demonstrating that
`TRG_CoachingRecord_AfterInsert` suspends a driver's eligibility for a
non-score reason too, and that resolving one via `UPDATE` correctly clears
it again.

## Changelog

Three bugs found by independent cross-check (stress-testing across 100-300
RNG seeds, re-deriving every CHECK constraint and trigger gate from actual
generated rows) and fixed:

1. **`stage_07_maintenance.py`** — `open_job_vins` (a set of VIN strings)
   was iterated directly. CPython randomizes string hashing per process, so
   iteration order — and every RNG draw made while walking it — varied run
   to run despite the fixed `SEED`. Fixed by iterating
   `sorted(open_job_vins)` instead. Confirmed byte-identical output across
   separate process runs after the fix.
2. **`stage_07_maintenance.py`** — the open-job branch of
   `MechanicWorkSession` end-time generation lacked the same
   `EndTime < StartTime` guard the closed-job branch already had, so a rare
   combination of RNG draws (~2-4% of seeds) could produce a session
   violating `CHK_MWS_Times` and abort the script partway through. Fixed by
   mirroring the closed-job branch's clamp. Re-verified across 300 seeds,
   zero violations.
3. **`stage_08_safety_events.py`** — `SafetyEvent.Odometer` was computed as
   the vehicle's present-day `Vehicle.Odometer` plus a positive random
   offset, regardless of the event's actual date — so every event across
   the 6-month window appeared to occur at a *higher* mileage than the
   vehicle's current reading, and odometer never accumulated over time.
   Fixed by treating `Vehicle.Odometer` as the end-of-window value and
   subtracting an accrual estimate (`~15-45 km/day` back from the event's
   date, ± small noise) instead of adding a flat offset.

## Known simplifications

- Certification and employment status are treated as current-state-only
  when generating historical rows (the schema itself has no history for
  either), so a driver/mechanic's cert or employment status at the time of
  a past event isn't distinguished from their status today.
- `EventReview` uses a single reviewer per event chain rather than modeling
  multiple independent reviewers reaching different states.
- Vehicle/driver timeline non-overlap is enforced by the generator as a
  data-quality choice, not because any constraint requires it.

## Files

```
config.py                    -- scale constants, date window, RNG seed, reference ID maps
utils.py                     -- SQL literal formatting, ID/VIN/plate generators, SqlFile writer
stage_01_reference.py        -- SafetyStaff, Supplier, Part, PartSupplier
stage_02_core_entities.py    -- Depot, Workshop, Vehicle, Driver, Mechanic
stage_03_certifications.py   -- DriverCertification, MechanicCertification
stage_04_score_init.py       -- sp_InitializeMonthlyScores calls
stage_05_vehicle_assignments.py
stage_06_alerts_schedules.py
stage_07_maintenance.py
stage_08_safety_events.py
stage_09_reviews_coaching.py
run.py                       -- orchestrator
```
