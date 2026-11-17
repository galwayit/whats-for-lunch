"""Invitation planning transaction tests; includes the existing migration/RLS regressions.
Usage: python3 backend/tests/invitation_regression.py lunch-review-postgres-<name>
"""
from concurrent.futures import ThreadPoolExecutor
import json
import subprocess
import uuid
from postgres_regression import sql, check, alice, bob

group = str(uuid.uuid4())
other = str(uuid.uuid4())
sql(f"""INSERT INTO groups(id,host_id,host_name,name,scheduled_at,area_lat,area_lng,radius_km,invite_code,place_name,place_id)
VALUES ('{group}','{alice}','Sam','Fictional test lunch',now()+interval '3 days',-37,144,2,'TST12345','Old cafe','old-place'),
('{other}','{bob}','Kim','Other fictional lunch',now()+interval '3 days',-37,144,2,'TST67890','Other cafe','other-place');""")
def denied(query, label):
    try: sql(query)
    except subprocess.CalledProcessError: check(True, label)
    else: raise AssertionError(label)

def submit(token='a'*64, user='null', code='TST12345', place='Alternative cafe'):
    return json.loads(sql(f"SET ROLE service_role; SELECT submit_group_suggestion('{code}',{user},'{token}','Guest Sam','{place}','10 Test Lane',now()+interval '4 days','Could we meet here?');"))

with ThreadPoolExecutor(max_workers=8) as pool:
    rows = list(pool.map(lambda _: submit(), range(12)))
check(len({row['id'] for row in rows}) == 1, 'concurrent/retried guest suggestions have one pending result')
row = rows[0]
check(sql(f"SELECT count(*) FROM rsvps WHERE group_id='{group}';") == '1', 'retry does not create duplicate guests')
check(sql(f"SELECT place_name FROM groups WHERE id='{group}';") == 'Old cafe', 'suggestion cannot change plan before host approval')
check(sql(f"SELECT status FROM rsvps WHERE id='{row['rsvp_id']}';") == 'pending', 'suggestion never implies RSVP acceptance')
second = submit(token='b'*64, user=f"'{bob}'", place='Another cafe')
check(second['id'] != row['id'], 'authenticated guest has a separate suggestion')
for role in ['anon', 'authenticated']:
    denied(f"SET ROLE {role}; SELECT * FROM group_suggestions;", f'{role} cannot list private suggestions')
    denied(f"SET ROLE {role}; SELECT submit_group_suggestion('TST12345',null,repeat('a',64),'Sam','Cafe',null,null,null);", f'{role} cannot call service-only submission RPC')
    denied(f"SET ROLE {role}; SELECT review_group_suggestion('{group}','{row['id']}','{alice}',true);", f'{role} cannot impersonate host via RPC')
    denied(f"SET ROLE {role}; SELECT update_group_details('{group}','{alice}','Sam',2500,'AUD','pay_own','card');", f'{role} cannot edit group through RPC')
