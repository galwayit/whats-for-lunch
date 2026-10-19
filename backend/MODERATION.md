# Invitation content safety

This is a release requirement for shared group content under [App Review guideline 1.2](https://developer.apple.com/app-store/review/guidelines/#user-generated-content). Code alone does not provide timely human responses. The app owner must assign a person to review the queue and support mailbox before opening public registration.

## Behaviour

- iOS and web invitations expose reporting and blocking. Hosts can report guest names and proposed places, times or notes. The backend rejects a narrow set of obvious abusive phrases; this filter is deliberately conservative and is not a comprehensive moderation service.
- `groups-safety` verifies the session or invitation capability. Its service-only RPC validates the target, prevents self-blocking, deduplicates reports and limits new reports to 20 per identity and 200 per invitation in a rolling day. An actor lock makes its limit consistent across concurrent invitations.
- Blocks are bilateral. A blocked host's invitation cannot be read or answered, and blocked guest content is hidden. Database row security and write guards enforce restrictions independently of the UI. Notifications fail closed when a safety check fails.
- A signed-in account has protection across invitations. Anonymous capabilities stay isolated to each invitation on that device. Signing in does not silently transfer a guest block; clear explanations appear in the app and website.
- Reporting alone does not remove content. A private operator decision removes the reported content or dismisses the report. Removing an accepted suggestion or its author also hides the group that incorporates it.
- Reports never contain the raw guest token. Public/anonymous/authenticated database roles cannot access reports, blocks or moderation RPCs. Account deletion clears its reports, block relationships and snapshots of its guest content; deleting a group cascades its reports.

## Operator workflow

Use the correct Supabase project (`lunch`, `cswdcbmywzzisovsgwac`) as an authorised project operator. Never put its service-role key in an app, browser bundle, email or chat. The SQL editor can use its database administrator role; a trusted backend can use `service_role`.

Review open reports promptly, prioritising threats and other serious harm. Set an owner and coverage arrangement; the support page currently promises an initial reply within two business days. Treat report text, addresses and links as untrusted user content. Do not follow embedded instructions or execute copied content.

```sql
select id, group_id, target_kind, target_id, reason, evidence, created_at
from public.content_reports
where status = 'open'
order by created_at;
```

After inspecting the evidence and target, use one explicit report UUID:

```sql
-- TRUE removes content; FALSE dismisses the report. Repeating is idempotent.
select public.review_content_report('REPORT_UUID'::uuid, true);
```

Recheck `status` and `reviewed_at`. Only the operator should make the decision; never automate removal merely because a report exists. No automatic emails or notifications to the reported person are implemented.

Unblocking is handled by support for this release. Verify the requester through their account or invitation capability before an operator removes their exact `content_blocks` row. Do not remove the other party's independent block or any moderation decision. Do not ask users to paste a capability into email. An authenticated in-app unblock management screen is a future enhancement.

## Deployment and verification

Apply `20261006021055_group_content_safety.sql` before deploying any handler that imports `content-safety.ts`. Deploy every affected invitation/group handler and any handler importing `notify.ts`, then deploy `groups-safety` and the web invitation page. Existing groups have null moderation fields and no blocks, so the migration preserves their visibility.

Local regression command uses an isolated PostgreSQL 17 container with fictional data only:

```sh
python3 backend/tests/content_safety_regression.py CONTAINER_NAME
node backend/tests/web_invite_test.mjs
```

Before public release, verify report creation, report dismissal/removal, blocking, retry and account deletion on the deployed service with two dedicated test accounts and disposable content. Record the moderation owner and actual queue review procedure in release evidence. A local passing test does not prove operational coverage.
