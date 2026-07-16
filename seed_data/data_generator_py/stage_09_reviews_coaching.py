"""
Stage 09 -- EventReview progression, manual CoachingRecord.

EventReview rows for every High/Critical SafetyEvent (Low/Medium never get
reviewed -- ReviewState stays 'No Review Required', untouched). All rows
insert at 'Unread' in one bulk statement (the BeforeInsert guard only
forbids inserting already-Closed, so Unread is always safe), then progress
through sequential UPDATE statements -- Read, then Commented and/or Closed --
respecting TRG_EventReview_BeforeUpdate's "must be Read before Closed, and
Closed is terminal" rules. A closed review on a Critical event's chain
triggers sp_RecomputeDriverEligibility for real via TRG_EventReview_AfterUpdate.

Progression likelihood is age-weighted: older events are more likely to be
fully Closed by "today"; recent ones are more likely still Assigned or not
yet reviewed at all (left at the SafetyEvent's own 'Pending' ReviewState,
no EventReview row).

Single reviewer per event chain, for simplicity -- fn_EventReviewState's
AND-semantics (every reviewer must Close for 'Completed') is exercised by
the CoachingRecord/eligibility interaction instead, not by multi-reviewer
races here.

Manual CoachingRecord rows cover the two types the DriverScorePenalty
cascade in stage 08 never touches: 'Licence Review' (never automated at
all) and a few 'Retraining' rows enrolled directly by staff (not from the
score cascade) -- inserting one demonstrates TRG_CoachingRecord_AfterInsert
suspending the driver for a reason unrelated to their score, and a
follow-up UPDATE to Passed/Failed demonstrates the AfterUpdate clear-path.
"""

from datetime import timedelta
from utils import SqlFile, sql_str
import config


