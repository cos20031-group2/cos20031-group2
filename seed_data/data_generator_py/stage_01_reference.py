"""
Stage 01 -- Reference tables NOT already seeded by schema.sql.

schema.sql already seeds: Location, VehicleCategory, VehicleStatus,
DriverCertificationType, EventType, EventSeverity, AlertType,
MechanicCertificationType, ActivityType, VehicleCertificationRequirement,
PenaltyRule. Those are referenced via config.py's ID maps, not re-inserted.

This stage only covers: SafetyStaff, Supplier, Part, PartSupplier.
"""

from utils import SqlFile, gen_local_address
import config


def generate(rng, faker):
    sql = SqlFile(
        "01 - REFERENCE DATA (not already seeded in schema.sql)",
        "SafetyStaff, Supplier, Part, PartSupplier. All other lookup tables "
        "are seeded directly by schema.sql and referenced by ID from config.py.",
    )

    state = {}

    # ---------- SafetyStaff ----------
    n_staff = 500
    staff_rows = []
    for i in range(1, n_staff + 1):
        staff_rows.append({
            "ReviewStaffID": i,
            "FullName": faker.name(),
            "ContactInfo": faker.phone_number(),
        })
    sql.comment("SafetyStaff -- reviewers who close out EventReview rows")
    sql.insert("SafetyStaff", ["ReviewStaffID", "FullName", "ContactInfo"], staff_rows)
    state["safety_staff_ids"] = [r["ReviewStaffID"] for r in staff_rows]

    # ---------- Supplier ----------
    n_suppliers = 100
    supplier_rows = []
    for i in range(1, n_suppliers + 1):
        supplier_rows.append({
            "SupplierID": i,
            "SupplierName": faker.company(),
            "ContactInfo": faker.phone_number(),
            "Address": gen_local_address(rng, rng.choice(list(config.LOCATIONS.values()))),
            "DeliveryLeadTime": rng.randint(1, 21),  # CHK: > 0
        })
    sql.comment("\nSupplier")
    sql.insert(
        "Supplier",
        ["SupplierID", "SupplierName", "ContactInfo", "Address", "DeliveryLeadTime"],
        supplier_rows,
    )
    state["supplier_ids"] = [r["SupplierID"] for r in supplier_rows]

    # ---------- Part ----------
    part_catalog = [
        "Brake Pad Set", "Brake Rotor", "Engine Oil Filter", "Air Filter",
        "Cabin Air Filter", "Timing Belt", "Serpentine Belt", "Spark Plug Set",
        "Battery (12V)", "EV Battery Module", "Radiator", "Coolant (per litre)",
        "Alternator", "Starter Motor", "Fuel Pump", "Tire (per unit)",
        "Shock Absorber", "Wheel Bearing", "Clutch Kit", "Transmission Fluid",
        "Refrigerant (per kg)", "Compressor (Refrigeration Unit)", "Evaporator Coil",
        "Windshield Wiper Set", "Headlight Assembly", "Oxygen Sensor",
        "Turbocharger", "Exhaust Muffler", "CV Joint", "Power Steering Pump",
    ]
    # NOTE: Feel free to add more parts to this catalog -- the generator will randomly pick from it.
    part_rows = []
    for i, name in enumerate(part_catalog, start=1):
        part_rows.append({
            "PartNumber": i,
            "PartName": name,
            "Description": None,
            "CurrentStock": rng.randint(5, 120),
            "ReorderThreshold": rng.randint(3, 20),  # CHK: > 0
            "UnitPrice": rng.randint(50_000, 15_000_000),  # VND, CHK: > 0
        })
    sql.comment("\nPart")
    sql.insert(
        "Part",
        ["PartNumber", "PartName", "Description", "CurrentStock", "ReorderThreshold", "UnitPrice"],
        part_rows,
    )
    state["part_numbers"] = [r["PartNumber"] for r in part_rows]
    state["part_stock"] = {r["PartNumber"]: r["CurrentStock"] for r in part_rows}
    state["part_names"] = {r["PartNumber"]: r["PartName"] for r in part_rows}

    # ---------- PartSupplier ----------
    # For each part, randomly assign 1 primary supplier and 4-8 backup suppliers.
    ps_rows = []
    for part_no in state["part_numbers"]:
        # Randomly decide the number of backup suppliers (6, 8, or 10) with weighted probabilities.
        # Using randint for broader compatibility with different RNG objects
        rand_val = rng.randint(1, 10)
        if rand_val <= 5:
            num_backups = 6
        elif rand_val <= 8:
            num_backups = 8
        else:
            num_backups = 10
            
        # Ensure we don't try to sample more suppliers than exist
        num_suppliers = min(1 + num_backups, len(state["supplier_ids"]))
        chosen = rng.sample(state["supplier_ids"], k=num_suppliers)
        
        primary_cost = rng.randint(40_000, 14_000_000)
        
        # 1. Add Primary supplier
        ps_rows.append({
            "PartNumber": part_no,
            "SupplierID": chosen[0],
            "IsPrimary": True,
            "UnitCost": primary_cost,
        })
        
        # 2. Add Backup supplier(s)
        for i in range(1, len(chosen)):
            ps_rows.append({
                "PartNumber": part_no,
                "SupplierID": chosen[i],
                "IsPrimary": False,
                "UnitCost": int(primary_cost * rng.uniform(1.02, 1.25)),
            })

    sql.comment("\nPartSupplier -- one primary + several backup suppliers per part")
    sql.insert(
        "PartSupplier",
        ["PartNumber", "SupplierID", "IsPrimary", "UnitCost"],
        ps_rows,
    )

    return sql, state
