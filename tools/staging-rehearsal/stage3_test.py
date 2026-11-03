"""Stage 3 database checks: account deletion keeps anonymised orders and
payments, and the retention clean-up acts only on confirmed periods. Run
last, against the database made by build_local_db.sh.

    REHEARSAL_DSN="host=... user=... dbname=..." python3 stage3_test.py"""
import json
import os
import sys
import traceback
import uuid

import psycopg

DSN = os.environ.get("REHEARSAL_DSN", "host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal")
ITEMS = json.dumps([{"menu_item_id": "kota-1", "quantity": 1, "notes": "allergic to nuts"}])
results = []


def conn():
    return psycopg.connect(DSN, autocommit=False)


def claims(c, role, uid=None):
    payload = {"role": role}
    if uid:
        payload["sub"] = uid
    c.execute("select set_config('request.jwt.claims', %s, true)", (json.dumps(payload),))
    c.execute(f"set local role {role}")


def one(c, sql, args=()):
    return c.execute(sql, args).fetchone()


def raises(c, sql, args=(), contains=None):
    c.execute("savepoint s")
    try:
        c.execute(sql, args)
    except psycopg.Error as e:
        c.execute("rollback to savepoint s")
        if contains and contains.lower() not in str(e).lower():
            raise AssertionError(f"wrong error: {e}") from e
        return
    c.execute("rollback to savepoint s")
    raise AssertionError(f"allowed: {sql[:80]}")


def new_user(c, anonymous=False, age_days=0):
    uid = str(uuid.uuid4())
    c.execute("""insert into auth.users (id, email, raw_user_meta_data, is_anonymous, created_at, last_sign_in_at)
                 values (%s, %s, '{"full_name": "Erin"}'::jsonb, %s, now() - make_interval(days => %s), now() - make_interval(days => %s))""",
              (uid, None if anonymous else f"{uid[:8]}@example.test", anonymous, age_days, age_days))
    return uid


def paid_order(c, uid, request_id):
    """A paid order for uid, made the same way the payment webhook makes one."""
    claims(c, "authenticated", uid)
    draft = one(c, "select public.prepare_card_checkout('Erin Example','0821234567','delivery','yoco','12 Test Street, Bloemfontein',75::numeric,%s,%s::jsonb)",
                (request_id, ITEMS))[0]["id"]
    claims(c, "service_role")
    checkout = f"ch_{request_id}"
    c.execute("update public.checkout_intents set yoco_checkout_id=%s, yoco_mode='test' where id=%s", (checkout, draft))
    one(c, "select public.record_card_payment_event(%s,%s,'pay_s3',7500,'test')", (f"evt_{request_id}", checkout))
    c.execute("reset role")
    return draft


def test(name):
    def deco(fn):
        results.append((name, fn))
        return fn
    return deco


@test("deleting an account keeps its orders and payments, without personal details")
def _(c):
    uid = new_user(c)
    order_id = paid_order(c, uid, "req-s3-0001")
    claims(c, "authenticated", uid)
    c.execute("select public.delete_own_account()")
    c.execute("reset role")
    assert one(c, "select count(*) from auth.users where id=%s", (uid,))[0] == 0
    assert one(c, "select count(*) from public.profiles where id=%s", (uid,))[0] == 0
    row = one(c, "select user_id, customer_name, customer_phone, delivery_address, total_price, payment_status from public.orders where id=%s", (order_id,))
    assert row == (None, "Deleted customer", "deleted", None, 75, "paid"), row
    assert one(c, "select notes from public.order_items where order_id=%s", (order_id,))[0] == ""
    assert one(c, "select count(*), max(amount_cents) from public.payments where order_id=%s", (order_id,)) == (1, 7500)
    assert one(c, "select count(*) from public.checkout_intents where user_id=%s", (uid,))[0] == 0


@test("a deleted customer's orders are visible to admins only")
def _(c):
    customer = new_user(c)
    claims(c, "authenticated", customer)
    assert one(c, "select count(*) from public.orders where customer_name='Deleted customer'")[0] == 0
    claims(c, "anon")
    raises(c, "select public.delete_own_account()")


