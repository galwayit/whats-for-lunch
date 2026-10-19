"""Fictional data; runs migration/invitation checks first in the disposable DB."""
import json
import uuid
from invitation_regression import sql, check, denied, alice, bob

g, rsvp = str(uuid.uuid4()), str(uuid.uuid4())
token = 'e' * 64
sql(f"""INSERT INTO groups(id,host_id,host_name,name,scheduled_at,area_lat,area_lng,radius_km,invite_code)
VALUES ('{g}','{alice}','Sam','Safety test',now()+interval '3 days',-37,144,2,'SAFE1234');
INSERT INTO rsvps(id,group_id,guest_user_id,display_name) VALUES ('{rsvp}','{g}','{bob}','Guest');""")

def action(user, target, target_id, kind='report_block', reason='harassment', guest='null'):
    return sql(f"SET ROLE service_role; SELECT group_safety_action('SAFE1234',{user},{guest},'{target}',{target_id},'{kind}','{reason}');")

def context(user='null', guest='null'):
    return json.loads(sql(f"SET ROLE service_role; SELECT group_safety_context('{g}',{user},{guest});"))

for role in ['anon', 'authenticated']:
    for table in ['content_reports', 'content_blocks']:
        denied(f'SET ROLE {role}; SELECT * FROM {table};', f'{role} cannot read private {table}')
    for fn in ['group_safety_action(text,uuid,text,text,uuid,text,text)', 'review_content_report(uuid,boolean)', 'group_safety_context(uuid,uuid,text,boolean)']:
        check(sql(f"SELECT has_function_privilege('{role}', '{fn}', 'EXECUTE');") == 'f', f'{role} cannot impersonate service through {fn}')

denied(f"SET ROLE service_role; SELECT group_safety_action('SAFE1234','{alice}',null,'group',null,'block','other');", 'cannot block self')
denied(f"SET ROLE service_role; SELECT group_safety_action('SAFE1234','{alice}',null,'rsvp','{uuid.uuid4()}','report','other');", 'cannot report a target outside the invitation')
sql(f"UPDATE groups SET cancelled_at=now() WHERE id='{g}';")
check(sql(f"SET ROLE service_role; SELECT group_safety_context('{g}','{bob}',null) IS NULL;") == 't', 'cancelled invitation stays unavailable to readers')
check(json.loads(sql(f"SET ROLE service_role; SELECT group_safety_context('{g}','{bob}',null,true);"))['allowed'] is True, 'cancellation notification can still check safety after cancelling')
sql(f"UPDATE groups SET cancelled_at=null WHERE id='{g}';")
report = action(f"'{alice}'", 'rsvp', f"'{rsvp}'")
check(action(f"'{alice}'", 'rsvp', f"'{rsvp}'") == report, 'duplicate report is idempotent')
check(rsvp in context(f"'{alice}'")['hiddenRsvpIds'], 'host immediately hides blocked guest')
check(context(f"'{bob}'")['allowed'] is False, 'blocked user cannot reopen host invitation')
check(json.loads(sql(f"SET ROLE service_role; SELECT group_safety_context('{g}','{bob}',null,true);"))['allowed'] is False, 'notification context still excludes a blocked recipient')
check(sql(f"SET ROLE authenticated; SET request.jwt.claim.sub='{bob}'; SELECT count(*) FROM groups WHERE id='{g}';") == '0', 'blocking enforced for direct RLS group reads')
check(sql(f"SET ROLE authenticated; SET request.jwt.claim.sub='{alice}'; SELECT count(*) FROM rsvps WHERE id='{rsvp}';") == '0', 'blocked guest hidden in direct host RSVP reads')
denied(f"SET ROLE service_role; UPDATE rsvps SET status='accepted' WHERE id='{rsvp}';", 'blocked identity cannot send a new RSVP')
denied(f"SET ROLE service_role; SELECT submit_group_suggestion('SAFE1234','{bob}',null,'Guest','Cafe',null,null,null);", 'blocked identity cannot suggest via service RPC')
sql(f"SET ROLE service_role; UPDATE rsvps SET status='pending' WHERE group_id='{g}';")
check(True, 'host plan changes can reset replies without failing on blocked guests')
evidence = json.loads(sql(f"SELECT evidence FROM content_reports WHERE id='{report}';"))
check(evidence == {'displayName':'Guest'}, 'report evidence excludes guest capability and account identifiers')
sql(f"SET ROLE service_role; SELECT review_content_report('{report}',true);")
check(sql(f"SELECT moderated_at IS NOT NULL FROM rsvps WHERE id='{rsvp}';") == 't', 'operator can remove reported guest content')

anon_report = action('null', 'group', 'null', guest=f"'{token}'")
check(context(guest=f"'{token}'")['allowed'] is False, 'anonymous viewer can block host without an RSVP')
check(context()['allowed'] is True, 'anonymous block does not remove group for unrelated viewers')
sql(f"SET ROLE service_role; SELECT review_content_report('{anon_report}',true);")
check(context()['allowed'] is False, 'operator removal hides group even from anonymous API reads')
check(sql(f"SET ROLE authenticated; SET request.jwt.claim.sub='{alice}'; SELECT count(*) FROM groups WHERE id='{g}';") == '0', 'operator removal also hides direct RLS reads')
sql(f"DELETE FROM auth.users WHERE id='{bob}';")
check(sql(f"SELECT count(*) FROM content_blocks WHERE blocked='u:{bob}' OR blocker='u:{bob}';") == '0', 'account deletion removes block identities')
check(sql(f"SELECT count(*) FROM content_reports WHERE target_id='{rsvp}';") == '0', 'account deletion removes snapshots of reported guest content')

# A removed author's accepted suggestion must not survive in the group's plan.
g2 = str(uuid.uuid4())
sql(f"INSERT INTO groups(id,host_id,host_name,name,scheduled_at,area_lat,area_lng,radius_km,invite_code) VALUES ('{g2}','{alice}','Sam','Reported plan',now()+interval '3 days',-37,144,2,'SAFE5678');")
suggestion = json.loads(sql(f"SET ROLE service_role; SELECT submit_group_suggestion('SAFE5678',null,repeat('f',64),'Guest','Reported cafe',null,null,null);"))
sql(f"SET ROLE service_role; SELECT review_group_suggestion('{g2}','{suggestion['id']}','{alice}',true);")
author_report = sql(f"SET ROLE service_role; SELECT group_safety_action('SAFE5678','{alice}',null,'rsvp','{suggestion['rsvp_id']}','report','other');")
sql(f"SET ROLE service_role; SELECT review_content_report('{author_report}',true);")
check(sql(f"SELECT moderated_at IS NOT NULL FROM groups WHERE id='{g2}';") == 't', 'removing an author also hides the accepted plan containing their content')
print('All content safety checks passed.')
