# SmartFleet — Index Performance Documentation

Single-file report: methodology, consolidated results, keep/drop recommendations, and per-index before/after analyses for 24 candidate indexes tested against simplified probes of business queries Q1–Q33.


---

## 1. Scope & methodology

- **Procedure** (per `index_testing.sql`): `ANALYZE FORMAT=JSON` → `CREATE INDEX` → `ANALYZE FORMAT=JSON` again → drop. Probes are simplified single-table shapes of the real queries in `6_business_queries.sql`.
- **Headline metric:** `r_total_time_ms` (query block) from the ANALYZE JSON; per-step fields (`filesort`, `temporary_table`, `access_type`, `rows`/`r_rows`, `using_index`) used to attribute cause; phpMyAdmin wall-clock as cross-check.
- **Caveats:**
  - Before/after pairs ran back-to-back; first runs were sometimes **cold** (IDX 6 is the clearest proof). Where the plan didn't change, the delta is caching, not the index.
  - Probes simplify production shapes (single equality instead of `IN`/`<>`, no joins) — IDX 5, 18, 19, 21, 22 may differ in degree, rarely in kind.
  - IDX 8 (and one IDX 23 run) matched **0 rows**; absolute after-times are optimistic, the plan change is what matters.
  - Deltas under ~0.1 ms on small tables (Vehicle, CoachingRecord, PartSupplier, WarrantyClaim, MechanicCertification) are within run-to-run noise.

## 2. Status legend (from index_testing.sql)

- **Improved Time** — significant margin over the original execution time.
- **Little Time Improvement** — small margin; may vary, no significant overall impact.
- **Worsened Time or No Improvement** — time worsened or no significant improvement.

## 3. Master results table

| IDX | Index (table) | For | Before (ms) | After (ms) | Δ | Status | Rec. |
|---|---|---|---|---|---|---|---|
| 1 | `idx_se_driver_time` (SafetyEvent) | Q9a | 5.0688 | 0.1599 | −97% | Improved | **KEEP** |
| 2 | `idx_se_vin_time` (SafetyEvent) | Q11/Q27 | 1.3883 | 0.0587 | −96% | Improved | **KEEP** |
| 3 | `idx_se_depot_time` (SafetyEvent) | Q3/Q8 | 8.9085 | 0.8122 | −91% | Improved | **KEEP** |
| 4 | `idx_se_review_state_time` (SafetyEvent) | Q5a | 5.0749 | 0.0494 | −99% | Improved | **KEEP** |
| 5 | `idx_se_event_type_driver` (SafetyEvent) | Q10 | 10.335 | 1.1667 | −89% | Improved | **KEEP** |
| 6 | `idx_dmss_driver_year_month` (DriverMonthlySafetyScore) | Q9b | 2.3636 | 0.0885 | −96% * | Improved | **DROP** |
| 7 | `idx_dmss_year_month_score` (DriverMonthlySafetyScore) | Q2a | 4.3837 | 0.7791 | −82% | Improved | **KEEP** |
| 8 | `idx_dc_status_expiry` (DriverCertification) | Q4/Q12 | 2.8706 | 0.0204 | −99% † | Improved | **KEEP** |
| 9 | `idx_mc_status_expiry_type` (MechanicCertification) | Q17/Q26 | 0.1246 | 0.1089 | −13% | Little | **DROP** |
| 10 | `idx_mc_mechanic_type_issue` (MechanicCertification) | Q30 | 0.0504 | 0.044 | −13% | Little | **DROP** |
| 11 | `idx_mj_vin_date` (MaintenanceJob) | Q27/Q20 | 0.5347 | 0.0265 | −95% | Improved | **KEEP** |
| 12 | `idx_mj_workshop_dates` (MaintenanceJob) | Q16 | 0.2418 | 0.0371 | −85% | Improved | **KEEP** |
| 13 | `idx_ma_repeated_fault` (MaintenanceActivity) | Q23 | 0.7161 | 0.0545 | −92% | Improved | **KEEP** |
| 14 | `idx_v_depot_status` (Vehicle) | Q32 | 0.464 | 0.0305 | −93% | Improved | **KEEP** |
| 15 | `idx_v_manufacturer_model` (Vehicle) | Q21 | 0.1144 | 0.0315 | −72% | Little | *optional* |
| 16 | `idx_va_status_depot` (VehicleAssignment) | Q33 | 2.0043 | 0.0462 | −98% | Improved | **KEEP** |
| 17 | `idx_va_driver_start` (VehicleAssignment) | Q13a | 0.0662 | 0.0227 | −66% | Little | *optional* |
| 18 | `idx_pa_status_date` (PredictiveAlert) | Q5b/Q15 | 1.7578 | 0.057 | −97% | Improved | **KEEP** |
| 19 | `idx_ss_status_date` (ScheduledService) | Q22 | 1.0739 | 0.048 | −96% | Improved | **KEEP** |
| 20 | `idx_cr_driver_date` (CoachingRecord) | Q6 | 0.0815 | 0.0203 | −75% | Little | *optional* |
| 21 | `idx_cr_type_outcome` (CoachingRecord) | Q7 | 0.1774 | 0.0492 | −72% | Little | *optional* |
| 22 | `idx_mws_mechanic_activity` (MechanicWorkSession) | Q31 | 1.0745 | 0.0383 | −96% | Improved | **KEEP** |
| 23 | `idx_ps_part_primary_cost` (PartSupplier) | Q29 | 0.0427 | 0.0527 | +23% | Worsened/None | **DROP** |
| 24 | `idx_wc_source_date` (WarrantyClaim) | Q28 | 0.0916 | 0.0501 | −45% | Little | *optional* |

