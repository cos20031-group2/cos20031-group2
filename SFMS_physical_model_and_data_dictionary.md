# Smart Fleet Management System — Physical Model & Data Dictionary

**Context:** This document covers `schema.sql` exclusively. Trigger-enforced behavior (state-machine guards, cascading recomputation) is documented separately in the trigger-layer docs; this document references it only where necessary to explain a physical design choice.

This guide is divided into four parts:
1. **Architectural & Physical Design Decisions:** The non-obvious conceptual-to-physical translations.
2. **Business Rule Traceability:** Mapping brief requirements to specific schema constraints.
3. **Full Data Dictionary:** Every table and column.
4. **DBMS-Level Security:** The `CREATE USER` / `GRANT` layer.

---

## Part 1: Key Architectural & Physical Design Decisions

### 1.1 Key & Identity Strategy
**Primary Keys: Surrogate vs. Natural**
* **Decision:** Two patterns coexist deliberately. Surrogate `AUTO_INCREMENT` PKs for lookup/reference and pure transaction tables. Natural (business) `VARCHAR` keys for five core entities: `Vehicle` (VIN), `Driver` (DriverID), `Mechanic` (MechanicID), `SafetyEvent` (EventID), and `MaintenanceJob` (JobID).
* **Rationale:** The brief’s operational data uses meaningful codes (e.g., `E091`, `D-112`, `ME-12`). These are the exact identifiers staff search by and filter on in queries. Using them as PKs avoids a redundant surrogate-id + unique-code pair.
* **Alternative Considered:** Pure-surrogate everywhere. Rejected for these five tables—it would double every FK/join path for no integrity benefit.

**Composite Keys vs. Surrogate + UNIQUE**
* **Decision:** 2-column natural relationships get composite PKs (e.g., `PartSupplier`, `ActivityPart`, `VehicleCertificationRequirement`). 3+ column natural relationships get a surrogate PK with a `UNIQUE` constraint (e.g., `DriverCertification`, `DriverMonthlySafetyScore`).
* **Rationale:** A 2-column junction table is simple to reference. A 3+ column natural key (like `DriverID + CertTypeID + IssueDate + ExpiryDate`) would force every downstream FK to carry 4 columns instead of 1. The surrogate PK keeps downstream joins clean while the `UNIQUE` constraint still guarantees the business rule.

**Integer Type Sizing**
* **Decision:** PK/FK width is scaled to realistic row-count ceilings rather than defaulting to `INT` everywhere.
  * `SMALLINT UNSIGNED`: Small, slow-growing reference sets (Locations, Categories, Statuses).
  * `MEDIUMINT UNSIGNED`: Mid-range volume (Safety Staff, Odometers).
  * `INT UNSIGNED`: Higher-cardinality operational tables (Assignments, Parts, Alerts, Certifications).
  * `BIGINT UNSIGNED`: Highest-volume tables (`MechanicWorkSession`, where one activity accumulates many shift sessions).
* **Rationale:** Column width acts as self-documentation of expected scale.

### 1.2 Value Representation & Type Choices
**Monetary Values**
* **Decision:** `BIGINT UNSIGNED` for all money fields (`Part.UnitPrice`, `MaintenanceJob.TotalCost`, etc.) representing whole-number VND, not `DECIMAL`.
* **Rationale:** VND has no minor currency unit. `BIGINT` is used instead of `INT` because aggregated costs can exceed the ~2.1 billion ceiling of a signed `INT` at VND scale.
* **Alternative Considered:** `DECIMAL(12,2)`. Rejected as unnecessary generality; no fractional units or secondary currencies exist in the brief. *(Note: Score fields correctly remain `DECIMAL(5,2)` as they are genuinely fractional).*

