# Smart Fleet Management System — Team Plan (Draft)

*Most of this is still open for discussion, feel free flag anything you'd change.*

---

## Process (Confluence / Jira)

- [ ] Confluence for task tracking, meeting minutes, and retrospective (required by rubric) + Jira for day-to-day board — using both or just Confluence is probably fine
- [ ] Recurring meetings, with minutes kept live and actions assigned to named people
- [ ] Retrospective doc, probalby updated incrementally as we go rather than written at the end. Depends on how you want to work.
- [ ] Everyone logs their own contributions as they happen.

---

## Database Core

- [ ] Finish `6_business_queries.sql` (the use cases, this is what I'm (Khiem) currently working on)
- [ ] Views / transactions needed for the CRUD dashboards
- [ ] Add `Role` + `User` tables for login/dashboard access — **please decide FK pattern below before touching this**
- [ ] Indexes, once queries are final (ie., 6_business_queries.sql): identify candidate columns from actual query patterns → run `EXPLAIN` + timing before/after on the seed dataset → document a retain/discard decision per index with the measured time improvement

### `Role` / `User` design (proposed)

---

Option A — Nullable FK on User

Role(RoleID, RoleName)
User(UserID, Username, PasswordHash, RoleID FK,
     DriverID FK NULL, MechanicID FK NULL, ReviewStaffID FK NULL)
    

Driver/Mechanic/Safety-Staff-role users: exactly one FK populated, pointing at their existing row.
Manager/Admin-role users: all three FK columns NULL — no operational entity behind them.
CHECK constraint enforces "exactly one FK populated, or none depending on role."

Pro: Driver, Mechanic, SafetyStaff and their existing triggers stay untouched — zero regression risk on code that already works.
Con: three nullable FK columns sitting mostly empty on any given row is a bit of a smell, and doesn't read as "clean" on an ERD.

---

Option B — Person/Employee Supertype

Person(PersonID, FullName, ContactInfo, ...)
Driver(PersonID FK PK, ...driver-specific fields...)
Mechanic(PersonID FK PK, ...mechanic-specific fields...)
SafetyStaff(PersonID FK PK, ...)
Manager(PersonID FK PK, ManagerType ENUM('Fleet','Workshop'))
User(UserID, Username, PasswordHash, RoleID FK, PersonID FK)


Every human in the system is a Person first; Driver/Mechanic/SafetyStaff/Manager become subtype tables sharing that PK.
User needs exactly one FK (PersonID) — no NULL-juggling.

Pro: textbook supertype/subtype modeling — reads well on an ERD, and is the "more correct" answer if this were graded purely on modeling elegance.
Con: means restructuring Driver/Mechanic/SafetyStaff (renaming their PKs to PersonID, re-pointing every existing FK in the trigger files that references DriverID/MechanicID/ReviewStaffID) — real risk to code that already works correctly, for a payoff that's mostly cosmetic at this schema's scale.

---

## Documentation in Confluence

- [ ] Use cases + user stories — one per stakeholder need listed in the brief's "Use of Fleet Database" section
- [ ] Seed-data generator write-up (staged design, why insert order respects the triggers, verification tooling)
- [ ] Physical model write-up (conceptual → physical translation decisions)
- [ ] Example data per table, pulled from the actual generated seed data

---

## ERD — Final Pass

- [ ] Fold in `Role` / `User` once the FK approach above is agreed
- [ ] Double-check weak-entity / subtype modeling reads cleanly for the rubric

---

## CRUD Dashboard App (required)

- [ ] Confirm tech stack as a team
- [ ] Role-based dashboards:
  - [ ] Driver
  - [ ] Mechanic
  - [ ] Safety Staff
  - [ ] Fleet Manager
  - [ ] Workshop Manager
  - [ ] Admin (possibly)
- [ ] Each dashboard pulls from its relevant slice of `6_business_queries.sql`
- [ ] Auth/login wired to `User` / `Role`

NOTE: Or we can set aside the auth/login and work on making the website function first, but it's recommended that we do the security part first.

---

