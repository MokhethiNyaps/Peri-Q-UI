"""Stage 2 database checks: policy acceptances (signup and checkout) and
privacy-rights requests. Run against the database made by build_local_db.sh.

    REHEARSAL_DSN="host=... user=... dbname=..." python3 stage2_test.py"""
import json
import os
import sys
import traceback
import uuid

import psycopg

DSN = os.environ.get("REHEARSAL_DSN", "host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal")
ALICE = "11111111-1111-1111-1111-111111111111"
BOB = "22222222-2222-2222-2222-222222222222"
ITEMS = json.dumps([{"menu_item_id": "kota-1", "quantity": 1}])
results = []


def conn():
    return psycopg.connect(DSN, autocommit=False)


def claims(c, role, uid=None, anonymous=False):
    payload = {"role": role, "is_anonymous": anonymous}
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


def new_user(c, metadata):
    uid = str(uuid.uuid4())
    c.execute("insert into auth.users (id, email, raw_user_meta_data) values (%s, %s, %s::jsonb)",
              (uid, f"{uid[:8]}@example.test", json.dumps(metadata)))
    return uid


def test(name):
    def deco(fn):
        results.append((name, fn))
        return fn
    return deco


@test("new functions are callable by signed-in users only; tables are read-only to customers")
def _(c):
    for fn in ["record_policy_acceptance(text,text,text,uuid)", "submit_privacy_request(text,text)"]:
        assert one(c, f"select has_function_privilege('anon','public.{fn}','execute'), has_function_privilege('authenticated','public.{fn}','execute')") == (False, True), fn
    claims(c, "authenticated", ALICE)
    raises(c, "insert into public.policy_acceptances (user_id, documents, version, context, client) values (%s, array['terms'], 'v', 'signup', 'website')", (ALICE,))
    raises(c, "insert into public.privacy_requests (user_id, request_type, details) values (%s, 'access', 'x')", (ALICE,))
    claims(c, "anon")
    raises(c, "select * from public.policy_acceptances")


@test("signup with accepted policies records a signup acceptance")
def _(c):
    uid = new_user(c, {"full_name": "New Customer", "policy_version": "2026-11-03-draft", "policy_client": "android"})
    assert one(c, "select documents, version, context, client from public.policy_acceptances where user_id=%s", (uid,)) == \
        (["terms", "privacy"], "2026-11-03-draft", "signup", "android")
    assert one(c, "select full_name from public.profiles where id=%s", (uid,))[0] == "New Customer"


@test("signup without, or with invalid, acceptance metadata still succeeds and records nothing")
def _(c):
    plain = new_user(c, {"full_name": "Old App"})
    bad = new_user(c, {"policy_version": "x" * 61, "policy_client": "android"})
    worse = new_user(c, {"policy_version": "v1", "policy_client": "ios-unknown"})
    assert one(c, "select count(*) from public.policy_acceptances where user_id = any(%s::uuid[])", ([plain, bad, worse],))[0] == 0
    assert one(c, "select count(*) from public.profiles where id = any(%s::uuid[])", ([plain, bad, worse],))[0] == 3


@test("checkout acceptance is linked to the caller's checkout and recorded once")
def _(c):
    claims(c, "authenticated", ALICE)
    draft = one(c, "select public.prepare_card_checkout('Alice','0821234567','pickup','yoco',null,45::numeric,'req-s2-0001',%s::jsonb)", (ITEMS,))[0]["id"]
    first = one(c, "select public.record_policy_acceptance('2026-11-03-draft','checkout','website',%s)", (draft,))[0]
    again = one(c, "select public.record_policy_acceptance('2026-11-03-draft','checkout','website',%s)", (draft,))[0]
    assert first == again
    assert one(c, "select count(*), max(context), max(checkout_id::text) from public.policy_acceptances where checkout_id=%s", (draft,)) == (1, "checkout", str(draft))
    claims(c, "authenticated", BOB)
    raises(c, "select public.record_policy_acceptance('2026-11-03-draft','checkout','website',%s)", (draft,), contains="not found")
    assert one(c, "select count(*) from public.policy_acceptances where checkout_id=%s", (draft,))[0] == 0, "Bob can read Alice's acceptance"


@test("invalid acceptances and guests without a session are rejected")
def _(c):
    claims(c, "authenticated", ALICE)
    raises(c, "select public.record_policy_acceptance('', 'checkout', 'website', null)", contains="invalid")
    raises(c, "select public.record_policy_acceptance('v1', 'marketing', 'website', null)", contains="invalid")
    claims(c, "anon")
    raises(c, "select public.record_policy_acceptance('v1', 'checkout', 'website', null)")


@test("customers submit and read their own privacy requests, at most three open")
def _(c):
    claims(c, "authenticated", new_user(c, {"full_name": "Dana"}))
    for kind in ["access", "correction", "deletion"]:
        one(c, "select public.submit_privacy_request(%s, 'Please help with my data.')", (kind,))
    raises(c, "select public.submit_privacy_request('objection', 'One more')", contains="three open")
    raises(c, "select public.submit_privacy_request('access', '   ')", contains="invalid")
    raises(c, "select public.submit_privacy_request('sell', 'x')", contains="invalid")
    assert one(c, "select count(*) from public.privacy_requests")[0] == 3
    claims(c, "authenticated", BOB)
    assert one(c, "select count(*) from public.privacy_requests")[0] == 0, "Bob can read Alice's requests"


@test("guest sessions cannot submit privacy requests")
def _(c):
    claims(c, "authenticated", BOB, anonymous=True)
    raises(c, "select public.submit_privacy_request('access', 'Guest request')", contains="sign in")


@test("only admins can change a request's status, and customers cannot edit details")
def _(c):
    # rehearsal_test.py leaves Alice as an admin, so use a fresh customer.
    customer = new_user(c, {"full_name": "Carol"})
    c.execute("alter table public.profiles disable trigger profiles_protect_role")
    c.execute("update public.profiles set role='admin' where id=%s", (BOB,))
    c.execute("alter table public.profiles enable trigger profiles_protect_role")
    claims(c, "authenticated", customer)
    rid = one(c, "select public.submit_privacy_request('access', 'Send me my data.')")[0]
    c.execute("update public.privacy_requests set status='completed' where id=%s", (rid,))
    assert one(c, "select status from public.privacy_requests where id=%s", (rid,))[0] == "received", "customer changed status"
    raises(c, "update public.privacy_requests set details='changed' where id=%s", (rid,))
    claims(c, "authenticated", BOB)
    c.execute("update public.privacy_requests set status='completed', resolved_at=now() where id=%s", (rid,))
    assert one(c, "select status from public.privacy_requests where id=%s", (rid,))[0] == "completed"
    c.execute("reset role")
    c.execute("alter table public.profiles disable trigger profiles_protect_role")
    c.execute("update public.profiles set role='customer' where id=%s", (BOB,))
    c.execute("alter table public.profiles enable trigger profiles_protect_role")


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