**ENUM vs. Lookup Tables**
* **Decision:** A deliberate split. 
  * **Lookup Tables:** Used for values referenced by multiple tables, carrying metadata, or reported on directly (e.g., `VehicleStatus`, `EventType`). Also used for values likely to grow post-launch (e.g., `ActivityType`).
  * **Inline ENUM:** Used for values scoped to one table, small/closed, and primarily driving that table's own state-machine `CHECK` logic (e.g., `AssignmentStatus`, `EmploymentStatus`, `ReviewState`).
* **Rationale:** Lookup tables allow post-launch additions via `INSERT`. ENUMs keep state-machine `CHECK` constraints and trigger `IF` branches as plain string comparisons, avoiding unnecessary joins on every `INSERT`/`UPDATE`.

**Warranty Claim Source (Known Gap)**
* **Decision:** `WarrantyClaim.ClaimSource` is an `ENUM('Vehicle Manufacturer', 'Parts Supplier', 'Internal Claim')`.
* **Known Gap:** There is no `SupplierID` column on `WarrantyClaim`. A "Parts Supplier" claim cannot be traced to the specific supplier directly—only indirectly via `ActivityPart` → `PartSupplier`. Accepted as a scope limitation; a nullable `SupplierID` FK is the natural follow-up if supplier-level accountability becomes a strict requirement later.

### 1.3 Constraints & Integrity Enforcement
**CHECK Constraints as Business-Rule Translation**
* **Decision:** Two types of `CHECK` constraints are used heavily: Format-level (e.g., VIN length, ID prefixes) and State-machine-level (e.g., `CHK_VA_StatusConsistency` ensuring `Completed` requires both `StartDate` and `EndDate`).
* **Rationale:** Encoding state logic at the physical layer makes invalid rows structurally impossible, rather than relying on every piece of app/trigger code to get the logic right independently. Enforces the "fail loudly" principle.

**Generated Column for Group-Level Uniqueness**
* **Decision:** `PartSupplier` uses a generated column: `PrimaryPartNumber INT UNSIGNED GENERATED ALWAYS AS (IF(IsPrimary, PartNumber, NULL)) VIRTUAL`, with a `UNIQUE` constraint on it.
* **Rationale:** Exploits MySQL's rule that `UNIQUE` indexes allow unlimited `NULL`s. This enforces "exactly one primary supplier per part, unlimited backups" at the DB layer.
* **Alternative Considered:** `UNIQUE(PartNumber, IsPrimary)`. Rejected because it would cap *both* `TRUE` and `FALSE` at one row per part, limiting backups to exactly one.

**Optional Foreign Keys & No Cascading Deletes**
* **Decision:** Several FKs are nullable (`MaintenanceJob.ScheduleID`, `MaintenanceActivity.LinkedAlertID`, `Driver.CurrentDepotID`) because the relationships are genuinely optional in the business logic. Furthermore, **no `ON DELETE CASCADE` is used anywhere**; all FKs default to `RESTRICT`.
* **Rationale:** `CASCADE` would allow deleting a `Driver` to silently wipe their entire event/assignment history, violating the brief's historical records requirement. `RESTRICT` forces deletions of fact tables to be deliberate.

### 1.4 Structural & Entity Modeling
**Workshop as a 1:1 Specialization**
* **Decision:** `Workshop` is a separate table linked to `Depot` via a `UNIQUE` FK (physical 1:1), rather than merging workshop columns into `Depot`.
* **Rationale:** `Depot` is referenced by many tables unrelated to maintenance. Merging them would force those tables to carry mostly-`NULL` workshop columns and conflate "a physical company site" with "a maintenance facility".

**Alert-to-Job Linkage: FK on Activity, Not Job**
* **Decision:** `MaintenanceActivity.LinkedAlertID` is the FK to `PredictiveAlert`, placed at the *activity* level, not the *job* level.
* **Rationale:** A single `MaintenanceJob` can bundle multiple activities. Different activities within the same job can address different alerts (e.g., a brake alert and a battery alert resolved in one visit). A job-level FK could only capture one alert per job. Placing it on the activity lets each task link to its specific alert, while `NULL` satisfies the rule that routine work has no alert.