@test("helpers and clean-up cannot be called by customers")
def _(c):
    for fn in ["anonymise_customer_orders(uuid)", "run_retention()"]:
        row = one(c, f"select has_function_privilege('authenticated','public.{fn}','execute'), has_function_privilege('anon','public.{fn}','execute')")
        assert row == (False, False), (fn, row)
    claims(c, "authenticated", new_user(c))
    raises(c, "update public.retention_settings set confirmed=true")
    assert one(c, "select count(*) from public.retention_settings")[0] == 0, "customers can read retention settings"


@test("retention defaults are proposals: nothing is cleaned up until confirmed")
def _(c):
    assert one(c, "select count(*) from public.retention_settings where confirmed")[0] == 0
    old_guest = new_user(c, anonymous=True, age_days=200)
    c.execute("update public.checkout_intents set created_at = now() - interval '400 days' where client_request_id='req-s3-unused'")
    assert one(c, "select public.run_retention()")[0] == {}
    assert one(c, "select count(*) from auth.users where id=%s", (old_guest,))[0] == 1


@test("confirmed periods remove old drafts and order-less guests only")
def _(c):
    recent_guest = new_user(c, anonymous=True, age_days=1)
    old_guest = new_user(c, anonymous=True, age_days=200)
    old_guest_with_order = new_user(c, anonymous=True, age_days=200)
    order_id = paid_order(c, old_guest_with_order, "req-s3-0002")
    claims(c, "authenticated", recent_guest)
    one(c, "select public.prepare_card_checkout('Guest','0821234567','pickup','yoco',null,45::numeric,'req-s3-0003',%s::jsonb)", (json.dumps([{"menu_item_id": "kota-1", "quantity": 1}]),))
    c.execute("reset role")
    c.execute("update public.checkout_intents set created_at = now() - interval '45 days' where client_request_id in ('req-s3-0002')")
    c.execute("update public.retention_settings set confirmed=true, confirmed_by='rehearsal' where data_type in ('checkout_drafts','guest_accounts')")
    summary = one(c, "select public.run_retention()")[0]
    assert summary["checkout_drafts"] >= 1 and summary["guest_accounts"] >= 1, summary
    assert one(c, "select count(*) from auth.users where id=%s", (old_guest,))[0] == 0
    assert one(c, "select count(*) from auth.users where id=%s", (recent_guest,))[0] == 1
    assert one(c, "select count(*) from auth.users where id=%s", (old_guest_with_order,))[0] == 1, "guest with an order was removed"
    assert one(c, "select count(*) from public.orders where id=%s", (order_id,))[0] == 1, "the paid order was removed"
    assert one(c, "select count(*) from public.checkout_intents where client_request_id='req-s3-0003'")[0] == 1, "recent draft removed"
    c.execute("update public.retention_settings set confirmed=false, confirmed_by=null")


@test("open-ended periods are never cleaned up, even if marked confirmed")
def _(c):
    before = one(c, "select count(*) from public.orders where user_id is null")[0]
    c.execute("update public.retention_settings set confirmed=true where data_type='deleted_customer_orders'")
    assert "deleted_customer_orders" not in one(c, "select public.run_retention()")[0]
    assert one(c, "select count(*) from public.orders where user_id is null")[0] == before
    c.execute("update public.retention_settings set confirmed=false")


def run():
    passed = failed = 0
    for name, fn in results:
        c = conn()
        try:
            fn(c)
            c.commit()
            print(f"PASS  {name}")
            passed += 1
        except Exception as e:  # noqa: BLE001
            c.rollback()
            print(f"FAIL  {name}: {type(e).__name__}: {e}")
            traceback.print_exc()
            failed += 1
        finally:
            c.close()
    print(f"\n{passed} passed, {failed} failed, {len(results)} total")
    return failed


if __name__ == "__main__":
    sys.exit(1 if run() else 0)
