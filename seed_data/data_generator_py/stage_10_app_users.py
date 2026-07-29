"""
Stage 10 -- AppUser (schema.sql section 7A: "Application Tables (For the
Web Dashboard Login)").

Role itself needs no seed data here -- schema.sql already seeds all 6 rows
directly (see the INSERT right after the AppUser CREATE TABLE). This stage
only covers AppUser, which had no seed data anywhere before this.

One AppUser row per Driver, per Mechanic, and per SafetyStaff -- each with
exactly one of DriverID/MechanicID/ReviewStaffID populated, matching
CHK_AppUser_FK_Consistency. Fleet Manager / Workshop Manager / Admin rows
have no operational entity to link to (all three FK columns NULL, the
"Allows Managers & Admin" branch of that same CHECK) -- their counts are a
generator decision (config.N_FLEET_MANAGERS etc.), not derived from an
existing table, so they're deliberately kept small and depot-anchored
rather than scaled with the rest of the fleet.

No trigger in any of the 5 trigger files touches Role or AppUser (checked
directly), so there's no AUTO_INCREMENT collision risk here the way there
was with ScheduledService/CoachingRecord -- explicit sequential UserID
values are safe.

PASSWORD NOTE: every account shares the same placeholder password ("1234",
matching the example credentials already sketched in TeamProposedTasks.md)
so the whole team can actually log into any seeded account during dashboard
development/testing. This is fine for seed/dev data -- obviously not a
real security practice, and worth calling out as such if this ever needs
to be explained in documentation.
"""

import hashlib
from utils import SqlFile
import config

_DEV_PASSWORD = "1234"
_PASSWORD_HASH = "sha256:" + hashlib.sha256(_DEV_PASSWORD.encode()).hexdigest()


def generate(core_state, ref_state):
    sql = SqlFile(
        "10 - APPLICATION USERS (schema.sql section 7A)",
        "AppUser -- one login per Driver/Mechanic/SafetyStaff, plus a "
        "depot-anchored handful of Fleet Manager/Workshop Manager accounts "
        "and a small fixed Admin count. Role itself is already seeded "
        "directly in schema.sql, not covered here.",
    )
    state = {}

    rows = []
    user_id = 1

    def add_user(username, role_id, driver_id=None, mechanic_id=None, review_staff_id=None):
        nonlocal user_id
        rows.append({
            "UserID": user_id, "Username": username, "PasswordHash": _PASSWORD_HASH,
            "RoleID": role_id, "DriverID": driver_id, "MechanicID": mechanic_id,
            "ReviewStaffID": review_staff_id,
        })
        user_id += 1

    # ---------- Driver ----------
    for d in core_state["drivers"]:
        add_user(f"Driver{d['DriverID'].replace('-', '')}", config.ROLES_BY_NAME["Driver"],
                  driver_id=d["DriverID"])

    # ---------- Mechanic ----------
    for m in core_state["mechanics"]:
        add_user(f"Mechanic{m['MechanicID'].replace('-', '')}", config.ROLES_BY_NAME["Mechanic"],
                  mechanic_id=m["MechanicID"])

    # ---------- Safety Staff ----------
    for staff_id in ref_state["safety_staff_ids"]:
        add_user(f"SafetyStaff{staff_id:04d}", config.ROLES_BY_NAME["Safety Staff"],
                  review_staff_id=staff_id)

    # ---------- Fleet Manager (no linked entity) ----------
    for i in range(1, config.N_FLEET_MANAGERS + 1):
        add_user(f"FleetManager{i:03d}", config.ROLES_BY_NAME["Fleet Manager"])

    # ---------- Workshop Manager (no linked entity) ----------
    for i in range(1, config.N_WORKSHOP_MANAGERS + 1):
        add_user(f"WorkshopManager{i:03d}", config.ROLES_BY_NAME["Workshop Manager"])

    # ---------- Admin (no linked entity) ----------
    for i in range(1, config.N_ADMINS + 1):
        add_user(f"Admin{i:03d}", config.ROLES_BY_NAME["Admin"])

    sql.comment(f"AppUser -- {len(rows)} rows "
                f"({len(core_state['drivers'])} Driver, {len(core_state['mechanics'])} Mechanic, "
                f"{len(ref_state['safety_staff_ids'])} Safety Staff, {config.N_FLEET_MANAGERS} Fleet Manager, "
                f"{config.N_WORKSHOP_MANAGERS} Workshop Manager, {config.N_ADMINS} Admin). "
                f"Every account shares the same dev password ('{_DEV_PASSWORD}') for testing convenience.")
    sql.insert(
        "AppUser",
        ["UserID", "Username", "PasswordHash", "RoleID", "DriverID", "MechanicID", "ReviewStaffID"],
        rows,
    )

    state["app_user_count"] = len(rows)
    return sql, state
