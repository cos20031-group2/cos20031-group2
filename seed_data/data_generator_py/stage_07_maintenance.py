"""
Stage 07 -- MaintenanceJob, MaintenanceActivity, MechanicWorkSession,
ActivityPart, WarrantyClaim.

Job placement:
1. One job per entry in stage 06's linked_open_schedules -- closes the real
   ScheduledService (via the fixed TRG_MaintenanceJob_AfterInsert back-write)
   and, where an alert is behind it, tags the first MaintenanceActivity with
   LinkedAlertID for traceability.
2. Extra standalone jobs (no schedule) top each vehicle up to a small target
   job count, placed in non-overlapping historical windows per VIN.
3. A few vehicles get a currently-OPEN job (DateClosed IS NULL) as of today
   -- deliberately including one of stage 05's 'in_operation' vehicles, to
   exercise the documented "emergency repair on an In Operation vehicle"
   scenario from the trigger file's own comments (Tier 1 of
   fn_NextVehicleStatus overriding Tier 2 until the job closes).

Per the earlier decision, TotalCost is a plausible randomized figure
independent of the actual ActivityPart sum (labour isn't modeled -- that's
left for the company to calculate). Downtime is derived from the job's own
open/close window for internal consistency.

Part stock is tracked locally (starting from stage 01's seeded
CurrentStock) and decremented as ActivityPart rows are generated, mirroring
what TRG_ActivityPart_AfterInsert will really do -- so we never generate a
quantity that would violate the stock gate when this SQL actually runs.
"""

from collections import defaultdict
from datetime import datetime, time, timedelta
from utils import SqlFile, gen_job_id
import config

DIAG_TEXTS = [
    "Visual and diagnostic inspection completed; findings addressed.",
    "Fault confirmed via diagnostic scan; component serviced.",
    "Routine wear-and-tear identified during scheduled check.",
    "Customer-reported issue reproduced and resolved.",
    "Preventative service performed per manufacturer interval.",
    "Follow-up inspection following prior repair.",
]


def _pick_mechanic(activity_type_id, workshop_id, mechanics_by_workshop, mechanic_active_ids,
                    mechanic_cert_holdings, all_mechanic_ids, rng):
    required_cert = config.ACTIVITY_TYPES[activity_type_id][1]
    candidates = [
        m for m in mechanics_by_workshop.get(workshop_id, [])
        if m in mechanic_active_ids and required_cert in mechanic_cert_holdings.get(m, set())
    ]
    if not candidates:
        candidates = [
            m for m in all_mechanic_ids
            if m in mechanic_active_ids and required_cert in mechanic_cert_holdings.get(m, set())
        ]
    return rng.choice(candidates) if candidates else None


