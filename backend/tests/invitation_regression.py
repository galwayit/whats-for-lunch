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
print('All invitation transaction checks passed (fictional data only).')
