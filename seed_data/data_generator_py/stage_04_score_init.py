"""
Stage 04 -- Monthly score initialization.

Just CALL sp_InitializeMonthlyScores(month, year) for every calendar month
touched by the 6-month window (7 calls, since the window starts/ends
mid-month -- see config.MONTHS_COVERED). Must run before any SafetyEvent
insert, since sp_EvaluatePenaltiesForEvent hard-requires a
DriverMonthlySafetyScore row to exist for the event's driver/month.
"""

from utils import SqlFile
import config


def generate():
    sql = SqlFile(
        "04 - MONTHLY SCORE INITIALIZATION",
        "Calls sp_InitializeMonthlyScores for every calendar month touched by "
        "the 6-month window, so DriverMonthlySafetyScore rows exist before any "
        "SafetyEvent is inserted in stage 08.",
    )
    for month, year in config.MONTHS_COVERED:
        sql.call("sp_InitializeMonthlyScores", [str(month), str(year)])
    return sql, {}
