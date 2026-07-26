# Changelog: `PartReceipt` (Supplier Price Tracking) — Built, Then Fully Reverted

**Final status: `PartReceipt` does not exist in the shipped schema.** This
document exists to record *why* it was tried and why it was ultimately
removed entirely — the reasoning is the actual deliverable here, not the
table.

## 0. Final decision

After the price-only version (§3 below) shipped, a closer look found it was
mostly redundant: `6_business_queries.sql` Q29 already compares each
supplier's *current* price per part using nothing but the original schema
(`PartSupplier.UnitCost`). `PartReceipt`'s only unique remaining
contribution was **historical price-paid trending** — which nobody had
actually asked for — plus an audited restock event, which can be achieved
with a direct `UPDATE Part SET CurrentStock = CurrentStock + N` instead of a
whole table. Keeping it would have meant carrying a table, two triggers, and
ongoing test/documentation overhead for a metric that duplicated existing
coverage. **Removed entirely.** `Part.CurrentStock`'s restock direction is
now a documented convention (see `5_workshop_operations_triggers.sql`'s
"Part Inventory Tracking" section header) rather than a captured event.

Nothing else in the schema, triggers, or the other 32 business queries ever
referenced `PartReceipt` — confirmed by grep across all files before
removing it.

If either audited restocking or supplier price-trend history becomes an
actual stated requirement later, §2 and §3 below are the starting point, not
a from-scratch design.

## 1. The motivating gap

While reviewing `6_business_queries.sql` Q19 ("Monitor supplier performance"),
two independent problems surfaced:

1. **No restock event.** `TRG_ActivityPart_AfterInsert`/`AfterDelete` only ever
   moved `Part.CurrentStock` down (usage) or back up (usage reversed). Nothing
   in the original schema ever *increased* it for a new delivery — it was a
   one-way ratchet toward zero.
2. **No price history.** `PartSupplier.UnitCost` only holds *today's* standing
   price per supplier. If that price is renegotiated, the old figure is gone —
   there was no way to see what was actually paid over time, which is the
   substance of "price competitiveness."

`PartReceipt` — one row per inbound shipment ("lot") of a part from a
supplier — fixes both.

## 2. The road not taken: lot-level traceability

The first version of this change went further: it added `ActivityPart.ReceiptID`
(nullable FK to `PartReceipt`) plus a `QuantityRemaining` depletion counter on
`PartReceipt` itself, so that a specific part *usage* — and any warranty claim
or `RepeatedFaultFlag` tied to it — could be traced back to the exact supplier
lot it came from. The intent was supplier **quality** auditing: "is Supplier
B's part correlated with more failures than Supplier A's," not just pricing.

This was fully built and passed 9 functional tests against a live database
(dual-level stock decrement, cross-part mismatch rejection, lot-insufficiency
distinct from fleet-wide insufficiency, update-lock, delete-restoration — see
§6). It was then rolled back, for two compounding reasons:

- **Workflow problem.** The design assumed whoever logs `ActivityPart` usage
  already knows which physical shipment a given part came from. Nothing in a
  real workshop's process reliably gives them that — once two shipments of
  the same part sit on the same shelf, they're indistinguishable by sight.
  The honest fix would have been FIFO auto-allocation (a procedure resolving
  the lot automatically, oldest-received-first), which in turn would have
  required relaxing `ActivityPart`'s `(ActivityID, PartNumber)` primary key to
  allow a single job to draw from multiple lots for the same part — a real
  structural change, not a small one.
- **Scope mismatch.** Once forced to name what "monitor supplier performance"
  actually needs, it split into three distinct questions: price
  competitiveness, delivery reliability, and quality/defect rate. Only the
  third needs write-time lot tracing at all, and it wasn't the one that got
  selected as in-scope (see §3). Building exact traceability for a dimension
  that was never actually chosen was solving a problem the brief didn't ask
  for, at real cost to the write-path (extra trigger logic on every part
  usage, forever) for a benefit nobody asked to keep.

**Decision:** scope "monitor supplier performance" to **price
competitiveness only**. Quality/defect-rate auditing and recall-style
traceability ("which vehicles got parts from this bad batch") are explicitly
**out of scope** for now. If either becomes a real requirement later, the
rolled-back design (`ActivityPart.ReceiptID` + FIFO allocation via a
`sp_LogPartUsage` procedure) is the starting point — not from scratch.

## 3. The price-only design (also since reverted)

### `PartReceipt` (new table, `schema.sql`)

One row per delivery. Every column is a historical fact — nothing on this
table progresses over time the way a job's status or a claim's outcome does.

