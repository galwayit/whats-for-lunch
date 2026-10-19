"""Exercise migrations and billing invariants in the dedicated disposable Docker DB.
Usage: python3 tests/postgres_regression.py lunch-review-postgres-20261001 [--bootstrap-settings-first]
No production credentials or ports are used. A fresh database is created per run.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import subprocess
import sys
import uuid

container = sys.argv[1]
if not container.startswith("lunch-review-postgres-"):
    raise SystemExit("Refusing to run outside the dedicated disposable test container")
database = "lunch_test_" + uuid.uuid4().hex


def sql(text, db=database):
    result = subprocess.run(
        ["docker", "exec", "-i", container, "psql", "-U", "postgres", "-d", db,
         "-X", "-q", "-tA", "-v", "ON_ERROR_STOP=1"],
        input=text, text=True, capture_output=True, check=True,
    )
    return result.stdout.strip()


def check(condition, label):
    if not condition:
        raise AssertionError(label)
    print("PASS", label)


sql(f"CREATE DATABASE {database};", "postgres")
sql("""
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN BYPASSRLS; END IF;
END $$;
CREATE SCHEMA extensions;
CREATE SCHEMA auth;
CREATE TABLE auth.users (id uuid PRIMARY KEY);
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
$$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
GRANT USAGE ON SCHEMA auth, public, extensions TO anon, authenticated, service_role;
CREATE PUBLICATION supabase_realtime;
""")
root = Path(__file__).resolve().parents[1]
bootstrap_first = "--bootstrap-settings-first" in sys.argv[2:]
if bootstrap_first:
    settings_migration = root / "supabase/migrations/20261001140622_ai_provider_system_parameters.sql"
    bootstrap = settings_migration.read_text().split("-- END SETTINGS BOOTSTRAP:", 1)[0]
    sql(bootstrap)
    check(sql("SELECT value->'providers'->1->'models'->>'pro' FROM system_parameters WHERE key='ai.providers';") == "gpt-6-luna", "settings can be provisioned before billing and quotas")
    sql("SET ROLE service_role; UPDATE system_parameters SET value=jsonb_set(value, '{providers,1,models,pro}', '\"operator-selected-model\"') WHERE key='ai.providers';")
    sql(bootstrap)
    check(sql("SELECT count(*) FROM system_parameter_history;") == "2", "repeated settings bootstrap does not create phantom audit entries")
for migration in sorted((root / "supabase/migrations").glob("*.sql")):
    sql(migration.read_text())
check(True, "every migration applies to PostgreSQL 17")
if bootstrap_first:
    check(sql("SELECT value->'providers'->1->'models'->>'pro' FROM system_parameters WHERE key='ai.providers';") == "operator-selected-model", "full rollout preserves the operator's model settings")
    check(sql("SELECT count(*) FROM system_parameter_history;") == "2", "full rollout preserves configuration history without duplicate seed entries")

alice = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
bob = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
sql(f"INSERT INTO auth.users VALUES ('{alice}'), ('{bob}');")


def reserve(_):
    return sql(f"SET ROLE service_role; SELECT public.reserve_ai_request('{alice}', '{uuid.uuid4()}', 1);")


with ThreadPoolExecutor(max_workers=12) as executor:
    outcomes = list(executor.map(reserve, range(30)))
check(outcomes.count("t") == 1, "30 simultaneous free requests spend exactly one allowance")
request = sql(f"SELECT request_id FROM ai_reservations WHERE app_user_id='{alice}';")
check(sql(f"SET ROLE service_role; SELECT refund_ai_request('{bob}', '{request}');") == "f", "another account cannot refund a reservation")
check(sql(f"SET ROLE service_role; SELECT refund_ai_request('{alice}', '{request}');") == "t", "failed AI call refunds its own reservation")
check(sql(f"SET ROLE service_role; SELECT refund_ai_request('{alice}', '{request}');") == "f", "duplicate refund does not decrement twice")
check(sql(f"SET ROLE service_role; SELECT reserve_ai_request('{alice}', '{request}', 1);") == "f", "refunded request ID cannot be reused")
check(reserve(0) == "t", "a fresh request can use the refunded allowance")
check(sql(f"SELECT ai_requests FROM usage WHERE app_user_id='{alice}';") == "1", "usage remains correct after refund and retry")


def snapshot(pro, timestamp, event):
    payload = json.dumps([{"app_user_id": alice, "is_pro": pro, "product_id": "lunch_pro_monthly",
                           "expires_at": "2099-01-01T00:00:00Z", "environment": "PRODUCTION"}])
    return sql(f"SET ROLE service_role; SELECT apply_revenuecat_snapshot('{payload}'::jsonb, '{timestamp}', '{event}');")


check(snapshot(True, "2026-10-01T01:00:00Z", "purchase") == "t", "valid billing snapshot applies")
check(snapshot(False, "2026-10-01T02:00:00Z", "refund") == "t", "refund removes access")
snapshot(True, "2026-10-01T01:00:00Z", "delayed-purchase")
check(sql(f"SELECT is_pro FROM entitlements WHERE app_user_id='{alice}';") == "f", "older purchase cannot overwrite newer refund")
check(snapshot(True, "2026-10-01T03:00:00Z", "refund") == "f", "duplicate webhook event cannot change state")
check(sql("SELECT count(*) FROM revenuecat_events WHERE event_id='refund';") == "1", "event ledger is idempotent")

with ThreadPoolExecutor(max_workers=12) as executor:
    budgets = list(executor.map(lambda _: sql("SET ROLE service_role; SELECT reserve_upstream_request('places', 10);"), range(30)))
check(budgets.count("t") == 10, "upstream capacity cap holds under simultaneous calls")
for role in ["anon", "authenticated"]:
    for function in ["reserve_ai_request(uuid,uuid,integer)", "refund_ai_request(uuid,uuid)",
                     "apply_revenuecat_snapshot(jsonb,timestamptz,text)", "reserve_upstream_request(text,integer)"]:
        check(sql(f"SELECT has_function_privilege('{role}', '{function}', 'EXECUTE');") == "f", f"{role} cannot execute {function}")

sql(f"""INSERT INTO groups(id,host_id,name,scheduled_at,area_lat,area_lng,radius_km,invite_code)
VALUES ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','{alice}','Fictional test lunch',now(),-33,151,2,'ABCD1234');""")
check(sql(f"SET ROLE authenticated; SET request.jwt.claim.sub='{bob}'; SELECT count(*) FROM groups;") == "0", "unrelated account cannot read a group")
check(sql(f"SET ROLE authenticated; SET request.jwt.claim.sub='{alice}'; SELECT count(*) FROM groups;") == "1", "host can read their group without recursive RLS")
# Protected runtime configuration and independent provider budgets.
for role in ["anon", "authenticated"]:
    for table in ["system_parameters", "system_parameter_history"]:
        for privilege in ["SELECT", "INSERT", "UPDATE", "DELETE"]:
            check(sql(f"SELECT has_table_privilege('{role}', '{table}', '{privilege}');") == "f", f"{role} cannot {privilege} {table}")
    check(sql(f"SELECT has_function_privilege('{role}', 'reserve_ai_provider_request(text,integer,integer)', 'EXECUTE');") == "f", f"{role} cannot reserve AI provider capacity")