**Closing the Loop: `MaintenanceJob.ScheduleID`**
* **Decision:** Added `MaintenanceJob.ScheduleID` (FK to `ScheduledService`) to allow a job to declare which scheduled service it is fulfilling.
* **Rationale:** Without this, a `MaintenanceJob` closing wouldn't automatically flip the linked `ScheduledService` to `Completed`. The service would sit as "overdue" forever. This is a rare case where *trigger design drove a schema change*.

### 1.5 Historical Accuracy & Derived State
**Voided vs. Revoked Certification Status**
* **Decision:** `DriverCertification` and `MechanicCertification` carry two distinct terminal statuses: `Revoked` (no longer valid going forward; past assignments remain legal) and `Voided` (retroactively invalid; past assignments become illegal).
* **Rationale:** Allows the system to audit past assignments that relied on a retroactively invalidated cert without corrupting the timeline of ordinary expirations. Full renewal history is retained by making the `UNIQUE` constraint span `(PersonID, CertTypeID, IssueDate, ExpiryDate)`, forcing renewals to create new rows rather than overwriting old ones.

**Derived State: "Cache, Not a Record" Pattern**
* **Decision:** `Driver.DrivingEligibility` and `SafetyEvent.ReviewState` are treated as caches. They are updated *only* through centralized stored procedures/triggers.
* **Rationale:** Computing these live via `JOIN`s hurts read performance; letting the app write them directly risks silent drift. `BEFORE UPDATE` triggers block any direct write to these columns unless a specific session flag (e.g., `@sfms_allow_eligibility_write`) is set by the authorized routine.

**Denormalized `DepotID` for Historical Accuracy**
* **Decision:** `VehicleAssignment.DepotID` is stored directly on the assignment row, rather than derived at query time from `Driver.CurrentDepotID`.
* **Rationale:** The brief requires historical records to survive depot transfers. `CurrentDepotID` is a live, changing column. If `VehicleAssignment` didn't store its own `DepotID`, the answer to "which depot was this assignment through?" would silently change retroactively. This is a deliberate 2NF-style choice over strict 3NF to guarantee point-in-time accuracy.

**Splitting Conflated Fields**
* **Decision:** Single fields quietly conflating two distinct facts were split. 
  * `IsActive` (boolean) → `AssignmentStatus` (ENUM) + `StartDate`. (Distinguishes a booking from an active trip).
  * `EmploymentStatus` / `DrivingEligibility`. (Distinguishes "are they employed" from "are they allowed to drive").
  * Terminal status + explicit resolution timestamp (e.g., `CompletionDate` paired with `Status`).
* **Rationale:** Managers need specific, unambiguous information. Inferred distinctions drift out of sync; first-class columns can be validated by `CHECK` and queried directly.

### 1.6 Scope Decisions & Application Layer
**Supplier Performance & the `PartReceipt` Rollback**
* **Decision:** A `PartReceipt` table was built to trace physical shipments for quality auditing, but deliberately reverted. 
* **Rationale:** Once two shipments sit on the same shelf, they're indistinguishable in practice without a FIFO auto-allocation procedure. "Supplier performance" is scoped strictly to price and lead time (covered by `PartSupplier`). Lot-traceability is out of scope for this iteration.

**Application Layer: `Role`/`AppUser` vs. DBMS Security**
* **Decision:** `Role` / `AppUser` handles application-level login (using nullable FKs to `Driver`/`Mechanic`/`SafetyStaff` to avoid supertype redesigns). The `CREATE USER`/`GRANT` block (Part 4) is a separate, lower layer governing raw DB connections.
* **Open Question:** The web app must decide whether to connect using the six shared per-role DB accounts (with `AppUser` handling auth) or as a single service account enforcing everything through `AppUser` in app logic. Neither approach gives row-level filtering for free; that remains an application-layer concern.

---

## Part 2: Business Rule → Schema Traceability

