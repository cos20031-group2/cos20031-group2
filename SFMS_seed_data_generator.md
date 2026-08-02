# SFMS Seed Data Generator Documentation

**Context:** This document covers the custom Python pipeline used to generate the SFMS dataset. It is the third pillar of the system documentation, alongside the Physical Model (schema) and the Trigger Layer (business logic). 

While the schema defines the rules and the triggers enforce them, this generator is responsible for **orchestrating the exact sequence of data writes** required to satisfy those rules without triggering false-positive constraint violations.

---

## 1. The "Why": The Trigger-Awareness Problem

Standard data generation tools (like Mockaroo or simple SQL scripts) generate rows independently. In the SFMS database, this approach fails immediately because the triggers enforce strict state machines, cascading recomputations, and cross-table dependencies. 

Dumping rows blindly would violate constraints in three specific ways:
1. **Missing Prerequisites (The `SIGNAL` Guard):** Inserting a `SafetyEvent` before the driver's `DriverMonthlySafetyScore` row exists will cause File 3's `sp_EvaluatePenaltiesForEvent` to throw a hard `SIGNAL` error, halting the import.
2. **State Machine Violations:** Inserting an `EventReview` directly as `Closed` will be rejected by File 4's `TRG_EventReview_BeforeUpdate`, which strictly enforces the `Unread → Read → Commented → Closed` progression.
3. **`AUTO_INCREMENT` Collisions:** File 2's triggers automatically create `ScheduledService` rows when alerts escalate. If the generator inserts manual schedules first, the database's auto-increment counter will eventually collide with the trigger-generated rows.

**The Solution:** We wrote a staged Python generator that produces insert-ordered `.sql` files. It explicitly coordinates state across stages, ensuring every row satisfies the schema's trigger logic when executed, while letting the triggers themselves handle the cascading business logic (like score deductions and eligibility flags).

---

## 2. Architecture & Execution Model

The generator is a **10-stage Python pipeline** driven by `run.py`. 

### State Passing & Dependency Resolution
The core architectural feature of the pipeline is **state passing**. Each stage returns two objects to the next stage:
1. A `SqlFile` object (the accumulated SQL `INSERT`/`UPDATE` statements for that stage).
2. A `state` dictionary containing the generated data entities.

This allows later stages to reference earlier decisions dynamically, rather than relying on hardcoded assumptions. For example:
* **Stage 03 → Stage 05:** Stage 03's generated certification holdings are passed in the `state` dict, which Stage 05 reads to filter for *actually eligible* drivers before creating `VehicleAssignment` rows.
* **Stage 06 → Stage 07:** Stage 06's list of open `ScheduledService` IDs is passed forward, allowing Stage 07's job placer to deliberately link `MaintenanceJob` rows to those specific open schedules to test the trigger back-writes.

### Reproducibility & Scale
* **Fixed Seed:** The dataset uses a fixed random seed (`42`) to ensure every run produces the exact same data, making debugging and evaluation fully reproducible.
* **Scale:** The resulting dataset spans roughly 20 rows (lookup tables) to ~12,000 rows (safety events).

---

## 3. Stage-by-Stage Breakdown

Each stage is designed to navigate specific trigger gates and schema constraints.

