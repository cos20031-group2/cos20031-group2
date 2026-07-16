"""
Stage 08 -- SafetyEvent.

Everything downstream (DriverScorePenalty, CoachingRecord creation at the
75/50 score thresholds, DrivingEligibility suspension for Critical events)
is fully automatic via the triggers in driver_eligibility_and_safety_event_
triggers.sql and review_coaching_and_scoring_triggers.sql -- this stage only
inserts SafetyEvent rows, nothing else, per the earlier correction that both
Base and Conditional PenaltyRules fire off SafetyEvent inserts alone.

Only drivers currently EmploymentStatus != 'Terminated' are used.
sp_InitializeMonthlyScores (stage 04) only created DriverMonthlySafetyScore
rows for non-Terminated drivers with a CurrentDepotID -- and
sp_EvaluatePenaltiesForEvent hard-SIGNALs if no score row exists for the
event's driver/month. Since EmploymentStatus has no history in this schema,
excluding currently-Terminated drivers entirely is the only fully safe
option (rather than trying to guess whether they were still Active back
when a historical event would have occurred).

VIN/DepotID are derived from the driver's actual VehicleAssignment history
where a Completed/In Operation assignment covers the event's timestamp
(cross-referencing stage 05's assignment_rows), falling back to a random
vehicle from the driver's home depot when no covering assignment exists
(e.g. the event happens in a gap between bookings).

Rows are sorted chronologically before being written, so the Conditional
PenaltyRule's "the Nth event this month" naturally lands on the
chronologically-last qualifying event within the month, not an arbitrary
row-order artifact.
"""

from collections import defaultdict
from datetime import date, datetime, time, timedelta
from utils import SqlFile, gen_event_id
import config


def _month_bounds(month, year):
    first = date(year, month, 1)
    nxt = date(year + 1, 1, 1) if month == 12 else date(year, month + 1, 1)
    last = nxt - timedelta(days=1)
    start = max(first, config.WINDOW_START)
    end = min(last, config.TODAY)
    return start, end


def _build_driver_intervals(assignment_rows):
    """DriverID -> sorted list of (start_dt, end_dt_or_None, VIN, DepotID) for
    Completed/In Operation assignments (the ones representing real driving time)."""
    by_driver = defaultdict(list)
    for r in assignment_rows:
        if r["AssignmentStatus"] not in ("Completed", "In Operation"):
            continue
        if r["StartDate"] is None:
            continue
        by_driver[r["DriverID"]].append((r["StartDate"], r["EndDate"], r["VIN"], r["DepotID"]))
    for did in by_driver:
        by_driver[did].sort(key=lambda t: t[0])
    return by_driver


def _find_vehicle(driver_id, ts, driver_intervals, vehicles_by_depot, driver_depot, rng):
    for start, end, vin, depot in driver_intervals.get(driver_id, []):
        if start <= ts and (end is None or ts <= end):
            return vin, depot
    pool = vehicles_by_depot.get(driver_depot) or []
    if pool:
        v = rng.choice(pool)
        return v["VIN"], v["DepotID"]
    return None, None