check(sql("SET ROLE service_role; SELECT value->>'enabled' FROM system_parameters WHERE key='ai.providers';") == "false", "AI starts disabled until provider verification")
history_count = int(sql("SELECT count(*) FROM system_parameter_history WHERE key='ai.providers';"))
sql("SET ROLE service_role; UPDATE system_parameters SET value=jsonb_set(value, '{primary}', '\"claude\"') WHERE key='ai.providers';")
check(int(sql("SELECT count(*) FROM system_parameter_history WHERE key='ai.providers';")) == history_count + 1, "runtime parameter edits preserve history")
with ThreadPoolExecutor(max_workers=12) as executor:
    ai_budgets = list(executor.map(lambda _: sql("SET ROLE service_role; SELECT reserve_ai_provider_request('google', 5, 8);"), range(20)))
check(ai_budgets.count("t") == 5, "primary provider cap holds under concurrency")
with ThreadPoolExecutor(max_workers=12) as executor:
    backup_budgets = list(executor.map(lambda _: sql("SET ROLE service_role; SELECT reserve_ai_provider_request('openai', 5, 8);"), range(20)))
check(backup_budgets.count("t") == 3, "backup respects the combined daily AI ceiling")
check(sql("SELECT requests FROM upstream_usage WHERE provider='ai';") == "8", "rejected reservations do not consume global capacity")
try:
    sql("SET ROLE service_role; SELECT reserve_ai_provider_request('openai', null, 8);")
except subprocess.CalledProcessError:
    check(True, "null limits cannot bypass AI capacity validation")
else:
    raise AssertionError("Null capacity limit was accepted")
print("All PostgreSQL regression checks passed; disposable database:", database)