def generate(rng, core_state, ref_state, event_state):
    sql = SqlFile(
        "09 - EVENT REVIEW & COACHING PROGRESSION",
        "EventReview rows for every High/Critical SafetyEvent, progressed "
        "via sequential UPDATEs respecting the close-guard. Plus a handful "
        "of manually-enrolled CoachingRecord rows outside the automatic cascade.",
    )
    state = {}

    staff_ids = ref_state["safety_staff_ids"]
    today_dt_date = config.TODAY

    review_id = 1
    insert_rows = []   # all start Unread
    update_stmts = []  # (ReviewID, ordered list of UPDATE dicts)

    reviewed_count = 0
    closed_count = 0

    for ev in event_state["high_critical_events"]:
        event_date = ev["EventTimestamp"].date()
        age_days = (today_dt_date - event_date).days

        if age_days >= 45:
            bucket_weights = {"closed": 75, "in_review": 15, "assigned": 10, "pending": 0}
        elif age_days >= 15:
            bucket_weights = {"closed": 30, "in_review": 35, "assigned": 35, "pending": 0}
        else:
            bucket_weights = {"closed": 5, "in_review": 20, "assigned": 40, "pending": 35}

        bucket = rng.choices(list(bucket_weights.keys()), weights=list(bucket_weights.values()), k=1)[0]
        if bucket == "pending":
            continue  # no EventReview row at all -- SafetyEvent stays at its forced 'Pending'

        reviewer = rng.choice(staff_ids)
        rid = review_id
        review_id += 1
        insert_rows.append({
            "ReviewID": rid, "EventID": ev["EventID"], "ReviewerStaffID": reviewer,
            "Comments": None, "Recommendations": None, "Status": "Unread", "DateReviewed": None,
        })
        reviewed_count += 1

        read_dt = ev["EventTimestamp"] + timedelta(days=rng.randint(1, 5), hours=rng.randint(0, 12))
        steps = [("Read", read_dt, None, None)]

        if bucket in ("in_review", "closed"):
            if rng.random() < 0.6:
                comment_dt = read_dt + timedelta(days=rng.randint(0, 3))
                steps.append(("Commented", comment_dt,
                              rng.choice([
                                  "Reviewed telemetry; driver coaching recommended.",
                                  "Consistent with prior pattern; escalate to retraining track.",
                                  "Isolated incident; no further action beyond standard coaching.",
                              ]),
                              "Recommend standard safety coaching follow-up."))

        if bucket == "closed":
            close_dt = steps[-1][1] + timedelta(days=rng.randint(1, 6))
            steps.append(("Closed", close_dt, None, None))
            closed_count += 1

        update_stmts.append((rid, steps))

    sql.comment(f"EventReview -- {reviewed_count} review chains started "
                f"({closed_count} fully Closed, rest Assigned/In Review) "
                f"out of {len(event_state['high_critical_events'])} High/Critical events")
    sql.insert(
        "EventReview",
        ["ReviewID", "EventID", "ReviewerStaffID", "Comments", "Recommendations", "Status", "DateReviewed"],
        insert_rows,
    )

    sql.comment("\nProgress each review sequentially -- Read, then optionally "
                "Commented, then optionally Closed. One UPDATE per step, since "
                "TRG_EventReview_BeforeUpdate enforces the ordering.")
    for rid, steps in update_stmts:
        for status, dt, comments, recommendations in steps:
            set_parts = [f"Status = {sql_str(status)}", f"DateReviewed = {sql_str(dt)}"]
            if comments is not None:
                set_parts.append(f"Comments = {sql_str(comments)}")
            if recommendations is not None:
                set_parts.append(f"Recommendations = {sql_str(recommendations)}")
            sql.update("EventReview", ", ".join(set_parts), f"ReviewID = {rid}")

    # ---------- Manual CoachingRecord ----------
    active_driver_ids = [d["DriverID"] for d in core_state["drivers"] if d["EmploymentStatus"] == "Active"]
    coaching_rows = []
    coaching_id = 1
    coaching_updates = []

    # A few Licence Review records -- never automated, purely staff-initiated.
    for _ in range(6):
        did = rng.choice(active_driver_ids)
        c_date = config.WINDOW_START + timedelta(days=rng.randint(0, (config.TODAY - config.WINDOW_START).days - 10))
        resolved = rng.random() < 0.7
        if resolved:
            completion = c_date + timedelta(days=rng.randint(3, 21))
            outcome = rng.choice(["Passed", "Failed"])
        else:
            completion, outcome = None, rng.choice(["Pending", "In Progress"])
        coaching_rows.append({
            "CoachingRecordID": coaching_id, "DriverID": did, "CoachingType": "Licence Review",
            "CoachingDate": c_date, "CompletionDate": completion, "Outcome": outcome,
        })
        coaching_id += 1

    # A few Retraining enrolments made directly by staff, outside the
    # DriverScorePenalty cascade -- exercises TRG_CoachingRecord_AfterInsert's
    # eligibility suspension for a non-score reason.
    manual_retraining_ids = rng.sample(active_driver_ids, k=min(4, len(active_driver_ids)))
    for did in manual_retraining_ids:
        c_date = config.TODAY - timedelta(days=rng.randint(5, 60))
        this_id = coaching_id
        coaching_rows.append({
            "CoachingRecordID": this_id, "DriverID": did, "CoachingType": "Retraining",
            "CoachingDate": c_date, "CompletionDate": None, "Outcome": "Pending",
        })
        coaching_id += 1
        # Resolve about half of them via a follow-up UPDATE, demonstrating
        # TRG_CoachingRecord_AfterUpdate's eligibility re-clear on Retraining
        # outcome change.
        if rng.random() < 0.5:
            completion = c_date + timedelta(days=rng.randint(10, 40))
            outcome = rng.choice(["Passed", "Failed"])
            coaching_updates.append((this_id, completion, outcome))

    sql.comment(f"\nCoachingRecord -- {len(coaching_rows)} manually-enrolled rows "
                "(Licence Review, plus Retraining enrolled directly by staff "
                "outside the DriverScorePenalty cascade)")
    sql.insert(
        "CoachingRecord",
        ["CoachingRecordID", "DriverID", "CoachingType", "CoachingDate", "CompletionDate", "Outcome"],
        coaching_rows,
    )

    if coaching_updates:
        sql.comment("\nResolve a subset of the manual Retraining enrolments")
        for cid, completion, outcome in coaching_updates:
            sql.update(
                "CoachingRecord",
                f"Outcome = {sql_str(outcome)}, CompletionDate = {sql_str(completion)}",
                f"CoachingRecordID = {cid}",
            )

    state["review_count"] = reviewed_count
    state["closed_review_count"] = closed_count
    state["coaching_record_count"] = len(coaching_rows)
    return sql, state