This table maps brief requirements to specific schema mechanisms (CHECK/UNIQUE constraints, table design). Rules primarily enforced by trigger logic are out of scope here.

| Rule | The Business Rule | Table(s) / Column(s) | Mechanism |
| :--- | :--- | :--- | :--- |
| **R10** | Alerts don't always result in a job; if they do, they stay linked. | `MaintenanceActivity.LinkedAlertID` | **Table Design:** FK sits on Activity, not Job, to allow multiple alerts per job. |
| **R11** | A maintenance job may exist independently of any alert. | `MaintenanceActivity.LinkedAlertID` | **Table Design:** Nullable FK allows routine activities with no alert. |
| **R12** | The company operates one workshop per depot. | `Workshop.DepotID` | **Constraint:** `UNIQUE` makes a second workshop on the same depot structurally impossible. |
| **R14** | Each part has one primary supplier, unlimited backups. | `PartSupplier.PrimaryPartNumber` | **Constraint:** Generated column + `UNIQUE` enforces at most one `IsPrimary = TRUE` per part. |
| **R15** | Warranty claims record manufacturer vs. parts supplier. | `WarrantyClaim.ClaimSource` | **Table Design:** `ENUM` restricts to fixed values. *(Known gap: no direct `SupplierID` FK).* |
| **R16** | Full certification renewal history is retained. | `Driver/MechanicCertification` | **Table Design:** `UNIQUE` spans dates + non-destructive rows. `Voided` vs `Revoked` distinguishes retroactive invalidation. |
| **R17** | Historical records survive depot transfers. | `VehicleAssignment.DepotID`, `DriverID`, `IssueDate`, `StartDate`, `EndDate` | **Design + Triggers:** `DepotID` is denormalized (frozen at write time). Core facts are locked by triggers once the assignment leaves `Pending`. |

*(Note: R1–R9 and R13 are enforced primarily via the trigger layer and are documented in the companion trigger file).*

---

## Part 3: Full Data Dictionary

*Unless noted, all surrogate ID columns are `AUTO_INCREMENT`, and all IDs/quantities are `UNSIGNED`.*

### 3.1 Lookup & Reference Tables
*Controlled vocabularies. No foreign keys.*

| Table | Columns & Constraints |
| :--- | :--- |
| **Location** | `LocationID` (PK), `LocationName` (NOT NULL, UNIQUE) |
| **VehicleCategory** | `VehicleCategoryID` (PK), `VehicleCategory` (NOT NULL, UNIQUE) |
| **VehicleStatus** | `VehicleStatusID` (PK), `VehicleStatus` (NOT NULL, UNIQUE) |
| **DriverCertificationType**| `DriverCertificationTypeID` (PK), `DriverCertificationType` (NOT NULL, UNIQUE), `Description` (TEXT, NULL) |
| **EventType** | `EventTypeID` (PK), `EventType` (NOT NULL, UNIQUE) |
| **EventSeverity** | `SeverityID` (PK), `SeverityLevel` (NOT NULL, UNIQUE) |
| **AlertType** | `AlertTypeID` (PK), `AlertType` (NOT NULL, UNIQUE) |
| **MechanicCertificationType**| `MechanicCertificationTypeID` (PK), `MechanicCertificationType` (NOT NULL, UNIQUE) |
| **SafetyStaff** | `ReviewStaffID` (PK), `FullName` (NOT NULL), `ContactInfo` (NOT NULL) |
| **Supplier** | `SupplierID` (PK), `SupplierName` (NOT NULL, UNIQUE), `ContactInfo` (NOT NULL), `Address` (NOT NULL), `DeliveryLeadTime` (NOT NULL, CHK > 0) |
| **Part** | `PartNumber` (PK), `PartName` (NOT NULL), `Description` (NULL), `CurrentStock` (NOT NULL), `ReorderThreshold` (NOT NULL, CHK > 0), `UnitPrice` (BIGINT, NOT NULL, CHK > 0) |

### 3.2 Core Entities & Level 1 Dependencies

