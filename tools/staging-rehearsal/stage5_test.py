"""Stage 5 database checks: atomic payment events, refunds, rate limits and
privileges. Run against the database made by build_local_db.sh, after
rehearsal_test.py.

    REHEARSAL_DSN="host=... user=... dbname=..." python3 stage5_test.py"""
import json
import os
import sys
import threading
import traceback

import psycopg

DSN = os.environ.get("REHEARSAL_DSN", "host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal")
ALICE = "11111111-1111-1111-1111-111111111111"
BOB = "22222222-2222-2222-2222-222222222222"
ITEMS = json.dumps([{"menu_item_id": "kota-1", "quantity": 2}])  # R90.00 = 9000c
results = []


def conn():
    return psycopg.connect(DSN, autocommit=False)


def as_user(c, uid):
    c.execute("select set_config('request.jwt.claims', %s, true)", (json.dumps({"sub": uid, "role": "authenticated"}),))
    c.execute("set local role authenticated")


def as_service(c):
    c.execute("select set_config('request.jwt.claims', %s, true)", (json.dumps({"role": "service_role"}),))
    c.execute("set local role service_role")


def as_anon(c):
    c.execute("select set_config('request.jwt.claims', %s, true)", (json.dumps({"role": "anon"}),))
    c.execute("set local role anon")


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


def linked_draft(request_id, checkout_id, uid=ALICE):
    """A customer draft linked to a Yoco checkout, as the checkout route leaves it."""
    with conn() as c:
        as_user(c, uid)
        draft = one(c, "select public.prepare_card_checkout('Alice','0821234567','pickup','yoco',null,90::numeric,%s,%s::jsonb)",
                    (request_id, ITEMS))[0]["id"]
        c.commit()
        as_service(c)
        c.execute("update public.checkout_intents set yoco_checkout_id=%s, yoco_mode='test', payment_status='pending' where id=%s",
                  (checkout_id, draft))
        c.commit()
    return draft


def pay(c, event, checkout, payment="pay_s5", amount=9000, mode="test"):
    return one(c, "select public.record_card_payment_event(%s,%s,%s,%s,%s)", (event, checkout, payment, amount, mode))[0]


def refund(c, event, checkout, refund_id, amount, mode="test", currency="ZAR"):
    return one(c, "select public.record_card_refund(%s,%s,%s,%s,%s,%s)", (event, checkout, refund_id, amount, currency, mode))[0]


def test(name):
    def deco(fn):
        results.append((name, fn))
        return fn
    return deco


@test("new functions are service_role only; new tables are not writable by customers")
def _(c):
    for fn in ["record_card_payment_event(text,text,text,integer,text)",
               "record_card_refund(text,text,text,integer,text,text)",
               "consume_rate_limit(text,integer,integer)"]:
        row = one(c, f"""select has_function_privilege('anon','public.{fn}','execute'),
                                has_function_privilege('authenticated','public.{fn}','execute'),
                                has_function_privilege('service_role','public.{fn}','execute')""")
        assert row == (False, False, True), (fn, row)
    as_user(c, ALICE)
    raises(c, "insert into public.payment_refunds (id,yoco_checkout_id,amount_cents,mode,webhook_event_id) values ('r','c',1,'test','e')")
    raises(c, "select * from public.api_rate_limits")
    raises(c, "select public.record_card_refund('e','c','r',1,'ZAR','test')")
    as_anon(c)
    raises(c, "select * from public.payment_refunds")


@test("a payment event creates one paid order, one payment row, and is marked processed")
def _(c):
    draft = linked_draft("req-s5-pay-0001", "ch_s5_1")
    as_service(c)
    assert pay(c, "evt_s5_1", "ch_s5_1") == {"status": "processed", "order_id": str(draft)}
    assert one(c, "select payment_status from public.orders where id=%s", (draft,))[0] == "paid"
    assert one(c, "select count(*), max(status), max(webhook_event_id) from public.payments where order_id=%s", (draft,)) == (1, "succeeded", "evt_s5_1")
    assert one(c, "select processed, outcome, order_id::text from public.yoco_webhook_events where id='evt_s5_1'") == (True, "processed", str(draft))


@test("replaying the same event is a no-op duplicate")
def _(c):
    as_service(c)
    assert pay(c, "evt_s5_1", "ch_s5_1")["status"] == "duplicate"
    assert one(c, "select count(*) from public.orders where yoco_checkout_id='ch_s5_1'")[0] == 1
    assert one(c, "select count(*) from public.payments p join public.orders o on o.id=p.order_id where o.yoco_checkout_id='ch_s5_1'")[0] == 1


@test("a second delivery with a new event ID does not create a second order")
def _(c):
    as_service(c)
    assert pay(c, "evt_s5_1b", "ch_s5_1")["status"] == "processed"
    assert one(c, "select count(*) from public.orders where yoco_checkout_id='ch_s5_1'")[0] == 1


