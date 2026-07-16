"""
Stage 06 -- PredictiveAlert, ScheduledService.

IMPORTANT DESIGN NOTE: sp_AutoScheduleFromAlert (fired by
TRG_PredictiveAlert_AfterInsert/AfterUpdate when a row lands on 'Scheduled
For Inspection' or 'Urgent Repair Standby') hardcodes
ScheduledService.ScheduledDate = CURDATE() -- the real wall-clock date when
this generated SQL is actually executed, not the alert's historical
DateGenerated. Routing a historical escalated alert through that trigger
would desync its ScheduledService from the rest of its own history.

So: only a handful of alerts meant to be genuinely live "as of today" are
inserted at an escalated status, letting the real trigger fire (CURDATE()
being "now" is correct for those). Every other alert that led to real
maintenance work is inserted at 'Resolved' directly (skips the trigger,
since Resolved isn't in its IN-list), with its ScheduledService row
inserted manually alongside it -- fully historical dates under our control,
left at Status='Scheduled' so stage 07's MaintenanceJob can close it for
real (exercising the fixed TRG_MaintenanceJob_AfterInsert back-write) rather
than being pre-marked Completed by this stage.

Standalone preventive ScheduledService rows (no alert behind them) are
generated the same way -- inserted directly, no trigger involvement at all
since there's no INSERT trigger on ScheduledService itself.
"""

from datetime import datetime, time, timedelta
from utils import SqlFile
import config