| Stage | Output File | Populates | Key Trigger/Schema Constraints Navigated |
| :--- | :--- | :--- | :--- |
| **01** | `01_reference.sql` | `SafetyStaff`, `Supplier`, `Part`, `PartSupplier` | **None.** Pure reference data. Seeded first to satisfy Foreign Keys for all subsequent stages. |
| **02** | `02_core_entities.sql` | `Depot`, `Workshop`, `Vehicle`, `Driver`, `Mechanic` | **Initial State:** All vehicles are seeded as `Available`. All drivers as `Eligible`. Later stages will update these via real trigger-firing transitions. |
| **03** | `03_certifications.sql` | `DriverCertification`, `MechanicCertification` | **Coverage Guarantee:** Runs a secondary pass to ensure a minimum pool of eligible drivers per vehicle category. This guarantees Stage 05 has real choices and doesn't fail the assignment gate. |
| **04** | `04_score_init.sql` | `DriverMonthlySafetyScore` (via SP) | **The `SIGNAL` Guard:** Calls `sp_InitializeMonthlyScores` for every month in the dataset window. **Must** run before Stage 08, or File 3's penalty evaluation will throw a fatal `SIGNAL` error. |
| **05** | `05_vehicle_assignments.sql` | `VehicleAssignment` | **The Eligibility Gate:** File 1's `BeforeInsert` trigger only validates rows born as `'In Operation'`. Historical rows are intentionally inserted directly as `'Completed'`/`'Cancelled'` to bypass the gate. A small subset is inserted as `'Pending'`/`'In Operation'` for live-state demos. |
| **06** | `06_alerts_schedules.sql` | `PredictiveAlert`, `ScheduledService` | **`AUTO_INCREMENT` Collision:** Non-escalated alerts are inserted first. Then, manual `ScheduledService` rows are inserted with **explicit IDs**. Finally, live-escalated alerts are inserted last. This prevents trigger-generated schedules from colliding with manual ones. |
| **07** | `07_maintenance.sql` | `MaintenanceJob`, `MaintenanceActivity`, `MechanicWorkSession`, `ActivityPart`, `WarrantyClaim` | **Trigger Back-Writes:** Closing these jobs via `DateClosed` triggers File 2's `AfterUpdate`, which automatically marks the linked `ScheduledService` as `Completed`. Includes deliberately open jobs to demonstrate live workshop states. |
| **08** | `08_safety_events.sql` | `SafetyEvent` | **Chronological Ordering:** Inserts events *only*. The triggers automatically handle the penalty cascade. **Crucial:** Rows are sorted chronologically so File 3's `Conditional` penalty rules (which check for repeated incidents within a time window) evaluate correctly. |
| **09** | `09_reviews_coaching.sql` | `EventReview`, `CoachingRecord` | **The Read-Before-Close Guard:** File 4's triggers strictly block `Unread → Closed`. The generator must script sequential `UPDATE` statements (`Unread` → `Read` → `Commented` → `Closed`) to respect the state machine. |
| **10** | `10_app_users.sql` | `AppUser` | **FK Consistency:** Creates one login per operational staff member. The schema's `CHK_AppUser_FK_Consistency` ensures exactly one role-linking FK is populated. All accounts share the dev password `1234`. |

---

## 4. How to Run

The pipeline is split into two distinct phases: **Generation** (Python) and **Execution** (MySQL via Batch Script).

### Step 1: Generate the SQL Files (Python)
Run the Python pipeline to generate the 10 numbered `.sql` files.

```bash
python run.py
```

* **Output Location:** The files are written to `seed_data/data_generator_py/output/`.
* **What this does:** This step *only* writes the `.sql` text files to disk. It does not connect to the database. This allows you to inspect the generated SQL, verify the state-passing logic, or modify the files manually before execution if needed.

### Step 2: Import the Full Database (MySQL)
The `import.bat` script automates the entire database build pipeline for XAMPP environments. 

**Prerequisites:**
1. Ensure XAMPP (specifically the MySQL service) is running.
2. Place `import.bat` in the project root directory (`cos20031-group2/`).

**Execution:**
1. Open the **XAMPP Control Panel**.
2. Click **Shell** to open the command line.
3. Navigate to the project folder:
   ```bash
   cd C:\xampp\htdocs\yourpath\cos20031-group2
   ```
4. Run the script:
   ```bash
   import.bat
   ```

### Under the Hood: What `import.bat` Does
The batch script executes a strict **16-step sequence** to ensure the database is built in the exact order the triggers require. 

1. **Database Creation:** Creates the `SmartFleet` database if it doesn't already exist.
2. **Environment Tuning:** Raises MySQL's `max_allowed_packet` to handle the large, multi-row `INSERT` statements generated by the Python script.
3. **Schema Import:** Imports `schema.sql` (Tables, Views, Constraints).
4. **Trigger Import:** Imports the **five trigger files** in order (establishing the business logic).
5. **Seed Data Import:** Imports the **ten seed files** (`01_reference.sql` through `10_app_users.sql`) in exact chronological order.

**Error Handling & Configuration:**
* **Fail-Fast:** The script stops immediately on any SQL error and prints exactly which step failed, preventing silent data corruption.
* **Credentials:** By default, it connects as `root` with no password (the standard XAMPP default). If your MySQL root user has a password, open `import.bat` in a text editor and set it in the `MYSQLPW` variable at the top of the file.