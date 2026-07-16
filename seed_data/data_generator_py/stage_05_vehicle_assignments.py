"""
Stage 05 -- VehicleAssignment.

Historical rows insert directly as 'Completed' or 'Cancelled'. Per
TRG_VehicleAssignment_BeforeInsert, the eligibility/certification gate only
runs when a row is born 'In Operation' -- so these historical backfills
deliberately skip it, matching the trigger file's own documented assumption.
Drivers are still chosen from the cert-eligible pool for the vehicle's
category, for realism, even though it's not enforced.

A small number of vehicles get one additional "as of today" row that DOES
go through the real gate: either 'In Operation' (driver + vehicle currently
active/eligible/certified, inserted directly per the walk-up case) or
'Pending' (booked, not yet started -- gate doesn't apply to Pending either).
These are the vehicles/drivers that end up in a genuinely live state for
stage 07 (maintenance) and demo purposes to coordinate around.

Scheduling: both per-vehicle and per-driver timelines are tracked and kept
non-overlapping -- not enforced by any constraint in schema.sql, but a
vehicle/driver being double-booked would be a real data-quality bug in any
fleet system, and this project's whole ethos (per earlier discussion) is
seeding discipline over relying on the database to catch sloppy generation.
"""

from datetime import datetime, time, timedelta
from utils import SqlFile
import config


def _overlaps(a_start, a_end, b_start, b_end):
    return a_start < b_end and b_start < a_end


def _pick_free_driver(pool, busy, start_dt, end_dt, rng, max_attempts=12):
    if not pool:
        return None
    candidates = list(pool)
    rng.shuffle(candidates)
    for did in candidates[:max_attempts]:
        conflicts = any(_overlaps(start_dt, end_dt, b_s, b_e) for b_s, b_e in busy.get(did, []))
        if not conflicts:
            return did
    return None


