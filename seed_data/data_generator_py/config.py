"""
Shared configuration for the Smart Fleet Management seed-data generator.

IMPORTANT: The ID maps below are NOT invented -- they mirror the exact
AUTO_INCREMENT order of the INSERT statements already present in schema.sql's
"SEED DATA: Lookup & Reference Tables" section. This generator assumes
schema.sql has already been run (and creates its rows starting from those
IDs), so none of stages 01+ re-insert or re-derive these lookup tables --
they just reference these IDs directly.
"""

import random
from datetime import date
from dateutil.relativedelta import relativedelta

# ==========================================
# Reproducibility
# ==========================================
SEED = 42
random.seed(SEED)

# ==========================================
# Scale (medium dataset)
# ==========================================
N_DEPOTS = 10
N_VEHICLES = 250
N_DRIVERS = 500
N_MECHANICS = 100

# ==========================================
# Date window: 12 months ending today, with some
# records deliberately left mid-lifecycle as of TODAY.
# ==========================================
TODAY = date.today()
WINDOW_START = TODAY - relativedelta(months=12)

# Convenience list of (month, year) tuples covered by the window, oldest first.
# Used to drive sp_InitializeMonthlyScores calls and SafetyEvent distribution.
def month_year_range(start: date, end: date):
    out = []
    cur = date(start.year, start.month, 1)
    while cur <= end:
        out.append((cur.month, cur.year))
        cur += relativedelta(months=1)
    return out

MONTHS_COVERED = month_year_range(WINDOW_START, TODAY)  # oldest -> newest, includes current month

# ==========================================
# Reference IDs already seeded by schema.sql
# (id -> name, in exact INSERT order)
# ==========================================

LOCATIONS = {1: "Ha Noi", 2: "Da Nang", 3: "Ho Chi Minh City", 4: "Can Tho"}

VEHICLE_CATEGORIES = {
    1: "Delivery Van",
    2: "Refrigerated Truck",
    3: "Electric Van",
    4: "Service Vehicle",
    5: "Heavy Transport Truck",
}

VEHICLE_STATUS = {
    1: "Active",
    2: "Available",
    3: "Under Maintenance",
    4: "Awaiting Inspection",
    5: "Out Of Service",
    6: "Retired",
}
VEHICLE_STATUS_BY_NAME = {v: k for k, v in VEHICLE_STATUS.items()}

DRIVER_CERT_TYPES = {
    1: "Standard License",
    2: "Heavy Vehicle License",
    3: "Refrigerated Transport Certification",
    4: "EV Certification",
    5: "Hazardous Goods Certification",
}

EVENT_TYPES = {
    1: "Harsh braking",
    2: "Rapid acceleration",
    3: "Excessive speeding",
    4: "Sharp cornering",
    5: "Excessive idling",
    6: "Fatigue warnings",
    7: "Seatbelt violations",
    8: "Phone distraction alerts",
}

EVENT_SEVERITY = {1: "Low", 2: "Medium", 3: "High", 4: "Critical"}
EVENT_SEVERITY_BY_NAME = {v: k for k, v in EVENT_SEVERITY.items()}

ALERT_TYPES = {
    1: "Brake Wear Warning",
    2: "Engine Overheating Risk",
    3: "Battery Degradation",
    4: "Oil Quality Deterioration",
    5: "Transmission Fault Warning",
    6: "Cooling System Anomaly",
    7: "Tire Pressure Irregularity",
}

MECHANIC_CERT_TYPES = {
    1: "Standard Vehicle Mechanic License",
    2: "EV Technician Certification",
    3: "Refrigeration Systems Certification",
    4: "Heavy Vehicle Mechanic License",
}

# ActivityTypeID -> (name, RequiredMechanicCertificationTypeID)
ACTIVITY_TYPES = {
    1: ("Routine Inspection", 1),
    2: ("Preventative Servicing", 1),
    3: ("Diagnostic Testing", 1),
    4: ("Emergency Repair", 1),
    5: ("Component Replacement", 1),
    6: ("EV Battery / Electrical Repair", 2),
    7: ("Refrigeration System Repair", 3),
    8: ("Heavy Vehicle Repair", 4),
}

# VehicleCategoryID -> list of required DriverCertificationTypeIDs
# (mirrors VehicleCertificationRequirement seed rows)
VEHICLE_CERT_REQUIREMENTS = {
    1: [1],          # Delivery Van
    2: [1, 2, 3],    # Refrigerated Truck
    3: [1, 4],       # Electric Van
    4: [1],          # Service Vehicle
    5: [2, 5],       # Heavy Transport Truck
}

# VehicleCategoryID -> plausible ActivityTypeIDs for that category (the
# specialist activity types -- EV/Refrigeration/Heavy -- only make sense for
# the matching vehicle category; general activities 1-5 apply everywhere).
CATEGORY_ACTIVITY_TYPES = {
    1: [1, 2, 3, 4, 5],          # Delivery Van
    2: [1, 2, 3, 4, 5, 7],       # Refrigerated Truck (+ Refrigeration System Repair)
    3: [1, 2, 3, 4, 5, 6],       # Electric Van (+ EV Battery/Electrical Repair)
    4: [1, 2, 3, 4, 5],          # Service Vehicle
    5: [1, 2, 3, 4, 5, 8],       # Heavy Transport Truck (+ Heavy Vehicle Repair)
}

# (the generator never inserts DriverScorePenalty directly -- these fire via
# triggers off SafetyEvent -- this map is here purely so later stages can
# reason about which severities/event types will provoke which rules)
PENALTY_RULES = {
    1: ("Base", None, 1),         # Low severity
    2: ("Base", None, 2),         # Medium severity
    3: ("Base", None, 3),         # High severity
    4: ("Base", None, 4),         # Critical severity
    5: ("Conditional", 3, None),  # >3 speeding events/month
    6: ("Conditional", 6, None),  # >2 fatigue warnings/month
}
