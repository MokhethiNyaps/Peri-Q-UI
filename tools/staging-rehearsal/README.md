# Card-checkout staging rehearsal

Repeatable, credential-free rehearsal of
`peri_q_app/supabase/migrations/20261017000000_card_only_checkout.sql` against the
schema that production actually has (the repository `schema.sql` without the
checkout-draft block), plus the RLS, pricing, idempotency and concurrency
guarantees the payment flow depends on.

The production project is **not** touched and no payment provider is called.

## What it builds

`build_local_db.sh` creates a disposable database containing:

1. minimal Supabase stand-ins (`stub.sql`) — `auth.users`, `auth.uid()`,
   `auth.role()`, `storage.*`, the `anon`/`authenticated`/`service_role` roles and
   the `supabase_realtime` publication;
2. the **prior** schema, taken from `git show <base>:peri_q_app/supabase/schema.sql`
   up to the `-- Checkout drafts never appear in orders` marker;
3. the card-only migration from the working tree;
4. deterministic fixtures (`seed.sql`) — menu items, store settings, two customers.

`historic_data_check.sh` loads cash/EFT/card/Yoco orders, order items, a payment
audit row and a webhook event into that prior schema, applies the migration, and
fails if any of them change.

## Requirements

- PostgreSQL 14+ with `psql` on `PATH` (a local cluster is enough — no Docker
  required). Tested on PostgreSQL 16.2 with `pgserver`'s bundled binaries.
- Python 3.11+ and `psycopg` 3 (`pip install "psycopg[binary]"`).

## Run

```bash
export PATH=/path/to/postgres/bin:$PATH
export PSQL_ARGS="-h /tmp/pgdata -U postgres"      # any psql connection flags
./build_local_db.sh                                 # DB defaults to peri_q_rehearsal

REHEARSAL_DSN="host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal" \
  PYTHONPATH=$(python3 -c 'import site;print(site.getsitepackages()[0])') \
  python3 rehearsal_test.py

./historic_data_check.sh
```

Expected output: `24 passed, 0 failed` and
`PASS historic orders, items, payments and webhook events are unchanged`.

Then run the Stage 5 checks (refunds, atomic webhook events, rate limits) on
the same database, after `rehearsal_test.py`:

```bash
REHEARSAL_DSN="host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal" python3 stage5_test.py
```

Then the Stage 2 checks (policy acceptances, privacy requests):

```bash
REHEARSAL_DSN="host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal" python3 stage2_test.py
```

Then the Stage 6 checks (grants, admin limits, audit log), last:

```bash
REHEARSAL_DSN="host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal" python3 stage6_test.py
```

Expected output: `14 passed, 0 failed` for Stage 5, `8 passed, 0 failed` for
Stage 2 and `9 passed, 0 failed` for Stage 6. All three migrations are safe to apply
twice: every object uses `if not exists`, `create or replace` or
`drop policy if exists`.

## What the 24 checks prove

| Area | Checks |
| --- | --- |
| Schema/privileges | checkout tables exist, RLS on, `prepare_card_checkout` executable by `authenticated` only, `finalize_card_checkout` by `service_role` only |
| Draft isolation | anon cannot read drafts; customers cannot insert/update drafts; one customer cannot read another's draft; payment audit rows are owner-only |
| Trusted pricing | server-computed total, tampered `p_expected_total` rejected, client add-on prices ignored, unavailable items rejected, delivery fee applied, cash methods rejected |
| Idempotency | repeated `client_request_id` returns the same draft; a reused id with changed fulfilment/address/total is rejected |
| Finalization | amount/mode/payment-id/unknown-checkout mismatches rejected; one paid order with copied items; replay returns the same order; concurrent finalize produces exactly one order |
| Fulfilment guard | customers cannot forge a paid order, only admins advance status, unpaid card orders cannot enter fulfilment |
| Legacy compatibility | `place_order` returns the "pay by card" error, historic rows survive the migration |

## Using a real Supabase staging project instead

Point `REHEARSAL_DSN` at a **disposable** staging database and prepare it
yourself: apply `schema.sql` (fresh) or the prior schema plus the migration,
then create two test users and the `kota-1`/`off-1` menu rows and settings used
by `seed.sql`. `stub.sql` must never be run there — it drops `auth`/`storage`.
`seed.sql` writes to `auth.users`, which only works in the SQL editor as the
database owner.

## Known migration behaviour (measured, not assumed)

- Applying the migration twice fails at
  `ERROR: multiple primary keys for table "checkout_intents" are not allowed`.
  It is wrapped in one transaction, so the failed rerun rolls back cleanly and
  leaves the migrated database intact — but it must be recorded in the Supabase
  migration history rather than re-run.
- Re-running the older `20261012155629_yoco_payments.sql` **after** the card-only
  migration succeeds and silently restores the pre-card-only `place_order` body.
  `require_verified_card_order` still blocks the resulting inserts, so no unpaid
  order is created, but the friendly "pay by card" error is lost. Apply
  migrations in timestamp order only.