\* IDX 6: after-plan unchanged (optimizer kept `UC_DriverMonthlySafetyScore`, filesort still present) — a cold→warm cache artifact, not the index.
† IDX 8: predicate matched 0 rows; the ALL+filesort → `range` plan change is real and scales once matches exist.

## 4. Recommendations

### 4.1 KEEP — create in production (15)

Real, index-attributable plan changes: filesort/temp-table elimination, full-scan → ref/range conversion, and/or covering (`using_index: true`) access on tables large enough to matter.

```sql
CREATE INDEX idx_se_driver_time        ON SafetyEvent(DriverID, EventTimestamp DESC);
CREATE INDEX idx_se_vin_time           ON SafetyEvent(VIN, EventTimestamp DESC);
CREATE INDEX idx_se_depot_time         ON SafetyEvent(DepotID, EventTimestamp DESC);
CREATE INDEX idx_se_review_state_time  ON SafetyEvent(ReviewState, EventTimestamp);
CREATE INDEX idx_se_event_type_driver  ON SafetyEvent(EventTypeID, DriverID);
CREATE INDEX idx_dmss_year_month_score ON DriverMonthlySafetyScore(Year, Month, Score);
CREATE INDEX idx_dc_status_expiry      ON DriverCertification(Status, ExpiryDate);
CREATE INDEX idx_mj_vin_date           ON MaintenanceJob(VIN, DateOpened DESC);
CREATE INDEX idx_mj_workshop_dates     ON MaintenanceJob(WorkshopID, DateClosed, DateOpened);
CREATE INDEX idx_ma_repeated_fault     ON MaintenanceActivity(RepeatedFaultFlag, ActivityTypeID);
CREATE INDEX idx_v_depot_status        ON Vehicle(DepotID, OperationalStatus);
CREATE INDEX idx_va_status_depot       ON VehicleAssignment(AssignmentStatus, DepotID);
CREATE INDEX idx_pa_status_date        ON PredictiveAlert(AlertStatus, DateGenerated);
CREATE INDEX idx_ss_status_date        ON ScheduledService(Status, ScheduledDate);
CREATE INDEX idx_mws_mechanic_activity ON MechanicWorkSession(MechanicID, ActivityID, StartTime);
```

