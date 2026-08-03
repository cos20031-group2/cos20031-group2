# Smart Fleet Management System — Team Plan

*Most of this is still open for discussion, feel free flag anything you'd change.*

---

## Process (Confluence / Jira)

- [ ] Confluence for task tracking, meeting minutes, and retrospective (required by rubric) + Jira for day-to-day board — using both or just Confluence is probably fine
- [ ] Recurring meetings, with minutes kept live and actions assigned to named people
- [ ] Retrospective doc, probalby updated incrementally as we go rather than written at the end. Depends on how you want to work.
- [ ] Everyone logs their own contributions as they happen.

---

## Database Core

- [X] Finish `6_business_queries.sql` (the use cases)
Comment: Finnished, needs checking and add indexes.
- [ ] Views / transactions needed for the CRUD dashboards
- [X] Add `Role` + `User` tables for login/dashboard access — **please decide FK pattern below before touching this**
- [ ] Indexes, once queries are final (ie., 6_business_queries.sql): identify candidate columns from actual query patterns → run `EXPLAIN` + timing before/after on the seed dataset → document a retain/discard decision per index with the measured time improvement

### `Role` / `User` design (Done! Now in schema.sql as section 7)

---

Option A — Nullable FK on User (We decided this option)

Role(RoleID, RoleName)
User(UserID, Username, PasswordHash, RoleID FK,
     DriverID FK NULL, MechanicID FK NULL, ReviewStaffID FK NULL)
    

Driver/Mechanic/Safety-Staff-role users: exactly one FK populated, pointing at their existing row.
Manager/Admin-role users: all three FK columns NULL — no operational entity behind them.
CHECK constraint enforces "exactly one FK populated, or none depending on role."

Pro: Driver, Mechanic, SafetyStaff and their existing triggers stay untouched — zero regression risk on code that already works.
Con: three nullable FK columns sitting mostly empty on any given row is a bit of a smell, and doesn't read as "clean" on an ERD.

---

## Documentation in Confluence

- [X] Use cases + user stories — one per stakeholder need listed in the brief's "Use of Fleet Database" section
- [X] Seed-data generator write-up (staged design, why insert order respects the triggers, verification tooling)
- [X] Physical model write-up (conceptual → physical translation decisions)
- [ ] Example data per table, pulled from the actual generated seed data
- [ ] Draw some UML diagrams (class, use case, sequence)

---

## ERD — Final Pass

- [ ] Fold in `Role` / `User` once the FK approach above is agreed
- [ ] Double-check weak-entity / subtype modeling reads cleanly for the rubric

---

## CRUD Dashboard App (finish the other tasks first)

- [ ] Confirm tech stack as a team
- [ ] Role-based dashboards:
  - [ ] Driver - (DriverD0001, 1234)
  - [ ] Mechanic - (MechanicME0001, 1234)
  - [ ] Safety Staff - (SafetyStaff0001, 1234)
  - [ ] Fleet Manager - (FleetManager001, 1234)
  - [ ] Workshop Manager (WorkshopManager001, 1234)
- [ ] Each dashboard pulls from its relevant slice of `6_business_queries.sql`
- [ ] Auth/login wired to `User` / `Role`



NOTE: user_id in user table is redundant if we can just use username as pk
- ANSWER: Checked. You're right that UserID isn't referenced as a FK anywhere else in the schema, so it's not breaking anything today. My only hesitation: usernames are usually a bad PK choice long-term since people sometimes want to change them, and a surrogate ID never has that problem. But given nothing depends on it here and Username's already UNIQUE, I think your simplification is fine for this project. Your call, if you drop it, just give me a heads up. Personally, let's just keep as it is simply because... it works :smile:

- ANSWER: Actually, we'll keep it the way it is.
---

