#!/usr/bin/env bash
# Build a disposable database that reproduces the pre-card-checkout ("prior")
# schema from Git history, then applies the card-only migration and test fixtures.
#
# Requirements: a running PostgreSQL 14+ server and `psql` on PATH.
#   PSQL_ARGS="-h /tmp/pgdata -U postgres" ./build_local_db.sh
# Environment:
#   PSQL_ARGS   connection flags for psql (default: "-h /tmp/pgdata -U postgres")
#   DB          database name to create/replace (default: peri_q_rehearsal)
#   BASE_REF    Git ref holding the prior schema (default: main)
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd ../.. && pwd)"
PSQL_ARGS=${PSQL_ARGS:-"-h /tmp/pgdata -U postgres"}
DB=${DB:-peri_q_rehearsal}
BASE_REF=${BASE_REF:-main}
PRIOR_SQL="$(mktemp)"
trap 'rm -f "$PRIOR_SQL"' EXIT

# The consolidated schema.sql already contains the card-only block, so the
# "prior" production schema is that file up to the checkout-draft section.
git -C "$REPO_ROOT" show "$BASE_REF:peri_q_app/supabase/schema.sql" \
  | awk '/^-- Checkout drafts never appear in orders/{exit} {print}' > "$PRIOR_SQL"
sed -i.bak '1s/^create extension if not exists pgcrypto;/-- pgcrypto is unavailable in some local builds; gen_random_uuid() is built in./' "$PRIOR_SQL"
rm -f "$PRIOR_SQL.bak"

grep -q "checkout_intents" "$PRIOR_SQL" && { echo "prior schema unexpectedly contains checkout_intents" >&2; exit 1; }
[ "$(wc -l < "$PRIOR_SQL")" -gt 500 ] || { echo "prior schema snapshot looks truncated" >&2; exit 1; }

echo "== creating database $DB =="
# shellcheck disable=SC2086
psql $PSQL_ARGS -d postgres -q -c "drop database if exists $DB" -c "create database $DB"

echo "== supabase stubs =="
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f stub.sql

echo "== prior schema (from $BASE_REF) =="
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f "$PRIOR_SQL" 2>&1 | grep -v "does not exist, skipping" || true

echo "== card-only migration =="
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 \
  -f "$REPO_ROOT/peri_q_app/supabase/migrations/20261017000000_card_only_checkout.sql"

echo "== fixtures =="
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f seed.sql

echo "== stage 5 migration (refunds, atomic webhook events, rate limits) =="
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 \
  -f "$REPO_ROOT/peri_q_app/supabase/migrations/20261103120000_yoco_refunds_and_rate_limits.sql"

echo "ready: REHEARSAL_DSN='host=... dbname=$DB' python3 rehearsal_test.py"
