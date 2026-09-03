# Static web assets

- `index.html`, `privacy/`, `support/`, and `terms/` provide the public App Store and support pages.
- `invite/index.html` — the `/i/<code>` landing page. Set `data-functions-url`, `data-anon-key` and the store links on the `<main>` element before enabling invitations. It calls `GET /invitations` and `POST /invitations-respond` and keeps the returned `guestToken` in `localStorage` (sent back as `x-guest-token`). Placeholder configuration fails closed with a service-unavailable message.
- `.well-known/apple-app-site-association` — configured for Team ID `RYM9BD2B27` and bundle ID `au.iapp.lunch`. It must be served as `application/json` with no redirect at `https://lunch.iapp.au/.well-known/apple-app-site-association`.
- `.well-known/assetlinks.json` — replace the SHA-256 placeholder with the Play App Signing certificate fingerprint (Play Console -> App integrity).

Cloudflare Pages reads `_redirects` for `/i/*` and `_headers` for content types and security headers. Do not consider invitations production-ready until the Supabase URL/key and final store links have replaced the placeholders.