| Table | Columns & Constraints |
| :--- | :--- |
| **Depot** | `DepotID` (PK), `DepotName` (NOT NULL, UNIQUE), `Address` (NOT NULL), `LocationID` (NOT NULL, FK → Location) |
| **ActivityType** | `ActivityTypeID` (PK), `ActivityType` (NOT NULL, UNIQUE), `RequiredMechanicCertification` (NOT NULL, FK → MechanicCertificationType) |
| **VehicleCertRequirement**| `VehicleCategoryID` (PK, FK), `DriverCertificationTypeID` (PK, FK) *(Composite PK)* |
| **Workshop** | `WorkshopID` (PK), `DepotID` (NOT NULL, **UNIQUE**, FK → Depot), `Name` (NOT NULL), `Address` (NOT NULL) |
| **Vehicle** | `VIN` (PK, CHK 17 chars), `RegistrationNumber` (NOT NULL, UNIQUE, CHK VN plate), `CategoryID` (NOT NULL, FK), `Model` (NOT NULL), `Manufacturer` (NOT NULL), `YearOfManufacture` (NOT NULL, CHK ≥ 1980), `Odometer` (NOT NULL), `DepotID` (NOT NULL, FK), `OperationalStatus` (NOT NULL, FK) |
| **Driver** | `DriverID` (PK, CHK prefix `D-`), `FullName` (NOT NULL), `ContactInfo` (NOT NULL), `CurrentDepotID` (NULL, FK), `EmploymentStatus` (ENUM, NOT NULL), `EmergencyContactDetails` (NOT NULL), `DrivingEligibility` (ENUM, NOT NULL, DEFAULT 'Eligible' — *derived cache*) |
| **Mechanic** | `MechanicID` (PK, CHK prefix `ME-`), `FullName` (NOT NULL), `ContactInfo` (NOT NULL), `WorkshopID` (NOT NULL, FK), `EmploymentStatus` (ENUM, NOT NULL) |

### 3.3 Assignments, Events & Maintenance

| Table | Columns & Constraints |
| :--- | :--- |
| **VehicleAssignment** | `AssignmentID` (PK), `VIN` (NOT NULL, FK), `DriverID` (NOT NULL, FK), `DepotID` (NOT NULL, FK), `IssueDate` (NOT NULL), `StartDate` (NULL), `EndDate` (NULL), `AssignmentStatus` (ENUM, NOT NULL, DEFAULT 'Pending'; *CHK ties dates to status*) |
| **SafetyEvent** | `EventID` (PK, CHK prefix `E`), `DriverID` (NOT NULL, FK), `VIN` (NOT NULL, FK), `DepotID` (NOT NULL, FK), `EventTimestamp` (NOT NULL), `EventTypeID` (NOT NULL, FK), `SeverityID` (NOT NULL, FK), `Odometer` (NOT NULL), `ReviewState` (ENUM, NOT NULL, DEFAULT 'No Review Required' — *derived cache*) |
| **CoachingRecord** | `CoachingRecordID` (PK), `DriverID` (NOT NULL, FK), `CoachingType` (ENUM, NOT NULL), `CoachingDate` (NOT NULL), `CompletionDate` (NULL), `Outcome` (ENUM, NOT NULL, DEFAULT 'Pending'; *CHK ties CompletionDate to Outcome*) |
| **PredictiveAlert** | `AlertID` (PK), `VIN` (NOT NULL, FK), `AlertTypeID` (NOT NULL, FK), `DateGenerated` (NOT NULL), `ActionTaken` (NULL), `AlertStatus` (ENUM, NOT NULL, DEFAULT 'Unresolved'), `ResolutionDate` (NULL; *CHK ties date to status*) |
| **MaintenanceJob** | `JobID` (PK, CHK prefix `M`), `VIN` (NOT NULL, FK), `WorkshopID` (NOT NULL, FK), `ScheduleID` (NULL, FK → ScheduledService), `DateOpened` (NOT NULL), `DateClosed` (NULL, CHK ≥ DateOpened), `Downtime` (DECIMAL, NOT NULL, CHK ≥ 0), `TotalCost` (BIGINT, NULL; *CHK: if closed, cost must be NOT NULL*) |
| **MaintenanceActivity** | `ActivityID` (PK), `JobID` (NOT NULL, FK), `ActivityTypeID` (NOT NULL, FK), `DiagnosticResult` (NULL), `RepeatedFaultFlag` (NOT NULL), `WarrantyFlag` (NOT NULL), `LinkedAlertID` (NULL, FK → PredictiveAlert) |

