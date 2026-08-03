# CHANGELOG: Part Receipt Tracking (`PartReceipt`)

> **Status: ROLLED BACK**
> The `PartReceipt` table was designed and briefly added to the schema, then deliberately removed. **It does not exist in the current `schema.sql`.** This document is retained as a record of the design decisions made, the reasoning behind the rollback, and a ready-made starting point if the requirement ever becomes a stated need.

---

## 1. Summary

A `PartReceipt` table was introduced to track physical stock deliveries, enabling two capabilities the base schema lacked:

1. **Audited restocking** — a verifiable history of *when* stock arrived and *how much*.
2. **Supplier price-trend history** — the price *actually paid* per batch, preserved even after standing prices are renegotiated.

After scoping review, the change was **rolled back**. Supplier performance in this system is scoped strictly to **price competitiveness and lead time**, not delivery/quality auditing. The table was removed cleanly (verified by `grep` — no other file referenced it). The design below is preserved verbatim as the restart point, not a from-scratch exercise.

---

## 2. The Change (As Designed)

### 2.1 Table Schema — `PartReceipt`

| Column | Type | Constraints |
| :--- | :--- | :--- |
| `ReceiptID` | `INT UNSIGNED` | PK, `AUTO_INCREMENT` |
| `PartNumber` | `INT UNSIGNED` | NOT NULL, FK → `Part` |
| `SupplierID` | `SMALLINT UNSIGNED` | NOT NULL, **Composite FK → `PartSupplier(PartNumber, SupplierID)`** — can only receive from a supplier actually registered (primary or backup) for that part |
| `DateReceived` | `DATE` | NOT NULL |
| `QuantityReceived` | `SMALLINT UNSIGNED` | NOT NULL, `CHECK > 0` |
| `UnitCost` | `BIGINT UNSIGNED` | NOT NULL, `CHECK > 0`. Price **actually paid** for this batch — deliberately separate from `PartSupplier.UnitCost` (today's standing price), which can be renegotiated without rewriting history. |

### 2.2 Trigger Behavior

* **On `INSERT`:** `QuantityReceived` restocks `Part.CurrentStock` immediately and in full.
* **Immutability:** Every column is a delivery fact. There is no equivalent of a job's `DateClosed` or a claim's `Status` to leave open. A wrong entry is **deleted and re-entered** — the same delete-and-reinsert pattern used for `ActivityPart` corrections (File 5, D5.4), keeping inventory math perfectly synced.

---

## 3. Key Design Decisions

These choices defined the design. They are the reasoning to carry forward if the table is ever reintroduced.

### 3.1 Scope: Price Competitiveness, Not Quality
* **Decision:** The table's purpose was scoped to **price competitiveness** (what was paid, when), *not* delivery-quality auditing (on-time vs. late, defect rates).
* **Rationale:** This was the single biggest choice in the change. Every other decision follows from it. Quality/lot-traceability was deemed out of scope for this iteration.

### 3.2 Full, Immediate Restocking — No Staged Receiving
* **Decision:** `QuantityReceived` restocks in full on insert. There is no "expected vs. arrived" distinction.
* **Rationale:** A receipt row represents stock that has **physically arrived, full stop.** If staged receiving becomes a real need, that is an *additional status field* — not a reason to revisit this design.

### 3.3 Seed `CurrentStock` Is an Untracked Opening Balance
* **Decision:** Existing seeded `Part.CurrentStock` values are treated as opening balances that **predate** `PartReceipt` and have no corresponding receipt rows.
* **Rationale:** Intentional. You cannot retroactively fabricate delivery history for stock that existed before tracking began.

### 3.4 Fully Immutable Rows
* **Decision:** `PartReceipt` rows are immutable after insert. Corrections = delete + re-enter.
* **Rationale:** Matches the historical-accuracy philosophy used throughout (e.g., `VehicleAssignment` founding-fact locks, File 1 D1.3). Delivery facts must stay exactly as recorded for audit integrity.

---

## 4. The Rollback

* **Action:** The `PartReceipt` table and its restock trigger were removed from `schema.sql`.
* **Verification:** Confirmed by `grep` across all files that **nothing referenced `PartReceipt`** before removal — no triggers, procedures, seed stages, or views depended on it, so the removal was clean and side-effect-free.
* **Reason:** Supplier-performance scope is limited to price and lead time. Lot-level delivery traceability was not a stated requirement, so the table was premature.

---

## 5. Known Gaps That Remain (Regardless of This Change)

These were flagged during the design review and are **not** addressed by either adding or removing `PartReceipt`:

* **Delivery reliability is unmeasured.** `Supplier.DeliveryLeadTime` is the *contracted* figure, but there is no `OrderDate` anywhere to compare `PartReceipt.DateReceived` against. On-time vs. late cannot be computed. This is a separate, smaller gap — noted, not resolved here.

---

## 6. Future Starting Point

If **audited restocking** or **supplier price-trend history** becomes an actual stated requirement later:

* **§2 (schema) and §3 (decisions) are the starting point** — not a from-scratch design.
* Reintroduce the table as specified, re-add the insert-time restock trigger, and decide whether to also close the delivery-reliability gap (§5) by adding an `OrderDate` for on-time comparison.