def generate(rng, core_state, cert_state):
    sql = SqlFile(
        "05 - VEHICLE ASSIGNMENTS",
        "Per-vehicle assignment history over the 12-month window. Historical "
        "rows insert directly Completed/Cancelled (skip the live gate by "
        "design); a handful of vehicles get one live In Operation/Pending "
        "row as of today that goes through the real eligibility gate.",
    )
    state = {}

    driver_ids_all = core_state["driver_ids"]
    driver_cert_holdings = cert_state["driver_cert_holdings"]

    eligible_by_category = {}
    for cat_id, required in config.VEHICLE_CERT_REQUIREMENTS.items():
        eligible_by_category[cat_id] = [
            did for did in driver_ids_all
            if set(required).issubset(driver_cert_holdings.get(did, set()))
        ]

    # Only currently-Active drivers are used for the LIVE row (the gate checks
    # this for real); historical rows draw from the full cert-eligible pool
    # regardless of current employment status (employment status has no
    # history in this schema, so this is a deliberate seed-data simplification).
    active_driver_ids = {d["DriverID"] for d in core_state["drivers"] if d["EmploymentStatus"] == "Active"}

    window_start_dt = datetime.combine(config.WINDOW_START, time(6, 0))
    today_dt = datetime.combine(config.TODAY, time(9, 0))
    FAR_FUTURE = today_dt + timedelta(days=3650)  # sentinel for open-ended 'In Operation' busy-blocking

    driver_busy = {did: [] for did in driver_ids_all}

    vins = list(core_state["vins"])
    rng.shuffle(vins)
    # Proportional to fleet size, preserving the original 10-per-60-vehicle
    # and 5-per-60-vehicle ratios rather than a hardcoded absolute count.
    n_live_in_operation = min(max(1, round(len(vins) * 10 / 60)), len(vins))
    n_live_pending = min(max(1, round(len(vins) * 5 / 60)), len(vins) - n_live_in_operation)
    live_in_operation_vins = set(vins[:n_live_in_operation])
    live_pending_vins = set(vins[n_live_in_operation:n_live_in_operation + n_live_pending])

    vehicles_by_vin = {v["VIN"]: v for v in core_state["vehicles"]}

    rows = []
    assignment_id = 1
    vehicle_live_state = {}  # VIN -> 'in_operation' | 'pending' | None

    for vin in core_state["vins"]:
        vehicle = vehicles_by_vin[vin]
        cat_id = vehicle["CategoryID"]
        depot_id = vehicle["DepotID"]
        pool = eligible_by_category.get(cat_id) or driver_ids_all

        is_live_op = vin in live_in_operation_vins
        is_live_pending = vin in live_pending_vins

        n_assignments = rng.randint(3, 5)
        n_historical = max(1, n_assignments - (1 if (is_live_op or is_live_pending) else 0))

        cursor_dt = window_start_dt
        # Leave enough room at the end for the live row, if this vehicle gets one.
        historical_ceiling = today_dt - timedelta(days=3) if (is_live_op or is_live_pending) else today_dt

        for _ in range(n_historical):
            gap = timedelta(days=rng.randint(1, 15), hours=rng.randint(0, 23))
            issue_dt = cursor_dt + gap
            if issue_dt >= historical_ceiling - timedelta(days=2):
                break

            start_dt = issue_dt + timedelta(hours=rng.randint(1, 48))
            duration = timedelta(days=rng.randint(1, 10), hours=rng.randint(0, 12))
            end_dt = start_dt + duration
            if end_dt >= historical_ceiling:
                end_dt = historical_ceiling - timedelta(hours=rng.randint(1, 12))
                if end_dt <= start_dt:
                    cursor_dt = issue_dt
                    continue

            cancelled = rng.random() < 0.12
            if cancelled:
                no_start = rng.random() < 0.4
                row_start = None if no_start else start_dt
                row_end = end_dt
                status = "Cancelled"
                busy_start, busy_end = issue_dt, end_dt
            else:
                row_start, row_end = start_dt, end_dt
                status = "Completed"
                busy_start, busy_end = start_dt, end_dt

            driver_id = _pick_free_driver(pool, driver_busy, busy_start, busy_end, rng)
            if driver_id is None:
                cursor_dt = end_dt
                continue

            rows.append({
                "AssignmentID": assignment_id, "VIN": vin, "DriverID": driver_id,
                "DepotID": depot_id, "IssueDate": issue_dt,
                "StartDate": row_start, "EndDate": row_end,
                "AssignmentStatus": status,
            })
            assignment_id += 1
            driver_busy[driver_id].append((busy_start, busy_end))
            cursor_dt = end_dt

        # ---------- Live "as of today" row ----------
        if is_live_op:
            issue_dt = today_dt - timedelta(hours=rng.randint(4, 30))
            start_dt = today_dt - timedelta(hours=rng.randint(1, 3))
            eligible_now = [did for did in pool if did in active_driver_ids]
            driver_id = _pick_free_driver(eligible_now, driver_busy, issue_dt, FAR_FUTURE, rng)
            if driver_id is not None:
                rows.append({
                    "AssignmentID": assignment_id, "VIN": vin, "DriverID": driver_id,
                    "DepotID": depot_id, "IssueDate": issue_dt,
                    "StartDate": start_dt, "EndDate": None,
                    "AssignmentStatus": "In Operation",
                })
                assignment_id += 1
                driver_busy[driver_id].append((issue_dt, FAR_FUTURE))
                vehicle_live_state[vin] = "in_operation"
        elif is_live_pending:
            issue_dt = today_dt - timedelta(hours=rng.randint(1, 48))
            eligible_now = [did for did in pool if did in active_driver_ids]
            driver_id = _pick_free_driver(eligible_now, driver_busy, issue_dt, FAR_FUTURE, rng)
            if driver_id is not None:
                rows.append({
                    "AssignmentID": assignment_id, "VIN": vin, "DriverID": driver_id,
                    "DepotID": depot_id, "IssueDate": issue_dt,
                    "StartDate": None, "EndDate": None,
                    "AssignmentStatus": "Pending",
                })
                assignment_id += 1
                # Pending doesn't block the driver's real-world availability
                # much (nothing physically happened yet), but avoid an
                # obviously-double-booked-on-paper look by still blocking a
                # short window around the booking.
                driver_busy[driver_id].append((issue_dt, issue_dt + timedelta(days=2)))
                vehicle_live_state[vin] = "pending"

    sql.comment(f"VehicleAssignment -- {len(rows)} rows across {len(core_state['vins'])} vehicles "
                f"({len(live_in_operation_vins)} live In Operation, {len(live_pending_vins)} live Pending)")
    sql.insert(
        "VehicleAssignment",
        ["AssignmentID", "VIN", "DriverID", "DepotID", "IssueDate", "StartDate", "EndDate", "AssignmentStatus"],
        rows,
    )

    state["vehicle_live_state"] = vehicle_live_state  # VIN -> 'in_operation' | 'pending', for stage 07 coordination
    state["driver_busy"] = driver_busy
    state["assignment_count"] = len(rows)
    state["assignment_rows"] = rows  # full rows, for stage 08's driver->vehicle-at-timestamp lookup

    return sql, state