### 3.4 Certifications & Reviews

| Table | Columns & Constraints |
| :--- | :--- |
| **DriverCertification** | `DriverCertificationID` (PK), `DriverID` (NOT NULL, FK), `DriverCertificationTypeID` (NOT NULL, FK), `IssueDate` (NOT NULL), `ExpiryDate` (NOT NULL, CHK > IssueDate), `RevocationDate` (NULL), `Status` (ENUM, NOT NULL, DEFAULT 'Active'), `StatusNotes` (NULL). **UNIQUE** (DriverID, TypeID, IssueDate, ExpiryDate) |
| **MechanicCertification**| `MechanicCertificationID` (PK), `MechanicID` (NOT NULL, FK), `MechanicCertificationTypeID` (NOT NULL, FK), `IssueDate` (NOT NULL), `ExpiryDate` (NOT NULL, CHK > IssueDate), `RevocationDate` (NULL), `Status` (ENUM, NOT NULL, DEFAULT 'Active'), `StatusNotes` (NULL). **UNIQUE** (MechanicID, TypeID, IssueDate, ExpiryDate) |
| **EventReview** | `ReviewID` (PK), `EventID` (NOT NULL, FK), `ReviewerStaffID` (NOT NULL, FK), `Comments` (NULL), `Recommendations` (NULL), `Status` (ENUM, NOT NULL, DEFAULT 'Unread'; *CHK: Commented requires Comments, Closed requires DateReviewed*), `DateReviewed` (NULL) |

### 3.5 Penalties, Scores & Schedules

| Table | Columns & Constraints |
| :--- | :--- |
| **PenaltyRule** | `PenaltyRuleID` (PK), `RuleType` (ENUM, NOT NULL), `RuleDescription` (NULL), `EventTypeID` (NULL, FK), `SeverityID` (NULL, FK), `MinEventCount` (NOT NULL, CHK > 0), `TimeWindowMonths` (NOT NULL, CHK > 0), `PenaltyPoints` (DECIMAL, NOT NULL, CHK ≥ 0). *CHK: at least one Event/Severity must be set.* |
| **DriverMonthlyScore** | `DriverMonthlySafetyScoreID` (PK), `DriverID` (NOT NULL, FK), `Month` (NOT NULL, CHK 1–12), `Year` (NOT NULL), `DepotID` (NOT NULL, FK), `Score` (DECIMAL, NOT NULL, CHK ≤ 100). **UNIQUE** (DriverID, Month, Year) |
| **DriverScorePenalty** | `ScorePenaltyID` (PK), `DriverMonthlySafetyScoreID` (NOT NULL, FK), `PenaltyRuleID` (NOT NULL, FK), `EventID` (NOT NULL, FK), `PointsDeducted` (DECIMAL, NOT NULL, CHK > 0), `DateApplied` (NOT NULL) |
| **ScheduledService** | `ScheduleID` (PK), `VIN` (NOT NULL, FK), `ScheduledDate` (NOT NULL), `Reason` (NULL), `AlertID` (NULL, FK), `CompletionDate` (NULL), `Status` (ENUM, NOT NULL, DEFAULT 'Scheduled'; *CHK ties CompletionDate to Status*) |

### 3.6 Workshop Operations & Parts Tracking