denied(f"SET ROLE service_role; SELECT review_group_suggestion('{group}','{row['id']}','{bob}',true);", 'verified other user cannot approve')
denied(f"SET ROLE service_role; SELECT review_group_suggestion('{other}','{row['id']}','{bob}',true);", 'suggestion cannot be applied to another group')
denied(f"SET ROLE service_role; SELECT submit_group_suggestion('TST12345','{alice}',null,'Host','Cafe',null,null,null);", 'host cannot impersonate a guest suggestion')
denied("SET ROLE service_role; SELECT submit_group_suggestion('TST12345',null,'not-a-token','Guest','Cafe',null,null,null);", 'invalid anonymous capability rejected')
sql(f"UPDATE rsvps SET status='accepted', responded_at=now() WHERE group_id='{group}';")
result = json.loads(sql(f"SET ROLE service_role; SELECT review_group_suggestion('{group}','{row['id']}','{alice}',true);"))
check(result['place_name'] == 'Alternative cafe' and result['place_address'] == '10 Test Lane', 'host approval changes place and address')
check(result['place_id'] is None, 'manual alternative clears stale Google Place ID')
check(sql(f"SELECT count(*) FROM rsvps WHERE group_id='{group}' AND status <> 'pending';") == '0', 'changed plan resets every RSVP for reconfirmation')
check(sql(f"SELECT status FROM group_suggestions WHERE id='{second['id']}';") == 'superseded', 'competing proposal becomes stale after plan changes')
denied(f"SET ROLE service_role; SELECT review_group_suggestion('{group}','{second['id']}','{alice}',true);", 'stale host action cannot overwrite a newer accepted plan')
third = submit(token='c'*64, place='Declined cafe')
sql(f"SET ROLE service_role; SELECT review_group_suggestion('{group}','{third['id']}','{alice}',false);")
check(sql(f"SELECT place_name FROM groups WHERE id='{group}';") == 'Alternative cafe', 'declining a suggestion leaves plan unchanged')
sql(f"UPDATE rsvps SET status='accepted' WHERE group_id='{group}';")
sql(f"SET ROLE service_role; SELECT update_group_details('{group}','{alice}','Sam',2500,'AUD','split_equally','card');")
check(sql(f"SELECT budget_per_person_minor FROM groups WHERE id='{group}';") == '2500', 'per-person budget stored as exact cents')
check(sql(f"SELECT count(*) FROM rsvps WHERE group_id='{group}' AND status <> 'pending';") == '0', 'material payment update needs fresh RSVP')
sql(f"UPDATE rsvps SET status='accepted' WHERE group_id='{group}';")
sql(f"SET ROLE service_role; SELECT update_group_details('{group}','{alice}','Samuel',2500,'AUD','split_equally','card');")
check(sql(f"SELECT count(*) FROM rsvps WHERE group_id='{group}' AND status = 'pending';") == '0', 'host spelling correction preserves RSVP')
sql(f"UPDATE groups SET cancelled_at=now() WHERE id='{group}';")
denied("SET ROLE service_role; SELECT submit_group_suggestion('TST12345',null,repeat('d',64),'Guest','Cafe',null,null,null);", 'cancelled lunch rejects new suggestions')
denied(f"SET ROLE service_role; SELECT update_group_details('{group}','{alice}','Sam',0,'AUD','host_pays','card');", 'cancelled lunch cannot be edited')

# Guest ceiling: 200 per lunch on every insert path; existing replies stay editable.
def guest_token(n): return format(n, '064x')
sql(f"""INSERT INTO rsvps(group_id,guest_user_id,display_name) VALUES ('{other}','{alice}','Signed-in guest');
INSERT INTO rsvps(group_id,guest_token,display_name) SELECT '{other}',lpad(to_hex(n),64,'0'),'Guest '||n FROM generate_series(1,194) n;""")
def reply(n):
    try: sql(f"SET ROLE service_role; INSERT INTO rsvps(group_id,guest_token,display_name,status) VALUES ('{other}','{guest_token(1000+n)}','Late guest','accepted');")
    except subprocess.CalledProcessError: return False
    return True
with ThreadPoolExecutor(max_workers=8) as pool:
    replies = list(pool.map(reply, range(12)))
check(replies.count(True) == 5 and sql(f"SELECT count(*) FROM rsvps WHERE group_id='{other}';") == '200', 'guest ceiling holds under simultaneous replies')
denied(f"SET ROLE service_role; SELECT submit_group_suggestion('TST67890',null,'{guest_token(2000)}','Guest','Cafe',null,null,null);", 'a full lunch rejects a new guest who arrives through a suggestion')
sql(f"SET ROLE service_role; UPDATE rsvps SET status='declined', responded_at=now() WHERE group_id='{other}' AND guest_token='{guest_token(1)}';")
sql(f"""SET ROLE service_role; INSERT INTO rsvps(group_id,guest_user_id,display_name,status) VALUES ('{other}','{alice}','Signed-in guest','accepted')
ON CONFLICT (group_id,guest_user_id) DO UPDATE SET status=excluded.status;""")
check(sql(f"SELECT string_agg(status,',' ORDER BY status) FROM rsvps WHERE group_id='{other}' AND (guest_token='{guest_token(1)}' OR guest_user_id='{alice}');") == 'accepted,declined', 'existing guests can still change their reply at the ceiling')
check(submit(token=guest_token(2), code='TST67890')['new_submission'] is True, 'existing guests can still suggest at the ceiling')
sql(f"SET ROLE service_role; INSERT INTO rsvps(group_id,guest_token,display_name) VALUES ('{group}','{guest_token(1)}','Guest');")
check(sql(f"SELECT count(*) FROM rsvps WHERE group_id='{group}' AND guest_token='{guest_token(1)}';") == '1', 'a full lunch does not block replies to another lunch')

