# Static web assets

- `index.html`, `privacy/`, `support/`, and `terms/` provide the public App Store and support pages.
- `invite/index.html` — the `/i/<code>` landing page. Set `data-functions-url`, `data-anon-key` and the store links on the `<main>` element before enabling invitations. It calls `GET /invitations`, `POST /invitations-respond`, and `POST /invitations-suggest` and keeps the returned `guestToken` in `localStorage` (sent back as `x-guest-token`). Placeholder configuration fails closed with a service-unavailable message.
- `.well-known/apple-app-site-association` — configured for Team ID `RYM9BD2B27` and bundle ID `au.iapp.lunch`. It must be served as `application/json` with no redirect at `https://lunch.iapp.au/.well-known/apple-app-site-association`.
- `.well-known/assetlinks.json` — replace the SHA-256 placeholder with the Play App Signing certificate fingerprint (Play Console -> App integrity).

Cloudflare Pages reads `_redirects` for `/i/*` and `_headers` for content types and security headers. Do not consider invitations production-ready until the Supabase URL/key and final store links have replaced the placeholders.

## Deploying

Cloudflare Pages project `lunch` (account ray2ding@gmail.com, direct upload, production branch
`main`), serving `lunch.iapp.au` and `lunch-7a6.pages.dev`. From the repo root, logged in with
`wrangler login` to that account:

```sh
wrangler pages deploy backend/web --project-name lunch --branch main
```

Test locally first with `wrangler pages dev backend/web --port 8788`, which applies `_redirects` and
`_headers` like production. Rewrites must target `/invite/`, never `/invite/index.html`: Pages
redirects `*/index.html` to the directory URL, and a 200 rewrite onto a redirecting path silently
falls back to the home page. Cloudflare's email obfuscation rewrites `mailto:` links on the live
pages, so a byte diff against this folder always shows those lines.

The invite page carries the `lunch` Supabase functions URL and anon key (public by design) and a
Smart App Banner for App Store id 6808090102 (`au.iapp.lunch`), which only appears once 1.0 is live.

The invitation shows the host, per-person budget, who pays and payment method. Guests can propose a place/time for host review; refreshing the link shows the latest plan and their suggestion status. Roll out the matching group-planning migration/functions before publishing this page.

Invitations also call `POST /groups-safety` for reporting and blocking. Deploy the content-safety migration and handlers before publishing those controls. An initial invitation GET can issue a guest token before an RSVP; the page must still collect a name for that first reply. Capabilities remain scoped to one invitation in localStorage. See `../MODERATION.md` for human review and operational requirements.