| Table | Columns & Constraints |
| :--- | :--- |
| **MechanicWorkSession** | `SessionID` (PK, BIGINT), `MechanicID` (NOT NULL, FK), `ActivityID` (NOT NULL, FK), `StartTime` (NOT NULL), `EndTime` (NULL, CHK ≥ StartTime) |
| **WarrantyClaim** | `ClaimID` (PK), `ActivityID` (NOT NULL, FK), `ClaimSource` (ENUM, NOT NULL), `ClaimDate` (NOT NULL), `Status` (ENUM, NOT NULL, DEFAULT 'Pending'), `ResolutionDate` (NULL; *CHK ties date to status*) |
| **PartSupplier** | `PartNumber` (PK, FK), `SupplierID` (PK, FK), `IsPrimary` (NOT NULL), `UnitCost` (BIGINT, NOT NULL, CHK > 0), `PrimaryPartNumber` (GENERATED, **UNIQUE**). *(Composite PK)* |
| **ActivityPart** | `ActivityID` (PK, FK), `PartNumber` (PK, FK), `ClaimID` (NULL, FK), `QuantityUsed` (NOT NULL, CHK > 0), `UnitCost` (BIGINT, NOT NULL, CHK > 0). *(Composite PK)* |

### 3.7 Application Authentication (Dashboard)

| Table | Columns & Constraints |
| :--- | :--- |
| **Role** | `RoleID` (PK), `RoleName` (NOT NULL, UNIQUE). *Seeded: Driver, Mechanic, Safety Staff, Fleet Manager, Workshop Manager, Admin.* |
| **AppUser** | `UserID` (PK), `Username` (NOT NULL, UNIQUE), `PasswordHash` (NOT NULL), `RoleID` (NOT NULL, FK), `DriverID` (NULL, FK), `MechanicID` (NULL, FK), `ReviewStaffID` (NULL, FK). *CHK: exactly one operational FK populated, or all three NULL.* |

---

## Part 4: Database Security & User Privileges (DBMS Level)

To satisfy least-privilege, dedicated MySQL accounts exist per role, granted only the table-level permissions their dashboard needs.

| DB User | Application Role | Access Scope |
| :--- | :--- | :--- |
| **admin_db** | Admin | `ALL PRIVILEGES` on `SmartFleet.*`, `WITH GRANT OPTION`. |
| **fleet_manager_db** | Fleet Manager | Full CRUD on `Vehicle`, `Driver`, `VehicleAssignment`, `DriverCertification`, `SafetyEvent`, `EventReview`, `CoachingRecord`. Read-only on `DriverMonthlySafetyScore` and reference tables. **No grants** on workshop/maintenance tables. |
| **workshop_manager_db**| Workshop Manager | Full CRUD on `MaintenanceJob`, `MaintenanceActivity`, `MechanicWorkSession`, `Mechanic`, `MechanicCertification`, `Part`, `Supplier`, `ActivityPart`, `WarrantyClaim`. Read-only on `Vehicle`, `PredictiveAlert`. **No grants** on driver/safety tables. |
| **safety_staff_db** | Safety Staff | `SELECT`, `UPDATE` on `SafetyEvent`. `SELECT`, `INSERT`, `UPDATE` on `EventReview` (**No `DELETE`**—reviews can never be removed, only progressed). Read-only on `Driver`, `DriverMonthlySafetyScore`, `CoachingRecord`. |
| **driver_db** | Driver | Read-only on `DriverMonthlySafetyScore`, `VehicleAssignment`, `SafetyEvent`, `DriverCertification`. *(Row-level filtering is app-layer).* |
| **mechanic_db** | Mechanic | Read-only on `MaintenanceJob`, `MaintenanceActivity`. `INSERT`, `UPDATE` only on their own `MechanicWorkSession` rows. *(Row-scoping is app-layer).* |

*Note: These six accounts are a separate enforcement layer from the `Role` / `AppUser` tables. There is currently no schema-level link between a `Role` row and a `CREATE USER` account, only a naming convention.*