# Retention: ledgers and closed reports 90 days; venue text 30 days after the lunch.
past, past_rsvp = str(uuid.uuid4()), str(uuid.uuid4())
sql(f"""INSERT INTO groups(id,host_id,host_name,name,scheduled_at,area_lat,area_lng,radius_km,invite_code,place_name,place_address,place_id)
VALUES ('{past}','{alice}','Sam','Past fictional lunch',now()-interval '31 days',-37,144,2,'TSTPAST1','Past cafe','1 Past Lane','past-place');
INSERT INTO rsvps(id,group_id,guest_token,display_name) VALUES ('{past_rsvp}','{past}','{guest_token(1)}','Guest');
INSERT INTO group_suggestions(group_id,rsvp_id,display_name,place_name,place_address,scheduled_at,note,status) VALUES
('{past}','{past_rsvp}','Guest','Past bistro','2 Past Lane',null,'Place only','declined'),
('{past}','{past_rsvp}','Guest','Past diner','3 Past Lane',now()-interval '31 days','Place and time','superseded');
INSERT INTO ai_requests(app_user_id,model,created_at) VALUES ('{alice}','fictional',now()-interval '91 days'),('{alice}','fictional',now()-interval '89 days');
INSERT INTO ai_reservations(request_id,app_user_id,day,created_at) VALUES (gen_random_uuid(),'{alice}',current_date-91,now()-interval '91 days');
INSERT INTO upstream_usage VALUES ('photos',current_date-91,5),('photos',current_date-89,5);
INSERT INTO caller_usage VALUES ('photos','{guest_token(3)}',current_date-91,5),('photos','{guest_token(3)}',current_date-89,5);
INSERT INTO revenuecat_events VALUES ('ancient',now()-interval '91 days');
INSERT INTO content_reports(group_id,reporter,target_kind,target_id,reason,evidence,status,created_at,reviewed_at) VALUES
('{past}','u:one','group','{past}','spam','{{}}','dismissed',now()-interval '120 days',now()-interval '91 days'),
('{past}','u:two','group','{past}','spam','{{}}','removed',now()-interval '120 days',now()-interval '89 days'),
('{past}','u:three','group','{past}','spam','{{}}','open',now()-interval '120 days',null);""")
current = "SELECT (SELECT count(*) FROM ai_reservations), (SELECT sum(ai_requests) FROM usage), (SELECT sum(requests) FROM upstream_usage WHERE day=current_date), (SELECT sum(requests) FROM caller_usage WHERE day=current_date), (SELECT count(*) FROM revenuecat_events), (SELECT count(*) FROM group_suggestions WHERE place_name IS NOT NULL);"
before = sql(current).split('|')
for run in ['first', 'repeated']:
    sql("SET ROLE service_role; SELECT run_daily_maintenance();")
    after = sql(current).split('|')
    check(after[1:4] == before[1:4], f'{run} maintenance keeps the current day quota, budget and caller counters')
    check([int(after[0]), int(after[4]), int(after[5])] == [int(before[0]) - 1, int(before[4]) - 1, int(before[5]) - 2], f'{run} maintenance keeps recent reservations, webhook receipts and current venue text')
    check(sql("SELECT string_agg(to_char(now()-created_at,'DD'),',') FROM ai_requests;") == '89', f'{run} maintenance removes AI request logs after 90 days')
    check(sql("SELECT string_agg((current_date-day)::text,',') FROM upstream_usage WHERE provider='photos';") == '89', f'{run} maintenance removes global budget days after 90 days')
    check(sql(f"SELECT string_agg((current_date-day)::text,',') FROM caller_usage WHERE caller_hash='{guest_token(3)}';") == '89', f'{run} maintenance removes caller days after 90 days')
    check(sql(f"SELECT string_agg(status,',' ORDER BY status) FROM content_reports WHERE group_id='{past}';") == 'open,removed', f'{run} maintenance removes only reports closed over 90 days ago')
    check(sql(f"SELECT place_id FROM groups WHERE id='{past}' AND place_name IS NULL AND place_address IS NULL;") == 'past-place', f'{run} maintenance clears venue text 30 days after a lunch and keeps the place ID')
    check(sql(f"SELECT string_agg(note,',') FROM group_suggestions WHERE group_id='{past}' AND place_name IS NULL AND place_address IS NULL;") == 'Place and time', f'{run} maintenance clears old suggested venues within the table constraints')
check(sql(f"SELECT place_name FROM groups WHERE id='{group}';") == 'Alternative cafe', 'maintenance keeps venue text for a current lunch')
for role in ['anon', 'authenticated']:
    check(sql(f"SELECT has_function_privilege('{role}', 'run_daily_maintenance()', 'EXECUTE');") == 'f', f'{role} cannot run maintenance')
check(sql("SELECT count(*) FROM pg_available_extensions WHERE name='pg_cron';") == '0', 'migrations apply where pg_cron is unavailable')
print('All invitation transaction checks passed (fictional data only).')