def generate(rng, core_state, cert_state, assign_state, alert_state, ref_state):
    sql = SqlFile(
        "07 - MAINTENANCE OPERATIONS",
        "MaintenanceJob, MaintenanceActivity, MechanicWorkSession, ActivityPart, "
        "WarrantyClaim. Schedule-linked jobs close their ScheduledService for "
        "real; a few vehicles get a genuinely open job as of today.",
    )
    state = {}

    vehicles_by_vin = {v["VIN"]: v for v in core_state["vehicles"]}
    workshop_by_depot = core_state["workshop_by_depot"]
    mechanic_active_ids = {m["MechanicID"] for m in core_state["mechanics"] if m["EmploymentStatus"] == "Active"}
    mechanic_cert_holdings = cert_state["mechanic_cert_holdings"]
    mechanics_by_workshop = defaultdict(list)
    for m in core_state["mechanics"]:
        mechanics_by_workshop[m["WorkshopID"]].append(m["MechanicID"])

    part_stock = dict(ref_state["part_stock"])
    part_numbers = ref_state["part_numbers"]

    window_start_dt = datetime.combine(config.WINDOW_START, time(6, 0))
    today_dt = datetime.combine(config.TODAY, time(9, 0))
    FAR_FUTURE = today_dt + timedelta(days=3650)

    job_rows, activity_rows, session_rows, activitypart_rows, warranty_rows = [], [], [], [], []
    job_counter = 1
    activity_id = 1
    session_id = 1
    claim_id = 1

    vin_busy = {vin: [] for vin in core_state["vins"]}

    schedules_by_vin = defaultdict(list)
    for item in alert_state["linked_open_schedules"]:
        schedules_by_vin[item["VIN"]].append(item)

    live_state = assign_state["vehicle_live_state"]
    in_op_vins = [vin for vin, s in live_state.items() if s == "in_operation"]
    other_vins = [vin for vin in core_state["vins"] if live_state.get(vin) is None]
    rng.shuffle(in_op_vins)
    rng.shuffle(other_vins)
    open_job_vins = set()
    if in_op_vins:
        open_job_vins.add(in_op_vins[0])  # deliberate "emergency repair while In Operation" case
    open_job_vins.update(other_vins[:2])

    def add_job(vin, date_opened, date_closed, schedule_id=None):
        nonlocal job_counter
        jid = gen_job_id(job_counter)
        job_counter += 1
        depot_id = vehicles_by_vin[vin]["DepotID"]
        workshop_id = workshop_by_depot[depot_id]
        if date_closed is not None:
            downtime_hours = round((date_closed - date_opened).total_seconds() / 3600, 4)
            total_cost = rng.randint(300_000, 45_000_000)
        else:
            downtime_hours = round((today_dt - date_opened).total_seconds() / 3600, 4)
            total_cost = None
        job_rows.append({
            "JobID": jid, "VIN": vin, "WorkshopID": workshop_id, "ScheduleID": schedule_id,
            "DateOpened": date_opened, "DateClosed": date_closed,
            "Downtime": downtime_hours, "TotalCost": total_cost,
        })
        return jid, workshop_id

    def add_activities_for_job(jid, vin, workshop_id, date_opened, date_closed, linked_alert_id=None):
        nonlocal activity_id, session_id, claim_id
        cat_id = vehicles_by_vin[vin]["CategoryID"]
        possible_types = config.CATEGORY_ACTIVITY_TYPES[cat_id]
        n_acts = rng.randint(1, min(3, len(possible_types)))
        types_chosen = rng.sample(possible_types, k=n_acts)

        for idx, at_id in enumerate(types_chosen):
            repeated = rng.random() < 0.10
            warranty = rng.random() < 0.20
            activity_rows.append({
                "ActivityID": activity_id, "JobID": jid, "ActivityTypeID": at_id,
                "DiagnosticResult": rng.choice(DIAG_TEXTS),
                "RepeatedFaultFlag": repeated, "WarrantyFlag": warranty,
                "LinkedAlertID": linked_alert_id if idx == 0 else None,
            })
            this_activity_id = activity_id
            activity_id += 1

            mech = _pick_mechanic(at_id, workshop_id, mechanics_by_workshop, mechanic_active_ids,
                                   mechanic_cert_holdings, core_state["mechanic_ids"], rng)
            if mech is not None:
                s_start = date_opened + timedelta(hours=rng.randint(1, 6))
                if date_closed is not None:
                    s_end = min(s_start + timedelta(hours=rng.randint(1, 8)), date_closed)
                    if s_end < s_start:
                        s_end = s_start
                else:
                    if rng.random() < 0.5:
                        s_end = None
                    else:
                        s_end = min(s_start + timedelta(hours=rng.randint(1, 6)), today_dt)
                        if s_end < s_start:
                            s_end = s_start
                session_rows.append({
                    "SessionID": session_id, "MechanicID": mech, "ActivityID": this_activity_id,
                    "StartTime": s_start, "EndTime": s_end,
                })
                session_id += 1

            this_claim_id = None
            if warranty and rng.random() < 0.6:
                claim_date = date_opened + timedelta(days=rng.randint(0, 3))
                if date_closed is not None and rng.random() < 0.8:
                    resolution = claim_date + timedelta(days=rng.randint(2, 20))
                    status = rng.choice(["Approved", "Rejected", "Settled"])
                else:
                    resolution, status = None, "Pending"
                warranty_rows.append({
                    "ClaimID": claim_id, "ActivityID": this_activity_id,
                    "ClaimSource": rng.choice(["Vehicle Manufacturer", "Parts Supplier", "Internal Claim"]),
                    "ClaimDate": claim_date, "Status": status, "ResolutionDate": resolution,
                })
                this_claim_id = claim_id
                claim_id += 1

            n_parts = rng.choice([0, 1, 1, 2])
            chosen_parts = rng.sample(part_numbers, k=min(n_parts, len(part_numbers))) if n_parts else []
            for pn in chosen_parts:
                avail = part_stock.get(pn, 0)
                if avail <= 0:
                    continue
                qty = min(rng.randint(1, 3), avail)
                activitypart_rows.append({
                    "ActivityID": this_activity_id, "PartNumber": pn,
                    "ClaimID": this_claim_id if (this_claim_id and rng.random() < 0.5) else None,
                    "QuantityUsed": qty, "UnitCost": rng.randint(40_000, 8_000_000),
                })
                part_stock[pn] = avail - qty

    # ---------- 1. Schedule-linked jobs ----------
    for vin, items in schedules_by_vin.items():
        for item in items:
            date_opened = item["approx_date"]
            date_closed = date_opened + timedelta(days=rng.randint(1, 5), hours=rng.randint(0, 12))
            if date_closed >= today_dt - timedelta(days=1):
                date_closed = today_dt - timedelta(days=1)
                if date_closed <= date_opened:
                    date_closed = date_opened + timedelta(hours=6)

            jid, workshop_id = add_job(vin, date_opened, date_closed, schedule_id=item["ScheduleID"])
            vin_busy[vin].append((date_opened, date_closed))
            add_activities_for_job(jid, vin, workshop_id, date_opened, date_closed,
                                    linked_alert_id=item.get("AlertID"))

    # ---------- 2. Standalone jobs (top up each vehicle to a small target) ----------
    for vin in core_state["vins"]:
        existing = len(schedules_by_vin.get(vin, []))
        target = min(3, max(existing, rng.choice([1, 1, 2])))
        for _ in range(target - existing):
            placed = False
            date_opened = date_closed = None
            for _attempt in range(8):
                span_days = max(1, (today_dt - window_start_dt).days - 10)
                date_opened = window_start_dt + timedelta(days=rng.randint(0, span_days), hours=rng.randint(0, 23))
                date_closed = date_opened + timedelta(days=rng.randint(1, 6), hours=rng.randint(0, 12))
                if date_closed >= today_dt - timedelta(days=2):
                    continue
                if not any(a < date_closed and date_opened < b for a, b in vin_busy[vin]):
                    placed = True
                    break
            if not placed:
                continue
            jid, workshop_id = add_job(vin, date_opened, date_closed)
            vin_busy[vin].append((date_opened, date_closed))
            add_activities_for_job(jid, vin, workshop_id, date_opened, date_closed)

    # ---------- 3. Currently-open jobs as of today ----------
    for vin in sorted(open_job_vins):
        date_opened = today_dt - timedelta(hours=rng.randint(4, 48))
        if any(date_opened < b for _a, b in vin_busy[vin]):
            continue  # would collide with an already-placed job's tail end
        jid, workshop_id = add_job(vin, date_opened, None)
        vin_busy[vin].append((date_opened, FAR_FUTURE))
        add_activities_for_job(jid, vin, workshop_id, date_opened, None)

    sql.comment(f"MaintenanceJob -- {len(job_rows)} jobs "
                f"({sum(1 for j in job_rows if j['DateClosed'] is None)} currently open, "
                f"{sum(1 for j in job_rows if j['ScheduleID'] is not None)} schedule-linked)")
    sql.insert(
        "MaintenanceJob",
        ["JobID", "VIN", "WorkshopID", "ScheduleID", "DateOpened", "DateClosed", "Downtime", "TotalCost"],
        job_rows,
    )

    sql.comment(f"\nMaintenanceActivity -- {len(activity_rows)} rows")
    sql.insert(
        "MaintenanceActivity",
        ["ActivityID", "JobID", "ActivityTypeID", "DiagnosticResult",
         "RepeatedFaultFlag", "WarrantyFlag", "LinkedAlertID"],
        activity_rows,
    )

    sql.comment(f"\nMechanicWorkSession -- {len(session_rows)} rows")
    sql.insert(
        "MechanicWorkSession",
        ["SessionID", "MechanicID", "ActivityID", "StartTime", "EndTime"],
        session_rows,
    )

    sql.comment(f"\nWarrantyClaim -- {len(warranty_rows)} rows")
    sql.insert(
        "WarrantyClaim",
        ["ClaimID", "ActivityID", "ClaimSource", "ClaimDate", "Status", "ResolutionDate"],
        warranty_rows,
    )

    sql.comment(f"\nActivityPart -- {len(activitypart_rows)} rows (stock tracked locally, never oversold)")
    sql.insert(
        "ActivityPart",
        ["ActivityID", "PartNumber", "ClaimID", "QuantityUsed", "UnitCost"],
        activitypart_rows,
    )

    state["job_count"] = len(job_rows)
    state["open_job_vins"] = open_job_vins
    state["final_part_stock"] = part_stock
    return sql, state