def generate(rng, core_state, assign_state):
    sql = SqlFile(
        "08 - SAFETY EVENTS",
        "SafetyEvent only -- DriverScorePenalty, CoachingRecord, and "
        "DrivingEligibility all cascade automatically via triggers. Rows "
        "sorted chronologically so Conditional PenaltyRule thresholds land "
        "on the realistic Nth event of the month.",
    )
    state = {}

    eligible_drivers = [d for d in core_state["drivers"] if d["EmploymentStatus"] != "Terminated"]
    driver_intervals = _build_driver_intervals(assign_state["assignment_rows"])
    vehicles_by_depot = defaultdict(list)
    for v in core_state["vehicles"]:
        vehicles_by_depot[v["DepotID"]].append(v)
    vehicle_base_odometer = {v["VIN"]: v["Odometer"] for v in core_state["vehicles"]}

    severity_ids = list(config.EVENT_SEVERITY.keys())
    severity_weights = [45, 30, 18, 7]  # Low, Medium, High, Critical (matches EVENT_SEVERITY id order)
    event_type_ids = list(config.EVENT_TYPES.keys())

    rows = []
    for month, year in config.MONTHS_COVERED:
        month_start, month_end = _month_bounds(month, year)
        if month_start > month_end:
            continue
        span_days = (month_end - month_start).days

        for driver in eligible_drivers:
            did = driver["DriverID"]
            n_events = rng.choices([0, 1, 2, 3, 4], weights=[10, 30, 30, 20, 10], k=1)[0]
            for _ in range(n_events):
                event_day = month_start + timedelta(days=rng.randint(0, span_days))
                ts = datetime.combine(event_day, time(rng.randint(0, 23), rng.randint(0, 59), rng.randint(0, 59)))
                if ts > datetime.combine(config.TODAY, time(23, 59, 59)):
                    continue

                severity_id = rng.choices(severity_ids, weights=severity_weights, k=1)[0]
                event_type_id = rng.choice(event_type_ids)

                vin, depot_id = _find_vehicle(did, ts, driver_intervals, vehicles_by_depot,
                                               driver["CurrentDepotID"], rng)
                if vin is None:
                    continue  # no vehicles at all in this depot -- skip, shouldn't happen at this scale

                days_before_today = (config.TODAY - ts.date()).days
                daily_km = rng.uniform(15, 45)
                odometer = max(0, vehicle_base_odometer[vin] - int(days_before_today * daily_km) + rng.randint(-100, 100))

                rows.append({
                    "DriverID": did, "VIN": vin, "DepotID": depot_id,
                    "EventTimestamp": ts, "EventTypeID": event_type_id,
                    "SeverityID": severity_id, "Odometer": odometer,
                })

    # ---------- Guarantee the Conditional PenaltyRules actually fire ----------
    # Natural random draws (uniform event type, modest per-driver volume) can
    # easily produce zero driver-months crossing either threshold -- worth
    # demonstrating deliberately rather than leaving it to chance, same
    # reasoning as the certification coverage top-up in stage 03.
    def _inject_burst(event_type_id, min_count, n_driver_months):
        for _ in range(n_driver_months):
            driver = rng.choice(eligible_drivers)
            did = driver["DriverID"]
            month, year = rng.choice(config.MONTHS_COVERED)
            month_start, month_end = _month_bounds(month, year)
            if month_start > month_end:
                continue
            span_days = (month_end - month_start).days
            for _ in range(min_count + 1):  # min_count+1 to actually exceed "> min_count"
                event_day = month_start + timedelta(days=rng.randint(0, span_days))
                ts = datetime.combine(event_day, time(rng.randint(0, 23), rng.randint(0, 59), rng.randint(0, 59)))
                if ts > datetime.combine(config.TODAY, time(23, 59, 59)):
                    ts = datetime.combine(month_end, time(12, 0, 0))
                vin, depot_id = _find_vehicle(did, ts, driver_intervals, vehicles_by_depot,
                                               driver["CurrentDepotID"], rng)
                if vin is None:
                    continue
                days_before_today = (config.TODAY - ts.date()).days
                daily_km = rng.uniform(15, 45)
                odometer = max(0, vehicle_base_odometer[vin] - int(days_before_today * daily_km) + rng.randint(-100, 100))
                rows.append({
                    "DriverID": did, "VIN": vin, "DepotID": depot_id,
                    "EventTimestamp": ts, "EventTypeID": event_type_id,
                    "SeverityID": rng.choices(severity_ids, weights=severity_weights, k=1)[0],
                    "Odometer": odometer,
                })

    _inject_burst(event_type_id=3, min_count=3, n_driver_months=3)  # >3 speeding/month
    _inject_burst(event_type_id=6, min_count=2, n_driver_months=2)  # >2 fatigue warnings/month

    rows.sort(key=lambda r: r["EventTimestamp"])
    for i, r in enumerate(rows, start=1):
        r["EventID"] = gen_event_id(i)

    severity_counts = defaultdict(int)
    for r in rows:
        severity_counts[config.EVENT_SEVERITY[r["SeverityID"]]] += 1

    sql.comment(f"SafetyEvent -- {len(rows)} rows across {len(eligible_drivers)} eligible drivers "
                f"(excludes Terminated). Severity mix: {dict(severity_counts)}. "
                "ReviewState omitted -- column DEFAULT / TRG_SafetyEvent_BeforeInsert handle it correctly "
                "for every severity without an explicit value.")
    sql.insert(
        "SafetyEvent",
        ["EventID", "DriverID", "VIN", "DepotID", "EventTimestamp", "EventTypeID", "SeverityID", "Odometer"],
        rows,
    )

    state["event_count"] = len(rows)
    state["severity_counts"] = dict(severity_counts)
    state["critical_event_driver_ids"] = list({r["DriverID"] for r in rows if config.EVENT_SEVERITY[r["SeverityID"]] == "Critical"})
    state["high_critical_events"] = [
        {"EventID": r["EventID"], "EventTimestamp": r["EventTimestamp"], "DriverID": r["DriverID"],
         "SeverityLevel": config.EVENT_SEVERITY[r["SeverityID"]]}
        for r in rows if config.EVENT_SEVERITY[r["SeverityID"]] in ("High", "Critical")
    ]
    return sql, state
