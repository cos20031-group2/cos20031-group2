"""
Stage 03 -- DriverCertification, MechanicCertification.

Coverage strategy: every driver gets 'Standard License' (required by every
VehicleCategory per VEHICLE_CERT_REQUIREMENTS), plus a random subset of the
specialised certs (Heavy Vehicle, Refrigerated Transport, EV, Hazardous
Goods) so stage 5 has a real, non-trivial pool of eligible drivers per
vehicle category to draw from -- not every driver qualifies for every
vehicle, which is the point (exercises the cert gate for real).

Most certs are seeded 'Active' and unexpired as of TODAY (their ExpiryDate
comfortably outlives the 6-month window), with a deliberate minority of
Expired/Revoked/Reinstated rows so the certification gate in
TRG_VehicleAssignment_BeforeInsert / BeforeUpdate has real negative cases to
reject, not just a green light for everyone.
"""

from datetime import timedelta
from utils import SqlFile
import config


def _pick_status_and_dates(rng, today):
    """Returns (IssueDate, ExpiryDate, RevocationDate, Status, StatusNotes)."""
    issue = today - timedelta(days=rng.randint(200, 1500))
    r = rng.random()
    if r < 0.78:
        # Active, comfortably unexpired
        expiry = today + timedelta(days=rng.randint(120, 900))
        return issue, expiry, None, "Active", None
    elif r < 0.90:
        # Expired -- lapsed at some point before today
        expiry = today - timedelta(days=rng.randint(5, 300))
        if expiry <= issue:
            expiry = issue + timedelta(days=30)
        return issue, expiry, None, "Expired", None
    elif r < 0.96:
        # Revoked
        expiry = today + timedelta(days=rng.randint(60, 500))
        revoke = issue + timedelta(days=rng.randint(30, max(31, (today - issue).days - 1)))
        revoke = min(revoke, expiry)
        return issue, expiry, revoke, "Revoked", "Revoked following a compliance review."
    else:
        # Reinstated -- was revoked, later reinstated; still needs RevocationDate NOT NULL
        expiry = today + timedelta(days=rng.randint(120, 700))
        revoke = issue + timedelta(days=rng.randint(30, max(31, (today - issue).days - 60)))
        revoke = min(revoke, expiry)
        return issue, expiry, revoke, "Reinstated", "Reinstated after remedial action."


