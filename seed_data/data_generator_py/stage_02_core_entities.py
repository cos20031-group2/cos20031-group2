"""
Stage 02 -- Core entities: Depot, Workshop, Vehicle, Driver, Mechanic.

Notes:
- Workshop.DepotID is UNIQUE -- one workshop per depot, so we give every
  depot exactly one (10 depots -> 10 workshops).
- Vehicle.OperationalStatus is seeded as 'Available' for everything here.
  It is NOT touched again by this stage. Later stages (VehicleAssignment,
  MaintenanceJob) are what legitimately change it, and only when they
  insert/update through a real trigger-firing transition -- historical
  Completed/Cancelled assignments never touch Vehicle at all, matching how
  the triggers actually behave. Only the handful of vehicles pushed through
  a live "as of today" transition in later stages end up anywhere else.
- Driver.DrivingEligibility default 'Eligible' is fine on INSERT -- the
  TRG_Driver_BeforeUpdate guard only fires on UPDATE, so a plain insert at
  the column default is unaffected by the cache-write lock.
"""

from utils import SqlFile, gen_vin, gen_plate, gen_driver_id, gen_mechanic_id, gen_local_address
import config


def generate(rng, faker):
    sql = SqlFile(
        "02 - CORE ENTITIES",
        "Depot, Workshop, Vehicle, Driver, Mechanic.",
    )
    state = {}

    # ---------- Depot ----------
    depot_rows = []
    location_ids = list(config.LOCATIONS.keys())
    for i in range(1, config.N_DEPOTS + 1):
        loc_id = location_ids[(i - 1) % len(location_ids)]
        city = config.LOCATIONS[loc_id]
        name = f"{city} Depot {(i - 1) // len(location_ids) + 1}"
        depot_rows.append({
            "DepotID": i,
            "DepotName": name,
            "Address": gen_local_address(rng, city),
            "LocationID": loc_id,
        })
    sql.comment(f"Depot -- {config.N_DEPOTS} depots spread across the 4 existing Locations")
    sql.insert("Depot", ["DepotID", "DepotName", "Address", "LocationID"], depot_rows)
    state["depot_ids"] = [r["DepotID"] for r in depot_rows]

    # ---------- Workshop (one per depot) ----------
    workshop_rows = []
    for depot in depot_rows:
        workshop_rows.append({
            "WorkshopID": depot["DepotID"],  # 1:1 with depot, ID reuse is fine (separate PK)
            "DepotID": depot["DepotID"],
            "Name": f"{depot['DepotName']} Workshop",
            "Address": depot["Address"],
        })
    sql.comment("\nWorkshop -- one per depot (DepotID is UNIQUE on this table)")
    sql.insert("Workshop", ["WorkshopID", "DepotID", "Name", "Address"], workshop_rows)
    state["workshop_ids"] = [r["WorkshopID"] for r in workshop_rows]
    state["workshop_by_depot"] = {r["DepotID"]: r["WorkshopID"] for r in workshop_rows}

    # ---------- Vehicle ----------
    vin_used, plate_used = set(), set()
    category_weights = [5, 2, 2, 3, 1]  # skew toward Delivery Van / Service Vehicle
    manufacturers = ["Toyota", "Isuzu", "Hino", "Ford", "Hyundai", "VinFast", "Mitsubishi Fuso"]
    vehicle_rows = []
    for i in range(1, config.N_VEHICLES + 1):
        cat_id = rng.choices(list(config.VEHICLE_CATEGORIES.keys()), weights=category_weights, k=1)[0]
        manufacturer = rng.choice(manufacturers)
        vehicle_rows.append({
            "VIN": gen_vin(rng, vin_used),
            "RegistrationNumber": gen_plate(rng, plate_used),
            "CategoryID": cat_id,
            "Model": f"{manufacturer} {rng.choice(['300', 'NPR', 'Dutro', 'Transit', 'H350', 'Model-E', 'Canter'])}",
            "Manufacturer": manufacturer,
            "YearOfManufacture": rng.randint(2015, 2025),  # CHK: >= 1980
            "Odometer": rng.randint(5_000, 220_000),
            "DepotID": rng.choice(state["depot_ids"]),
            "OperationalStatus": config.VEHICLE_STATUS_BY_NAME["Available"],
        })
    sql.comment(f"\nVehicle -- {config.N_VEHICLES} vehicles, all seeded Available "
                "(later stages flip status via real trigger-firing transitions)")
    sql.insert(
        "Vehicle",
        ["VIN", "RegistrationNumber", "CategoryID", "Model", "Manufacturer",
         "YearOfManufacture", "Odometer", "DepotID", "OperationalStatus"],
        vehicle_rows,
    )
    state["vehicles"] = vehicle_rows  # keep full rows -- later stages need CategoryID etc.
    state["vins"] = [r["VIN"] for r in vehicle_rows]

    # ---------- Driver ----------
    driver_rows = []
    employment_weights = {"Active": 0.85, "On Leave": 0.12, "Terminated": 0.03}
    for i in range(1, config.N_DRIVERS + 1):
        emp_status = rng.choices(
            list(employment_weights.keys()), weights=list(employment_weights.values()), k=1
        )[0]
        driver_rows.append({
            "DriverID": gen_driver_id(i),
            "FullName": faker.name(),
            "ContactInfo": faker.phone_number(),
            "CurrentDepotID": rng.choice(state["depot_ids"]),
            "EmploymentStatus": emp_status,
            "EmergencyContactDetails": f"{faker.name()} - {faker.phone_number()}",
            # DrivingEligibility omitted -> column DEFAULT 'Eligible' applies.
            # Safe on INSERT: the derived-value guard only blocks UPDATE.
        })
    sql.comment(f"\nDriver -- {config.N_DRIVERS} drivers (DrivingEligibility left at column default)")
    sql.insert(
        "Driver",
        ["DriverID", "FullName", "ContactInfo", "CurrentDepotID",
         "EmploymentStatus", "EmergencyContactDetails"],
        driver_rows,
    )
    state["drivers"] = driver_rows
    state["driver_ids"] = [r["DriverID"] for r in driver_rows]

    # ---------- Mechanic ----------
    mechanic_rows = []
    mech_employment_weights = {"Active": 0.88, "Inactive": 0.05, "Suspended": 0.03, "Terminated": 0.04}
    for i in range(1, config.N_MECHANICS + 1):
        emp_status = rng.choices(
            list(mech_employment_weights.keys()), weights=list(mech_employment_weights.values()), k=1
        )[0]
        mechanic_rows.append({
            "MechanicID": gen_mechanic_id(i),
            "FullName": faker.name(),
            "ContactInfo": faker.phone_number(),
            "WorkshopID": rng.choice(state["workshop_ids"]),
            "EmploymentStatus": emp_status,
        })
    sql.comment(f"\nMechanic -- {config.N_MECHANICS} mechanics")
    sql.insert(
        "Mechanic",
        ["MechanicID", "FullName", "ContactInfo", "WorkshopID", "EmploymentStatus"],
        mechanic_rows,
    )
    state["mechanics"] = mechanic_rows
    state["mechanic_ids"] = [r["MechanicID"] for r in mechanic_rows]

    return sql, state