@test("a failed payment write leaves no processed event behind")
def _(c):
    linked_draft("req-s5-pay-0002", "ch_s5_2")
    as_service(c)
    raises(c, "select public.record_card_payment_event('evt_s5_bad','ch_s5_2','pay_x',8999,'test')", contains="mismatch")
    assert one(c, "select count(*) from public.yoco_webhook_events where id='evt_s5_bad'")[0] == 0
    assert one(c, "select count(*) from public.orders where yoco_checkout_id='ch_s5_2'")[0] == 0


@test("concurrent deliveries of one event produce one order: one processed, one duplicate")
def _(c):
    linked_draft("req-s5-pay-0003", "ch_s5_3")
    statuses, errors = [], []
    barrier = threading.Barrier(2)

    def worker():
        try:
            with conn() as w:
                as_service(w)
                barrier.wait()
                statuses.append(pay(w, "evt_s5_3", "ch_s5_3")["status"])
                w.commit()
        except Exception as e:  # noqa: BLE001
            errors.append(e)
    threads = [threading.Thread(target=worker) for _ in range(2)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert not errors, errors
    assert sorted(statuses) == ["duplicate", "processed"], statuses
    as_service(c)
    assert one(c, "select count(*) from public.orders where yoco_checkout_id='ch_s5_3'")[0] == 1


@test("a partial refund is recorded and the order stays paid")
def _(c):
    as_service(c)
    result = refund(c, "evt_r1", "ch_s5_1", "rfd_1", 4000)
    assert result["status"] == "processed" and result["refunded_amount_cents"] == 4000, result
    assert one(c, "select payment_status from public.orders where yoco_checkout_id='ch_s5_1'")[0] == "paid"
    assert one(c, "select p.refunded_amount_cents from public.payments p join public.orders o on o.id=p.order_id where o.yoco_checkout_id='ch_s5_1'")[0] == 4000
    assert one(c, "select processed, outcome from public.yoco_webhook_events where id='evt_r1'") == (True, "processed")


@test("refund replays and repeated refund IDs are not counted twice")
def _(c):
    as_service(c)
    assert refund(c, "evt_r1", "ch_s5_1", "rfd_1", 4000)["status"] == "duplicate"
    assert refund(c, "evt_r1_again", "ch_s5_1", "rfd_1", 4000)["status"] == "duplicate"
    assert one(c, "select count(*), sum(amount_cents) from public.payment_refunds where yoco_checkout_id='ch_s5_1'") == (1, 4000)


@test("refunds beyond the paid amount are rejected and kept for review")
def _(c):
    as_service(c)
    assert refund(c, "evt_r_over", "ch_s5_1", "rfd_over", 5001)["status"] == "rejected"
    assert one(c, "select outcome from public.yoco_webhook_events where id='evt_r_over'")[0] == "rejected"
    assert one(c, "select count(*) from public.payment_refunds where id='rfd_over'")[0] == 0


@test("refunding the remainder marks the order refunded")
def _(c):
    as_service(c)
    assert refund(c, "evt_r2", "ch_s5_1", "rfd_2", 5000)["status"] == "processed"
    assert one(c, "select payment_status from public.orders where yoco_checkout_id='ch_s5_1'")[0] == "refunded"
    assert one(c, "select p.refunded_amount_cents, p.status from public.payments p join public.orders o on o.id=p.order_id where o.yoco_checkout_id='ch_s5_1'") == (9000, "succeeded")


@test("a late payment replay does not undo a refund")
def _(c):
    as_service(c)
    assert pay(c, "evt_s5_1c", "ch_s5_1")["status"] == "processed"
    assert one(c, "select payment_status from public.orders where yoco_checkout_id='ch_s5_1'")[0] == "refunded"


@test("unmatched and wrong-mode refunds are acknowledged without changing payments")
def _(c):
    as_service(c)
    assert refund(c, "evt_r_unlinked", None, "rfd_u", 100)["status"] == "unmatched"
    assert refund(c, "evt_r_unknown", "ch_unknown", "rfd_u2", 100)["status"] == "unmatched"
    assert refund(c, "evt_r_live", "ch_s5_3", "rfd_l", 100, mode="live")["status"] == "rejected"
    assert one(c, "select count(*) from public.payment_refunds where id in ('rfd_u','rfd_u2','rfd_l')")[0] == 0
    assert one(c, "select processed from public.yoco_webhook_events where id='evt_r_unlinked'")[0] is True


@test("customers see only their own refunds")
def _(c):
    as_user(c, ALICE)
    assert one(c, "select count(*) from public.payment_refunds")[0] == 2
    as_user(c, BOB)
    assert one(c, "select count(*) from public.payment_refunds")[0] == 0


@test("rate limits count per bucket and window")
def _(c):
    as_service(c)
    got = [one(c, "select public.consume_rate_limit('test:a', 2, 600)")[0] for _ in range(3)]
    assert got == [True, True, False], got
    assert one(c, "select public.consume_rate_limit('test:b', 2, 600)")[0] is True
    raises(c, "select public.consume_rate_limit('test:c', 0, 600)", contains="invalid")


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