def generate(rng, core_state):
    sql = SqlFile(
        "03 - CERTIFICATIONS",
        "DriverCertification and MechanicCertification. Standard License is "
        "universal for drivers; specialised certs are distributed so vehicle "
        "category gating in VehicleAssignment has real winners and losers.",
    )
    state = {}
    today = config.TODAY

    # ---------- DriverCertification ----------
    dc_rows = []
    dc_id = 1
    driver_cert_holdings = {}  # DriverID -> set of DriverCertificationTypeIDs currently 'Active'/'Reinstated' & unexpired

    for driver in core_state["drivers"]:
        did = driver["DriverID"]
        held_active = set()

        # Standard License (id 1) -- required by 4 of the 5 vehicle categories
        # (all but Heavy Transport Truck, which only needs Heavy Vehicle +
        # Hazardous Goods), so most drivers get it, but it's not guaranteed --
        # a driver who only ever drives Heavy Transport Trucks genuinely
        # doesn't need it. High probability since Delivery Van and Service
        # Vehicle (the two most common categories by fleet weight) need
        # nothing else; the coverage-guarantee pass below backstops any
        # category that ends up short regardless.
        cert_types_for_driver = []
        if rng.random() < 0.85:
            cert_types_for_driver.append(1)

        # Randomly layer on specialised certs. Probabilities bumped above the
        # naive per-cert rate because categories 2 and 5 require *combinations*
        # (Heavy AND Refrigerated; Heavy AND Hazardous) -- independent 0.15-0.20
        # rates left only ~5 eligible driver for those categories out of 500,
        # too thin a margin for the live "as of today" assignments in stage 5.
        if rng.random() < 0.42:
            cert_types_for_driver.append(2)  # Heavy Vehicle
        if rng.random() < 0.32:
            cert_types_for_driver.append(3)  # Refrigerated Transport
        if rng.random() < 0.25:
            cert_types_for_driver.append(4)  # EV Certification
        if rng.random() < 0.28:
            cert_types_for_driver.append(5)  # Hazardous Goods

        for cert_type in cert_types_for_driver:
            issue, expiry, revoke, status, notes = _pick_status_and_dates(rng, today)
            dc_rows.append({
                "DriverCertificationID": dc_id,
                "DriverID": did,
                "DriverCertificationTypeID": cert_type,
                "IssueDate": issue,
                "ExpiryDate": expiry,
                "RevocationDate": revoke,
                "Status": status,
                "StatusNotes": notes,
            })
            if status in ("Active", "Reinstated") and expiry > today:
                held_active.add(cert_type)
            dc_id += 1

        driver_cert_holdings[did] = held_active

    # ---------- Coverage guarantee pass ----------
    # Random assignment above can land badly for categories that need a
    # *combination* of certs (Refrigerated Truck needs 1+2+3, Heavy Transport
    # needs 2+5) -- a single unlucky RNG draw can leave a category with only
    # 1 eligible driver out of many, too thin for stage 5's live "as of today"
    # assignments to reliably find someone. Top up directly instead of
    # re-tuning probabilities blindly.
    MIN_ELIGIBLE_DRIVERS = 500
    driver_ids_all = [d["DriverID"] for d in core_state["drivers"]]
    for required in config.VEHICLE_CERT_REQUIREMENTS.values():
        eligible = [did for did in driver_ids_all if set(required).issubset(driver_cert_holdings[did])]
        shortfall = MIN_ELIGIBLE_DRIVERS - len(eligible)
        if shortfall <= 0:
            continue
        candidates = [did for did in driver_ids_all if did not in eligible]
        rng.shuffle(candidates)
        for did in candidates[:shortfall]:
            for cert_type in required:
                if cert_type in driver_cert_holdings[did]:
                    continue
                issue = today - timedelta(days=rng.randint(200, 800))
                expiry = today + timedelta(days=rng.randint(365, 900))
                dc_rows.append({
                    "DriverCertificationID": dc_id,
                    "DriverID": did,
                    "DriverCertificationTypeID": cert_type,
                    "IssueDate": issue,
                    "ExpiryDate": expiry,
                    "RevocationDate": None,
                    "Status": "Active",
                    "StatusNotes": "Top-up grant to guarantee category coverage.",
                })
                dc_id += 1
                driver_cert_holdings[did].add(cert_type)

    sql.comment("DriverCertification")
    sql.insert(
        "DriverCertification",
        ["DriverCertificationID", "DriverID", "DriverCertificationTypeID",
         "IssueDate", "ExpiryDate", "RevocationDate", "Status", "StatusNotes"],
        dc_rows,
    )
    state["driver_cert_holdings"] = driver_cert_holdings  # for stage 5's eligibility pre-filter

    # ---------- MechanicCertification ----------
    mc_rows = []
    mc_id = 1
    mechanic_cert_holdings = {}

    for mech in core_state["mechanics"]:
        mid = mech["MechanicID"]
        held_active = set()

        cert_types_for_mech = [1]  # Standard Vehicle Mechanic License -- universal
        if rng.random() < 0.25:
            cert_types_for_mech.append(2)  # EV Technician
        if rng.random() < 0.20:
            cert_types_for_mech.append(3)  # Refrigeration Systems
        if rng.random() < 0.30:
            cert_types_for_mech.append(4)  # Heavy Vehicle Mechanic

        for cert_type in cert_types_for_mech:
            issue, expiry, revoke, status, notes = _pick_status_and_dates(rng, today)
            mc_rows.append({
                "MechanicCertificationID": mc_id,
                "MechanicID": mid,
                "MechanicCertificationTypeID": cert_type,
                "IssueDate": issue,
                "ExpiryDate": expiry,
                "RevocationDate": revoke,
                "Status": status,
                "StatusNotes": notes,
            })
            if status in ("Active", "Reinstated") and expiry > today:
                held_active.add(cert_type)
            mc_id += 1

        mechanic_cert_holdings[mid] = held_active

    # Same coverage guarantee, mirrored for mechanics/activity types.
    MIN_ELIGIBLE_MECHANICS = 500
    mechanic_ids_all = [m["MechanicID"] for m in core_state["mechanics"]]
    activity_cert_ids = {cert_id for _, cert_id in config.ACTIVITY_TYPES.values()}
    for cert_id in activity_cert_ids:
        eligible = [mid for mid in mechanic_ids_all if cert_id in mechanic_cert_holdings[mid]]
        shortfall = MIN_ELIGIBLE_MECHANICS - len(eligible)
        if shortfall <= 0:
            continue
        candidates = [mid for mid in mechanic_ids_all if mid not in eligible]
        rng.shuffle(candidates)
        for mid in candidates[:shortfall]:
            issue = today - timedelta(days=rng.randint(200, 800))
            expiry = today + timedelta(days=rng.randint(365, 900))
            mc_rows.append({
                "MechanicCertificationID": mc_id,
                "MechanicID": mid,
                "MechanicCertificationTypeID": cert_id,
                "IssueDate": issue,
                "ExpiryDate": expiry,
                "RevocationDate": None,
                "Status": "Active",
                "StatusNotes": "Top-up grant to guarantee activity-type coverage.",
            })
            mc_id += 1
            mechanic_cert_holdings[mid].add(cert_id)

    sql.comment("\nMechanicCertification")
    sql.insert(
        "MechanicCertification",
        ["MechanicCertificationID", "MechanicID", "MechanicCertificationTypeID",
         "IssueDate", "ExpiryDate", "RevocationDate", "Status", "StatusNotes"],
        mc_rows,
    )
    state["mechanic_cert_holdings"] = mechanic_cert_holdings

    return sql, state