| Column | Type | Notes |
|---|---|---|
| `ReceiptID` | `INT UNSIGNED AUTO_INCREMENT PK` | |
| `PartNumber` | `INT UNSIGNED NOT NULL` | FK → `Part` |
| `SupplierID` | `SMALLINT UNSIGNED NOT NULL` | Composite FK → `PartSupplier(PartNumber, SupplierID)` — can only receive from a supplier actually registered (primary or backup) for that part |
| `DateReceived` | `DATE NOT NULL` | |
| `QuantityReceived` | `SMALLINT UNSIGNED NOT NULL` | `CHECK > 0` |
| `UnitCost` | `BIGINT UNSIGNED NOT NULL` | Price actually paid for **this** batch — separate from `PartSupplier.UnitCost` (today's standing price), which can be renegotiated without rewriting history. `CHECK > 0` |

No `QuantityRemaining` / lot-depletion counter — that only existed to support
the rolled-back `ActivityPart` link and would have sat unused (and
misleadingly "live-looking") once that link was removed.

### `ActivityPart` — unchanged

Exactly as it was before this whole change: `ActivityID`, `PartNumber`,
`ClaimID`, `QuantityUsed`, `UnitCost`. No knowledge of suppliers or receipts.
Mechanics log usage exactly as before; nothing new is asked of them.

### Triggers (`5_workshop_operations_triggers.sql`)

- **`TRG_PartReceipt_AfterInsert`** — `Part.CurrentStock += QuantityReceived`.
  The only path in the schema that increases stock.
- **`TRG_PartReceipt_BeforeUpdate`** — locks every column (`PartNumber`,
  `SupplierID`, `DateReceived`, `QuantityReceived`, `UnitCost`). Unlike most
  historical-fact tables in this project, there's no field left open for
  legitimate progression — a correction is delete + re-insert.
- `TRG_ActivityPart_*` (all four) — unchanged from before this feature
  existed.

## 4. Design choices, assumptions, and justifications

- **Price competitiveness, not quality.** Explicit scoping decision (§2/§3) —
  the single biggest choice in this change. Everything else follows from it.
- **`QuantityReceived` restocks immediately, in full, on insert.** No partial
  or staged receiving (e.g. "expected" vs "arrived") — a receipt row
  represents stock that has physically arrived, full stop. If staged
  receiving becomes a real need, that's an additional status field, not a
  reason to revisit this design.
- **Existing seed `Part.CurrentStock` is an untracked opening balance.** It
  predates `PartReceipt` and has no corresponding receipt rows. Intentional —
  no retroactive receipts were fabricated for seed data, matching how an
  opening inventory balance is normally handled.
- **Nothing currently prevents a direct `UPDATE Part SET CurrentStock = ...`.**
  `PartReceipt` (up) and `ActivityPart` (down) are the two paths that are
  *supposed* to move it, but that's convention, not an enforced invariant —
  same as before this change. Worth a call if this needs tightening later
  (a guard mirroring the `DrivingEligibility`/`ReviewState` session-flag
  pattern used elsewhere in this project).
- **`PartReceipt` rows are fully immutable after insert.** Every column is a
  delivery fact; there's no equivalent of a job's `DateClosed` or a claim's
  `Status` to leave open. A wrong entry is deleted and re-entered.
- **Delivery *reliability* (on-time vs late) is still unmeasured.** `Supplier.
  DeliveryLeadTime` is the contracted figure; there's no `OrderDate` anywhere
  to compare `PartReceipt.DateReceived` against. Flagged as a separate,
  smaller gap — not addressed here, since it wasn't part of what triggered
  this change.

## 5. Downstream query impact — superseded by §0

Section 5 originally described adding a `PartReceipt`-based Q19 to
`6_business_queries.sql`. That did ship briefly, then was removed per §0:
`6_business_queries.sql` Q29 (current price per supplier per part, via
`PartSupplier` alone) already covers what Q19 was for. Q19's slot in that
file now just points to Q29 with a one-line note, rather than duplicating
it. The query below is kept here only as a record of what the
`PartReceipt`-based version looked like, in case price-trend history is
ever revisited:

```sql
SELECT
    p.PartName, s.SupplierName, ps.IsPrimary, ps.UnitCost AS CurrentStandingPrice,
    COUNT(pr.ReceiptID) AS ReceiptCount,
    ROUND(AVG(pr.UnitCost), 2) AS AvgActualPricePaid,
    MIN(pr.UnitCost) AS MinPricePaid, MAX(pr.UnitCost) AS MaxPricePaid,
    MAX(pr.DateReceived) AS LastDelivery
FROM PartSupplier ps
JOIN Part p ON p.PartNumber = ps.PartNumber
JOIN Supplier s ON s.SupplierID = ps.SupplierID
LEFT JOIN PartReceipt pr ON pr.PartNumber = ps.PartNumber AND pr.SupplierID = ps.SupplierID
GROUP BY p.PartName, s.SupplierName, ps.IsPrimary, ps.UnitCost
ORDER BY p.PartName, ps.IsPrimary DESC;
```

The flexibility pass on the rest of `6_business_queries.sql` (optional
filters on Q1, Q4, Q5a, Q6, Q21, Q28, Q33, Q30, Q2, Q3, Q11, Q20, Q29, Q32)
did ship, separately from this table's fate — see that file directly.

## 6. Verification

Both the original (lot-traceability) and final (price-only) designs were
loaded into a real MariaDB 10.11 instance and exercised with functional
tests — not just checked for DDL syntax.

**Original design** (9 tests, since rolled back): receipt auto-derives
`QuantityRemaining` and restocks `Part.CurrentStock`; unregistered-supplier
receipt rejected; usage decrements both `Part.CurrentStock` and the specific
lot; cross-part mismatch rejected via composite FK; lot-level insufficiency
correctly distinguished from fleet-wide insufficiency; `ReceiptID` locked
after insert; delete restores both counters; `PartReceipt` historical facts
locked after insert.

**Price-only design** (9 tests, since also reverted): confirmed `ActivityPart.
ReceiptID` and `PartReceipt.QuantityRemaining` no longer exist; receipt
restocks `Part.CurrentStock`; unregistered-supplier receipt still rejected;
`ActivityPart` usage still decrements stock correctly with no lot involved;
`ActivityPart`'s original field-lock (`QuantityUsed`, etc.) intact;
`PartReceipt` fully immutable after insert; delete still restores stock; the
price-competitiveness query (§5) returned correct current-vs-actual figures
per supplier.

**Final state** (current, full revert): re-ran `schema.sql` and
`5_workshop_operations_triggers.sql` through MariaDB clean; confirmed via
`SHOW TABLES LIKE 'PartReceipt'` that the table no longer exists; confirmed
via `grep` across all four SQL files that no executable statement anywhere
still references it; ran the entire updated `6_business_queries.sql` (32
queries, every `?` substituted with `NULL`) end to end with zero errors.