Caveats: IDX 13 works only while `RepeatedFaultFlag = TRUE` stays the minority (~10% now); IDX 18/19 were tested with single-value equality whereas Q5b/Q22 use `<>` / `IN (...)` in production, which weakens (but doesn't remove) the benefit.

### 4.2 DROP — do not create / remove if present (4)

- **IDX 6** — no plan change; speedup came from warm cache; `UC_DriverMonthlySafetyScore` already serves the `DriverID` lookup.
- **IDX 9** — optimizer never chose it (`FK_MC_CertType`'s 100-row ref is cheaper; no ORDER BY to win).
- **IDX 10** — redundant prefix subset of `UC_MechanicCertification`, which already covers the query; filesort remains either way.
- **IDX 23** — no improvement (marginally worse); filesort remains; the 9-row lookup via `PRIMARY` was already free.

### 4.3 OPTIONAL — genuine but noise-level today (5)

- **IDX 15** — covering ref vs scan on a 250-row table (~0.08 ms saved). Revisit if `Vehicle` grows 10×.
- **IDX 17** — removes a sort and covers, but ~4 rows per driver (~0.04 ms saved).
- **IDX 20** — perfect shape, but the test driver had 1 coaching row; revisit as histories grow.
- **IDX 21** — 487 → 6 rows, but ~0.13 ms absolute; production Q7 uses `Outcome <> 'Passed'`.
- **IDX 24** — scan+sort → ordered covering probe on a 173-row table (~0.04 ms saved).

```sql
-- Optional (commented out):
-- CREATE INDEX idx_v_manufacturer_model ON Vehicle(Manufacturer, Model, VIN);
-- CREATE INDEX idx_va_driver_start      ON VehicleAssignment(DriverID, StartDate);
-- CREATE INDEX idx_cr_driver_date       ON CoachingRecord(DriverID, CoachingDate DESC);
-- CREATE INDEX idx_cr_type_outcome      ON CoachingRecord(CoachingType, Outcome);
-- CREATE INDEX idx_wc_source_date       ON WarrantyClaim(ClaimSource, ClaimDate DESC);
```

---

## 5. Per-index analyses

### IDX 1 — `idx_se_driver_time` (SafetyEvent, Q9a) — KEEP

- **Index:** `(DriverID, EventTimestamp DESC)` · **Status:** Improved Time

```sql
SELECT se.EventID, se.EventTimestamp, v.Model
FROM SafetyEvent se JOIN Vehicle v ON v.VIN = se.VIN
WHERE se.DriverID = 'D-0002' ORDER BY se.EventTimestamp DESC;
```

**Screenshots:** [1v1] before · [1v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 5.0688 | 0.1599 |
| Access / key (`se`) | `ref` / `FK_SE_Driver` | `ref` / `idx_se_driver_time` |
| Rows examined | 24 | 24 |
| Filesort | Yes — 4.4328 ms | **None** (pre-sorted by index) |
| `se` read / `v` join | 4.3465 / 0.5951 ms | 0.0973 / 0.0344 ms |

**Result:** −4.91 ms, ≈97% reduction, ≈32× (wall 0.0058 s → 0.0005 s).
**Why:** same 24 rows both runs — the win is ordering, not filtering: the filesort was ~87% of the original cost and disappears with `(DriverID, EventTimestamp DESC)`. Not covering (the join needs `se.VIN`), but removing the sort alone drives nearly all of the gain.

### IDX 2 — `idx_se_vin_time` (SafetyEvent, Q11/Q27) — KEEP

- **Index:** `(VIN, EventTimestamp DESC)` · **Status:** Improved Time

```sql
SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se
WHERE se.VIN = 'DZRECBSNBKSJ7HP6T' ORDER BY se.EventTimestamp DESC;
```

**Screenshots:** [2v1] before · [2v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 1.3883 | 0.0587 |
| Access / key | `ref` / `FK_SE_Vehicle` | `ref` / `idx_se_vin_time` |
| Rows examined | 47 | 47 |
| Filesort | Yes — 1.3443 ms | **None** |
| `se` read | 1.2829 ms (ICP) | 0.0305 ms |
| `using_index` | — | **true** (covering) |

**Result:** −1.33 ms, ≈96%, ≈24× (wall 0.0027 s → 0.0003 s).
**Why:** two stacked wins — pre-sorted output kills the filesort, and the index covers the SELECT (`EventTimestamp` key column + `EventID` PK rides along), so no clustered lookups. Contrast IDX 1, which can't be covered because the join needs `se.VIN`.

### IDX 3 — `idx_se_depot_time` (SafetyEvent, Q3/Q8) — KEEP

- **Index:** `(DepotID, EventTimestamp DESC)` · **Status:** Improved Time

```sql
SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se
WHERE se.DepotID = 1 ORDER BY se.EventTimestamp DESC;
```

**Screenshots:** [3v1] before · [3v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 8.9085 | 0.8122 |
| Access / key | `ref` / `FK_SE_Depot` | `ref` / `idx_se_depot_time` |
| Rows examined | 1265 | 1265 |
| Filesort | Yes — 8.5102 ms (~96% of cost) | **None** |
| `se` read | 3.9327 ms | 0.859 ms |
| `using_index` | — | **true** (covering) |

**Result:** −8.10 ms, ≈91%, ≈11× (wall 0.0098 s → 0.0011 s).
**Why:** structural win on identical row counts: the composite removes the dominant filesort and, being covering (`EventTimestamp` + PK `EventID`), avoids clustered lookups.

### IDX 4 — `idx_se_review_state_time` (SafetyEvent, Q5a) — KEEP

- **Index:** `(ReviewState, EventTimestamp)` · **Status:** Improved Time

```sql
SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se
WHERE se.ReviewState = 'Pending' ORDER BY se.EventTimestamp;
```

**Screenshots:** [4v1] before · [4v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 5.0749 | 0.0494 |
| Access / key | `ALL` — full scan | `ref` / `idx_se_review_state_time` |
| Rows examined | ~11968, `filtered` 0.45% | 54 |
| Filesort | Yes — 5.0505 ms | **None** |
| `se` read | 3.7592 ms | 0.0284 ms |
| `using_index` | — | **true** (covering) |

**Result:** −5.03 ms, ≈99%, ≈103× (wall 0.0066 s → 0.0003 s).
**Why:** the biggest win, and the only one with a dramatic row-count change: a ~12k-row scan + sort becomes a 54-row ordered, covering probe.

### IDX 5 — `idx_se_event_type_driver` (SafetyEvent, Q10) — KEEP

- **Index:** `(EventTypeID, DriverID)` · **Status:** Improved Time

```sql
SELECT se.DriverID, COUNT(*) FROM SafetyEvent se
WHERE se.EventTypeID = 3 GROUP BY se.DriverID;
```

**Screenshots:** [5v1] before · [5v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 10.335 | 1.1667 |
| Access / key | `ref` / `FK_SE_EventType` | `ref` / `idx_se_event_type_driver` |
| Rows examined | 1814 | 1614 (r_rows) |
| GROUP BY strategy | `temporary_table` + filesort (0.1599 ms, 465 groups) | **None** — grouping off index order |
| `se` read | 8.4068 ms | 0.8124 ms |
| `using_index` | — | **true** (covering) |

**Result:** −9.17 ms, ≈89%, ≈9× (wall 0.0107 s → 0.0019 s).
**Why:** covering index removes clustered lookups, and rows for `EventTypeID = 3` arrive pre-grouped by `DriverID`, eliminating the temp table + filesort.

### IDX 6 — `idx_dmss_driver_year_month` (DriverMonthlySafetyScore, Q9b) — DROP

- **Index:** `(DriverID, Year, Month)` · **Status:** Improved Time (artifact)

```sql
SELECT Year, Month, Score FROM DriverMonthlySafetyScore
WHERE DriverID = 'D-0002' ORDER BY Year, Month;
```

**Screenshots:** [6v1] before · [6v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 2.3636 | 0.0885 |
| Access / key | `ref` / `UC_DriverMonthlySafetyScore` | same — **new index not chosen** |
| Rows examined | 13 | 13 |
| Filesort | Yes — 2.3462 ms | Still present — 0.0712 ms |
| Table read | 2.3138 ms | 0.0531 ms |

**Result:** −2.28 ms, ≈96%, ≈27× on paper (wall 0.0032 s → 0.0004 s) — but the plan is unchanged; every per-step cost shrank ~40×, the signature of a cold first run vs warm second run.
**Why:** the existing unique key already starts with `DriverID`; with 13 rows the optimizer saw no reason to switch. The index is largely redundant — do not create.

### IDX 7 — `idx_dmss_year_month_score` (DriverMonthlySafetyScore, Q2a) — KEEP

- **Index:** `(Year, Month, Score)` · **Status:** Improved Time

```sql
SELECT DriverID, Score FROM DriverMonthlySafetyScore
WHERE Month = 12 AND Year = 2025 ORDER BY Score;
```

**Screenshots:** [7v1] before · [7v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 4.3837 | 0.7791 |
| Access / key | `ALL` — full scan (6266 rows, `filtered` 7.69%) | `ref` / `idx_dmss_year_month_score` (`Year`, `Month`) |
| Rows examined | 6266 | 482 |
| Filesort | Yes — 4.2751 ms | **None** (`Score` trailing column) |
| Table read | 3.3534 ms | 0.6857 ms |

**Result:** −3.60 ms, ≈82%, ≈5.6× (wall 0.0048 s → 0.0011 s).
**Why:** equality on `(Year, Month)` cuts the scan to the 482 matches and trailing `Score` satisfies `ORDER BY Score`. Not covering (`DriverID` absent), so the remainder is clustered lookups.

### IDX 8 — `idx_dc_status_expiry` (DriverCertification, Q4/Q12) — KEEP

- **Index:** `(Status, ExpiryDate)` · **Status:** Improved Time

```sql
SELECT DriverID, ExpiryDate FROM DriverCertification
WHERE Status = 'Active' AND ExpiryDate <= '2026-06-30' ORDER BY ExpiryDate;
```

**Screenshots:** [8v1] before · [8v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 2.8706 | 0.0204 |
| Access / key | `ALL` — full scan (1885 rows, 0 matches) | `range` / `idx_dc_status_expiry` (`Status`, `ExpiryDate`) |
| Filesort | Yes — 2.8559 ms | **None** (range walks `ExpiryDate` in order) |
| Table read | 2.6481 ms | 0.0087 ms |

**Result:** −2.85 ms, ≈99%, ≈141× (wall 0.0031 s → 0.0003 s).
**Why:** textbook equality-then-range-then-order. Caveat: the predicate matched 0 rows in current data, so the after figure is an almost-empty probe — the `range`-instead-of-scan plan change is the real, scalable improvement.

### IDX 9 — `idx_mc_status_expiry_type` (MechanicCertification, Q17/Q26) — DROP

- **Index:** `(Status, ExpiryDate, MechanicCertificationTypeID)` · **Status:** Little Time Improvement

```sql
SELECT MechanicID, ExpiryDate FROM MechanicCertification
WHERE Status = 'Active' AND ExpiryDate > CURDATE() AND MechanicCertificationTypeID = 1;
```

**Screenshots:** [9v1] before · [9v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.1246 | 0.1089 |
| Access / key | `ref` / `FK_MC_CertType` | same — new index in `possible_keys` but **not chosen** |
| Rows examined | 100 (`filtered` 78–88%) | 100 |
| Filesort | None | None |

**Result:** −0.016 ms, ≈13%, ≈1.1× — within noise at sub-0.13 ms absolutes.
**Why:** the optimizer prefers the 100-row `ref` on cert type and filtering afterwards; the new index would walk the Status+Expiry range first and filter type at the end — likely more rows. No ORDER BY to win. Adds nothing.

### IDX 10 — `idx_mc_mechanic_type_issue` (MechanicCertification, Q30) — DROP

- **Index:** `(MechanicID, MechanicCertificationTypeID, IssueDate)` · **Status:** Little Time Improvement

```sql
SELECT MechanicCertificationTypeID, IssueDate FROM MechanicCertification
WHERE MechanicID = 'ME-0001' ORDER BY IssueDate;
```

**Screenshots:** [10v1] before · [10v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.0504 | 0.044 |
| Access / key | `ref` / `UC_MechanicCertification` (covering) | `ref` / new index (covering) |
| Rows examined | 3 | 3 |
| Filesort | Yes — 0.037 ms | Still present — 0.0306 ms |

**Result:** −0.006 ms, ≈13%, ≈1.1× — noise.
**Why:** the existing unique key already covers the query; the new index is a redundant prefix subset and can't remove the filesort (`MechanicCertificationTypeID` sits between `MechanicID` and `IssueDate`). Sorting 3 rows costs ~0.03 ms either way.

### IDX 11 — `idx_mj_vin_date` (MaintenanceJob, Q27/Q20) — KEEP

- **Index:** `(VIN, DateOpened DESC)` · **Status:** Improved Time

```sql
SELECT JobID, DateOpened FROM MaintenanceJob
WHERE VIN = 'DZRECBSNBKSJ7HP6T' ORDER BY DateOpened DESC;
```

**Screenshots:** [11v1] before · [11v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.5347 | 0.0265 |
| Access / key | `ref` / `FK_MJ_Vehicle` | `ref` / `idx_mj_vin_date` |
| Rows examined | 4 | 4 |
| Filesort | Yes — 0.4662 ms | **None** |
| `using_index` | — | **true** (covering) |

**Result:** −0.51 ms, ≈95%, ≈20× (wall 0.0015 s → 0.0003 s).
**Why:** pre-sorted output removes the filesort and the index covers the SELECT (`JobID` = PK rides along).

### IDX 12 — `idx_mj_workshop_dates` (MaintenanceJob, Q16) — KEEP

- **Index:** `(WorkshopID, DateClosed, DateOpened)` · **Status:** Improved Time

```sql
SELECT JobID, DateClosed FROM MaintenanceJob WHERE WorkshopID = 1;
```

**Screenshots:** [12v1] before · [12v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.2418 | 0.0371 |
| Access / key | `ref` / `FK_MJ_Workshop` | `ref` / `idx_mj_workshop_dates` |
| Rows examined | 55 | 55 |
| Filesort | None (no ORDER BY) | None |
| `using_index` | — | **true** (covering) |

**Result:** −0.20 ms, ≈85%, ≈6.5× (wall 0.0021 s → 0.0003 s).
**Why:** purely a covering-index story: every column the query touches lives in the index, so the 55 clustered lookups of the FK path disappear (read 0.2247 → 0.0242 ms). Also serves Q16's join lookup without touching the base table.

### IDX 13 — `idx_ma_repeated_fault` (MaintenanceActivity, Q23) — KEEP

- **Index:** `(RepeatedFaultFlag, ActivityTypeID)` · **Status:** Improved Time (boolean-leading = risky; works while TRUE stays the minority)

```sql
SELECT ActivityID, ActivityTypeID FROM MaintenanceActivity
WHERE RepeatedFaultFlag = TRUE;
```

**Screenshots:** [13v1] before · [13v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.7161 | 0.0545 |
| Access / key | `ALL` — full scan (1428 rows, `filtered` 10.1%) | `ref` / `idx_ma_repeated_fault` |
| Rows examined | 1428 | 144 |
| `using_index` | — | **true** (covering) |

**Result:** −0.66 ms, ≈92%, ≈13× (wall 0.0011 s → 0.0003 s).
**Why:** scan → direct probe to the 144 flagged rows, covering (`ActivityTypeID` key column + PK). Only works because TRUE is ~10% of rows; near 50/50 the optimizer would abandon it.

### IDX 14 — `idx_v_depot_status` (Vehicle, Q32) — KEEP

- **Index:** `(DepotID, OperationalStatus)` · **Status:** Improved Time

```sql
SELECT VIN, OperationalStatus FROM Vehicle
WHERE DepotID = 1 AND OperationalStatus = 2;
```

**Screenshots:** [14v1] before · [14v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.464 | 0.0305 |
| Access / key | `index_merge` intersect (`FK_Vehicle_Depot` ∩ `FK_Vehicle_Status`) | `ref` / `idx_v_depot_status` (`ref: [const, const]`) |
| Rows examined | 12 (r_rows 11) | 11 |
| `using_index` | true | true (covering — `VIN` is PK) |

**Result:** −0.43 ms, ≈93%, ≈15× (wall 0.0042 s → 0.0003 s).
**Why:** both plans cover, but one composite `ref` probe is cheaper machinery than two range scans + row-ID intersection. Matches Q32's equality-on-depot + equality-on-status shape.

### IDX 15 — `idx_v_manufacturer_model` (Vehicle, Q21) — OPTIONAL

- **Index:** `(Manufacturer, Model, VIN)` · **Status:** Little Time Improvement

```sql
SELECT VIN, Model FROM Vehicle WHERE Manufacturer = 'Ford' AND Model = 'Ford H350';
```

**Screenshots:** [15v1] before · [15v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.1144 | 0.0315 |
| Access / key | `ALL` — full scan (250 rows, `filtered` 1.8%) | `ref` / `idx_v_manufacturer_model` (`ref: [const, const]`) |
| Rows examined | 250 | 4 |
| `using_index` | — | **true** (covering) |

**Result:** −0.08 ms, ≈72%, ≈3.6× (wall 0.0011 s → 0.0004 s).
**Why:** structurally perfect (ref probe + covering) but on a 250-row cached table the absolute saving is noise. Create only if `Vehicle`/Q21 becomes hot.

### IDX 16 — `idx_va_status_depot` (VehicleAssignment, Q33) — KEEP

- **Index:** `(AssignmentStatus, DepotID)` · **Status:** Improved Time

```sql
SELECT AssignmentID, DriverID FROM VehicleAssignment
WHERE AssignmentStatus = 'In Operation' AND DepotID = 1;
```

**Screenshots:** [16v1] before · [16v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 2.0043 | 0.0462 |
| Access / key | `ref` / `FK_VA_Depot` (153 rows, `filtered` 1.96%) | `ref` / `idx_va_status_depot` (`ref: [const, const]`) |
| Rows examined | 153 | 3 |
| Table read | 1.9717 ms | 0.0365 ms |

**Result:** −1.96 ms, ≈98%, ≈43× (wall 0.0028 s → 0.0003 s).
**Why:** the FK path read all 153 depot rows and discarded ~98% on status; the composite answers both equalities in one probe. Not covering, but 3 clustered lookups instead of 153.

### IDX 17 — `idx_va_driver_start` (VehicleAssignment, Q13a) — OPTIONAL

- **Index:** `(DriverID, StartDate)` · **Status:** Little Time Improvement

```sql
SELECT AssignmentID, StartDate FROM VehicleAssignment
WHERE DriverID = 'D-0012' ORDER BY StartDate;
```

**Screenshots:** [17v1] before · [17v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.0662 | 0.0227 |
| Access / key | `ref` / `FK_VA_Driver` | `ref` / `idx_va_driver_start` |
| Rows examined | 4 | 4 |
| Filesort | Yes — 0.0511 ms | **None** |
| `using_index` | — | **true** (covering) |

**Result:** −0.04 ms, ≈66%, ≈3× (wall 0.0021 s → 0.0003 s).
**Why:** does everything right (sort removed, covering) but a driver has ~4 assignments — sorting 4 rows cost 0.05 ms. Absolute saving is noise.

### IDX 18 — `idx_pa_status_date` (PredictiveAlert, Q5b/Q15) — KEEP

- **Index:** `(AlertStatus, DateGenerated)` · **Status:** Improved Time

```sql
SELECT AlertID, DateGenerated FROM PredictiveAlert
WHERE AlertStatus = 'Urgent Repair Standby' ORDER BY DateGenerated;
```

**Screenshots:** [18v1] before · [18v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 1.7578 | 0.057 |
| Access / key | `ALL` — full scan (752 rows, `filtered` 4.26%) | `ref` / `idx_pa_status_date` |
| Rows examined | 752 | 32 |
| Filesort | Yes — 1.7387 ms | **None** (trailing `DateGenerated`) |
| `using_index` | — | **true** (covering) |

**Result:** −1.70 ms, ≈97%, ≈31× (wall 0.0020 s → 0.0004 s).
**Why:** scan+sort collapses to an ordered covering probe. Caveat: Q5b's `AlertStatus <> 'Resolved'` inequality benefits less directly than Q15's equality.

### IDX 19 — `idx_ss_status_date` (ScheduledService, Q22) — KEEP

- **Index:** `(Status, ScheduledDate)` · **Status:** Improved Time

```sql
SELECT ScheduleID, ScheduledDate FROM ScheduledService
WHERE Status = 'Scheduled' AND ScheduledDate <= CURDATE() ORDER BY ScheduledDate;
```

**Screenshots:** [19v1] before · [19v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 1.0739 | 0.048 |
| Access / key | `ALL` — full scan (366 rows, `filtered` 15.3%) | `range` / `idx_ss_status_date` (`Status`, `ScheduledDate`) |
| Rows examined | 366 | 56 |
| Filesort | Yes — 1.0418 ms | **None** |
| `using_index` | — | **true** (covering) |

**Result:** −1.03 ms, ≈96%, ≈22× (wall 0.0013 s → 0.0003 s).
**Why:** equality-then-range-then-order, covering. Caveat: Q22's `Status IN ('Scheduled','In Progress')` can break the index sort order across merged ranges; the measured single-status case is the ideal shape.

### IDX 20 — `idx_cr_driver_date` (CoachingRecord, Q6) — OPTIONAL

- **Index:** `(DriverID, CoachingDate DESC)` · **Status:** Little Time Improvement

```sql
SELECT CoachingRecordID, CoachingDate FROM CoachingRecord
WHERE DriverID = 'D-0002' ORDER BY CoachingDate DESC;
```

**Screenshots:** [20v1] before · [20v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.0815 | 0.0203 |
| Access / key | `ref` / `FK_CR_Driver` | `ref` / `idx_cr_driver_date` |
| Rows examined | 1 | 1 |
| Filesort | Yes — 0.0475 ms (1 row) | **None** |
| `using_index` | — | **true** (covering) |

**Result:** −0.06 ms, ≈75%, ≈4× (wall 0.0013 s → 0.0003 s).
**Why:** perfect shape, but the test driver had exactly 1 record — the "before" sorted one row. Revisit as coaching histories grow.

### IDX 21 — `idx_cr_type_outcome` (CoachingRecord, Q7) — OPTIONAL

- **Index:** `(CoachingType, Outcome)` · **Status:** Little Time Improvement

```sql
SELECT DriverID, Outcome FROM CoachingRecord
WHERE CoachingType = 'Retraining' AND Outcome = 'Failed';
```

**Screenshots:** [21v1] before · [21v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.1774 | 0.0492 |
| Access / key | `ALL` — full scan (487 rows, `filtered` 1.23%) | `ref` / `idx_cr_type_outcome` (`ref: [const, const]`) |
| Rows examined | 487 | 6 |
| `using_index` | — | — (not covering: selects `DriverID`) |

**Result:** −0.13 ms, ≈72%, ≈3.6× (wall 0.0015 s → 0.0004 s).
**Why:** clean two-equality probe, but ~0.13 ms absolute on a 487-row table is noise; production Q7 uses `Outcome <> 'Passed'` (multi-range), less neat than tested.

### IDX 22 — `idx_mws_mechanic_activity` (MechanicWorkSession, Q31) — KEEP

- **Index:** `(MechanicID, ActivityID, StartTime)` · **Status:** Improved Time

```sql
SELECT SessionID, ActivityID FROM MechanicWorkSession
WHERE MechanicID = 'ME-0001' ORDER BY ActivityID;
```

**Screenshots:** [22v1] before · [22v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 1.0745 | 0.0383 |
| Access / key | `ref` / `FK_MWS_Mechanic` | `ref` / `idx_mws_mechanic_activity` |
| Rows examined | 11 | 11 |
| Filesort | Yes — 1.0527 ms (~98% of cost) | **None** |
| `using_index` | — | **true** (covering) |

**Result:** −1.04 ms, ≈96%, ≈28× (wall 0.0020 s → 0.0003 s).
**Why:** removes the dominant filesort via index order and covers the SELECT. Trailing `StartTime` also helps Q31 (though Q31 needs `EndTime` too, so not fully covered there).

### IDX 23 — `idx_ps_part_primary_cost` (PartSupplier, Q29) — DROP

- **Index:** `(PartNumber, IsPrimary DESC, UnitCost)` · **Status:** Worsened Time or No Improvement

```sql
SELECT SupplierID, UnitCost FROM PartSupplier
WHERE PartNumber = 1 ORDER BY IsPrimary DESC, UnitCost;
```

**Screenshots:** [23v1] before · [23v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.0427 | 0.0527 (+23%) |
| Access / key | `ref` / `PRIMARY` | `ref` / new index (covering) |
| Rows examined | 9 | 9 (r_rows 0 in this run) |
| Filesort | Yes — 0.0309 ms | **Still present** — 0.0383 ms |

**Result:** marginally *slower*; wall clock moves the other way (0.0008 s → 0.0004 s) — the two signals disagree, i.e. noise.
**Why:** the index is chosen and covering but the filesort remains and a 9-row `PRIMARY` lookup was already free (0.01 ms). Nothing structural improves; ±0.01 ms is per-query overhead.

### IDX 24 — `idx_wc_source_date` (WarrantyClaim, Q28) — OPTIONAL

- **Index:** `(ClaimSource, ClaimDate DESC)` · **Status:** Little Time Improvement

```sql
SELECT ClaimID, ClaimDate FROM WarrantyClaim
WHERE ClaimSource = 'Parts Supplier' ORDER BY ClaimDate DESC;
```

**Screenshots:** [24v1] before · [24v2] after

| Metric | Before | After |
|---|---|---|
| `r_total_time_ms` | 0.0916 | 0.0501 |
| Access / key | `ALL` — full scan (173 rows, `filtered` 31.8%) | `ref` / `idx_wc_source_date` |
| Rows examined | 173 | 55 |
| Filesort | Yes — 0.081 ms | **None** |
| `using_index` | — | **true** (covering) |

**Result:** −0.04 ms, ≈45%, ≈1.8× (wall 0.0003 s → 0.0003 s, unchanged).
**Why:** perfect structural fit (ordered covering probe) on a 173-row table whose full scan + sort cost ~0.09 ms. Relative gain real, absolute noise.