def generate(rng, core_state):
    sql = SqlFile(
        "06 - PREDICTIVE ALERTS & SCHEDULED SERVICES",
        "PredictiveAlert history plus both alert-linked and standalone "
        "ScheduledService rows. Historical escalations are inserted "
        "Resolved-with-manual-schedule to avoid sp_AutoScheduleFromAlert's "
        "CURDATE()-based ScheduledDate; only a few live-today alerts go "
        "through the real trigger.",
    )
    state = {}

    window_start_dt = datetime.combine(config.WINDOW_START, time(6, 0))
    today_dt = datetime.combine(config.TODAY, time(9, 0))
    vins = core_state["vins"]

    alert_rows = []
    alert_id = 1
    schedule_rows = []
    schedule_id = 1
    linked_open_schedules = []  # for stage 07 to close via a real MaintenanceJob

    n_alerts = int(len(vins) * 1.5)
    for _ in range(n_alerts):
        vin = rng.choice(vins)
        alert_type_id = rng.choice(list(config.ALERT_TYPES.keys()))
        gen_dt = window_start_dt + timedelta(
            seconds=rng.randint(0, int((today_dt - timedelta(days=5) - window_start_dt).total_seconds()))
        )

        bucket = rng.random()
        if bucket < 0.55:
            # Resolved historically, no maintenance action taken (false
            # positive / monitored and cleared).
            resolution_dt = gen_dt + timedelta(days=rng.randint(1, 20))
            resolution_dt = min(resolution_dt, today_dt - timedelta(days=1))
            if resolution_dt <= gen_dt:
                resolution_dt = gen_dt + timedelta(hours=6)
            alert_rows.append({
                "AlertID": alert_id, "VIN": vin, "AlertTypeID": alert_type_id,
                "DateGenerated": gen_dt, "ActionTaken": "Monitored; no corrective action required.",
                "AlertStatus": "Resolved", "ResolutionDate": resolution_dt,
            })
            alert_id += 1

        elif bucket < 0.80:
            # Resolved historically, WITH a real maintenance action --
            # manually create the linked ScheduledService (still open,
            # Status='Scheduled') for stage 07 to close via a real job.
            sched_dt = gen_dt + timedelta(days=rng.randint(1, 5))
            resolution_dt = sched_dt + timedelta(days=rng.randint(1, 10))
            resolution_dt = min(resolution_dt, today_dt - timedelta(days=1))
            if resolution_dt <= gen_dt:
                resolution_dt = gen_dt + timedelta(hours=12)

            alert_rows.append({
                "AlertID": alert_id, "VIN": vin, "AlertTypeID": alert_type_id,
                "DateGenerated": gen_dt,
                "ActionTaken": "Escalated for inspection; corrective maintenance performed.",
                "AlertStatus": "Resolved", "ResolutionDate": resolution_dt,
            })
            this_alert_id = alert_id
            alert_id += 1

            schedule_rows.append({
                "ScheduleID": schedule_id, "VIN": vin, "ScheduledDate": sched_dt.date(),
                "Reason": f"Auto-flagged by PredictiveAlert #{this_alert_id} ({config.ALERT_TYPES[alert_type_id]})",
                "AlertID": this_alert_id, "CompletionDate": None, "Status": "Scheduled",
            })
            linked_open_schedules.append({"VIN": vin, "ScheduleID": schedule_id, "approx_date": sched_dt, "AlertID": this_alert_id})
            schedule_id += 1

        elif bucket < 0.92:
            # Still open as of today -- Unresolved or Acknowledged, nothing
            # escalated yet. Recent-ish DateGenerated.
            status = rng.choice(["Unresolved", "Acknowledged"])
            gen_dt_recent = today_dt - timedelta(days=rng.randint(1, 14))
            alert_rows.append({
                "AlertID": alert_id, "VIN": vin, "AlertTypeID": alert_type_id,
                "DateGenerated": gen_dt_recent,
                "ActionTaken": "Acknowledged, pending review." if status == "Acknowledged" else None,
                "AlertStatus": status, "ResolutionDate": None,
            })
            alert_id += 1

        else:
            # Genuinely live escalation as of today -- lets the real
            # trigger fire and auto-create its ScheduledService.
            status = rng.choice(["Scheduled For Inspection", "Urgent Repair Standby"])
            gen_dt_recent = today_dt - timedelta(days=rng.randint(0, 3))
            alert_rows.append({
                "AlertID": alert_id, "VIN": vin, "AlertTypeID": alert_type_id,
                "DateGenerated": gen_dt_recent,
                "ActionTaken": "Escalated -- awaiting workshop slot.",
                "AlertStatus": status, "ResolutionDate": None,
            })
            alert_id += 1
            # NOTE: no manual ScheduledService row here -- TRG_PredictiveAlert_AfterInsert
            # calls sp_AutoScheduleFromAlert for real when this INSERT runs.

    sql.comment(f"PredictiveAlert -- {len(alert_rows)} rows "
                f"({sum(1 for r in alert_rows if r['AlertStatus'] in ('Scheduled For Inspection', 'Urgent Repair Standby'))} "
                f"live escalations that will fire sp_AutoScheduleFromAlert for real)")
    sql.insert(
        "PredictiveAlert",
        ["AlertID", "VIN", "AlertTypeID", "DateGenerated", "ActionTaken", "AlertStatus", "ResolutionDate"],
        alert_rows,
    )

    # ---------- Standalone preventive ScheduledService (no alert) ----------
    n_standalone = max(10, len(vins) // 4)
    for _ in range(n_standalone):
        vin = rng.choice(vins)
        r = rng.random()
        if r < 0.5:
            # Historical, due-and-done -- left open here, closed by stage 07.
            sched_dt = window_start_dt + timedelta(days=rng.randint(10, 150))
            schedule_rows.append({
                "ScheduleID": schedule_id, "VIN": vin, "ScheduledDate": sched_dt.date(),
                "Reason": "Routine preventative maintenance interval.",
                "AlertID": None, "CompletionDate": None, "Status": "Scheduled",
            })
            linked_open_schedules.append({"VIN": vin, "ScheduleID": schedule_id, "approx_date": sched_dt, "AlertID": None})
            schedule_id += 1
        elif r < 0.85:
            # Upcoming -- due after today, stays open, not linked to any job.
            sched_dt = config.TODAY + timedelta(days=rng.randint(3, 45))
            schedule_rows.append({
                "ScheduleID": schedule_id, "VIN": vin, "ScheduledDate": sched_dt,
                "Reason": "Routine preventative maintenance interval.",
                "AlertID": None, "CompletionDate": None, "Status": "Scheduled",
            })
            schedule_id += 1
        else:
            # Cancelled historical booking.
            sched_dt = window_start_dt + timedelta(days=rng.randint(10, 150))
            schedule_rows.append({
                "ScheduleID": schedule_id, "VIN": vin, "ScheduledDate": sched_dt.date(),
                "Reason": "Routine preventative maintenance interval.",
                "AlertID": None, "CompletionDate": None, "Status": "Cancelled",
            })
            schedule_id += 1

    sql.comment(f"\nScheduledService -- {len(schedule_rows)} rows "
                f"({len(linked_open_schedules)} left open for stage 07 to close via a real MaintenanceJob)")
    sql.insert(
        "ScheduledService",
        ["ScheduleID", "VIN", "ScheduledDate", "Reason", "AlertID", "CompletionDate", "Status"],
        schedule_rows,
    )

    state["linked_open_schedules"] = linked_open_schedules
    state["alert_count"] = len(alert_rows)
    state["schedule_count"] = len(schedule_rows)
    return sql, state
