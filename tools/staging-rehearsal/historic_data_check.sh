#!/usr/bin/env bash
# Prove the card-only migration preserves historic orders, items, payments and
# webhook events when it is applied to a database that already holds them.
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd ../.. && pwd)"
PSQL_ARGS=${PSQL_ARGS:-"-h /tmp/pgdata -U postgres"}
DB=${DB:-peri_q_rehearsal_legacy}
BASE_REF=${BASE_REF:-main}
PRIOR_SQL="$(mktemp)"
trap 'rm -f "$PRIOR_SQL"' EXIT

git -C "$REPO_ROOT" show "$BASE_REF:peri_q_app/supabase/schema.sql" \
  | awk '/^-- Checkout drafts never appear in orders/{exit} {print}' > "$PRIOR_SQL"
sed -i.bak '1s/^create extension if not exists pgcrypto;/-- pgcrypto omitted/' "$PRIOR_SQL"
rm -f "$PRIOR_SQL.bak"

# shellcheck disable=SC2086
psql $PSQL_ARGS -d postgres -q -c "drop database if exists $DB" -c "create database $DB"
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f stub.sql
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f "$PRIOR_SQL" >/dev/null 2>&1
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f seed.sql
# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 -f legacy_data.sql

before=$(psql $PSQL_ARGS -d "$DB" -At -c \
  "select (select count(*) from public.orders)||'/'||(select count(*) from public.order_items)||'/'||(select count(*) from public.payments)||'/'||(select count(*) from public.yoco_webhook_events)||'/'||(select md5(string_agg(id||payment_method||payment_status||total_price||status, ',' order by id)) from public.orders)")

# shellcheck disable=SC2086
psql $PSQL_ARGS -d "$DB" -q -v ON_ERROR_STOP=1 \
  -f "$REPO_ROOT/peri_q_app/supabase/migrations/20261017000000_card_only_checkout.sql"

after=$(psql $PSQL_ARGS -d "$DB" -At -c \
  "select (select count(*) from public.orders)||'/'||(select count(*) from public.order_items)||'/'||(select count(*) from public.payments)||'/'||(select count(*) from public.yoco_webhook_events)||'/'||(select md5(string_agg(id||payment_method||payment_status||total_price||status, ',' order by id)) from public.orders)")

echo "before: $before"
echo "after : $after"
if [ "$before" != "$after" ]; then
  echo "FAIL historic data changed" >&2
  exit 1
fi
echo "PASS historic orders, items, payments and webhook events are unchanged"
