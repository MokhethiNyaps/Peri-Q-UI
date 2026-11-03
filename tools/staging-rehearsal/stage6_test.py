"""Stage 6 database checks: least-privilege grants, admin column limits,
profile email protection, retired EFT uploads, storage listing, and the
admin audit log. Run against the database made by build_local_db.sh, after
rehearsal_test.py and stage5_test.py (which leave paid orders behind).

    REHEARSAL_DSN="host=... user=... dbname=..." python3 stage6_test.py"""
import json
import os
import sys
import traceback
import uuid

import psycopg

DSN = os.environ.get("REHEARSAL_DSN", "host=/tmp/pgdata user=postgres dbname=peri_q_rehearsal")
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


def new_user(c, admin=False):
    uid = str(uuid.uuid4())
    c.execute("insert into auth.users (id, email, raw_user_meta_data) values (%s, %s, '{}'::jsonb)",
              (uid, f"{uid[:8]}@example.test"))
    if admin:
        c.execute("alter table public.profiles disable trigger profiles_protect_role")
        c.execute("update public.profiles set role='admin' where id=%s", (uid,))
        c.execute("alter table public.profiles enable trigger profiles_protect_role")
    return uid


def test(name):
    def deco(fn):
        results.append((name, fn))
        return fn
    return deco


@test("signed-out visitors cannot write any table; nobody but the owner can truncate")
def _(c):
    tables = [r[0] for r in c.execute("select tablename from pg_tables where schemaname='public'").fetchall()]
    for table in tables:
        for privilege in ["insert", "update", "delete"]:
            assert not one(c, "select has_table_privilege('anon', %s, %s)", (f"public.{table}", privilege))[0], (table, privilege)
        for role in ["anon", "authenticated"]:
            assert not one(c, "select has_table_privilege(%s, %s, 'truncate')", (role, f"public.{table}"))[0], (table, role)
    claims(c, "anon")
    assert one(c, "select count(*) > 0 from public.menu_items")[0], "anon can no longer read the menu"


@test("admins can change an order's status but not its price or payment fields")
def _(c):
    admin = new_user(c, admin=True)
    order_id = one(c, "select id from public.orders where status='pending' and payment_status='paid' order by created_at limit 1")[0]
    claims(c, "authenticated", admin)
    for column, value in [("total_price", "1"), ("payment_status", "'refunded'"), ("customer_phone", "'000'"), ("paid_at", "null")]:
        raises(c, f"update public.orders set {column}={value} where id=%s", (order_id,), contains="permission denied")
    c.execute("update public.orders set status='preparing' where id=%s", (order_id,))
    assert one(c, "select status from public.orders where id=%s", (order_id,))[0] == "preparing"
    entry = one(c, "select actor_id::text, action, changes from public.admin_audit_log where table_name='orders' and row_id=%s order by id desc limit 1", (str(order_id),))
    assert entry[0] == admin and entry[1] == "update", entry
    assert entry[2] == {"status": {"from": "pending", "to": "preparing"}}, entry[2]


@test("server payment updates are not logged as admin actions")
def _(c):
    order_id = one(c, "select id from public.orders order by created_at limit 1")[0]
    before = one(c, "select count(*) from public.admin_audit_log")[0]
    claims(c, "service_role")
    c.execute("update public.orders set payment_status=payment_status where id=%s", (order_id,))
    c.execute("reset role")
    assert one(c, "select count(*) from public.admin_audit_log")[0] == before


@test("customers can edit their name and phone but not their profile email")
def _(c):
    customer = new_user(c)
    claims(c, "authenticated", customer)
    c.execute("update public.profiles set full_name='New Name', phone='0710000000', email='attacker@example.test' where id=%s", (customer,))
    name, phone, email = one(c, "select full_name, phone, email from public.profiles where id=%s", (customer,))
    assert (name, phone) == ("New Name", "0710000000")
    assert email == f"{customer[:8]}@example.test", email
    c.execute("insert into public.profiles (id, email, full_name, phone) values (%s, %s, 'Upsert Name', '0711111111') on conflict (id) do update set email=excluded.email, full_name=excluded.full_name, phone=excluded.phone",
              (customer, "other@example.test"))
    assert one(c, "select email, full_name from public.profiles where id=%s", (customer,)) == (f"{customer[:8]}@example.test", "Upsert Name")


@test("new signups still create profiles after the trigger function was locked down")
def _(c):
    assert not one(c, "select has_function_privilege('authenticated', 'public.handle_new_user()', 'execute')")[0]
    uid = new_user(c)
    assert one(c, "select count(*) from public.profiles where id=%s", (uid,))[0] == 1


@test("EFT payment proofs can no longer be uploaded or attached")
def _(c):
    customer = new_user(c)
    claims(c, "authenticated", customer)
    raises(c, "insert into storage.objects (bucket_id, name) values ('payment-proofs', %s)", (f"{customer}/order/proof.png",))
    raises(c, "select public.attach_payment_proof(gen_random_uuid(), 'x')", contains="permission denied")


@test("only admins can list the menu-images bucket")
def _(c):
    c.execute("insert into storage.buckets (id, name, public) values ('menu-images', 'menu-images', true) on conflict (id) do nothing")
    c.execute("insert into storage.objects (bucket_id, name) values ('menu-images', 'items/stage6-test.webp')")
    customer = new_user(c)
    admin = new_user(c, admin=True)
    claims(c, "anon")
    assert one(c, "select count(*) from storage.objects where bucket_id='menu-images'")[0] == 0
    claims(c, "authenticated", customer)
    assert one(c, "select count(*) from storage.objects where bucket_id='menu-images'")[0] == 0
    claims(c, "authenticated", admin)
    assert one(c, "select count(*) from storage.objects where bucket_id='menu-images'")[0] >= 1


@test("admin menu edits are logged; customers cannot read the audit log")
def _(c):
    admin = new_user(c, admin=True)
    claims(c, "authenticated", admin)
    c.execute("update public.menu_items set price = price + 1 where id='kota-1'")
    entry = one(c, "select action, changes ? 'price', changes ? 'updated_at' from public.admin_audit_log where table_name='menu_items' and row_id='kota-1' order by id desc limit 1")
    assert entry == ("update", True, False), entry
    c.execute("update public.menu_items set price = price - 1 where id='kota-1'")
    c.execute("reset role")
    customer = new_user(c)
    claims(c, "authenticated", customer)
    assert one(c, "select count(*) from public.admin_audit_log")[0] == 0
    raises(c, "insert into public.admin_audit_log (table_name, row_id, action) values ('x', 'y', 'update')")


@test("customer profile edits are not admin actions")
def _(c):
    customer = new_user(c)
    before = one(c, "select count(*) from public.admin_audit_log")[0]
    claims(c, "authenticated", customer)
    c.execute("update public.profiles set full_name='Just Me' where id=%s", (customer,))
    c.execute("reset role")
    assert one(c, "select count(*) from public.admin_audit_log")[0] == before


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
