# Static web assets

- `invite/index.html` — the `/i/<code>` landing page. Set `data-functions-url`, `data-anon-key` and the store links on the `<main>` element before deploying. It calls `GET /invitations` and `POST /invitations-respond` and keeps the returned `guestToken` in `localStorage` (sent back as `x-guest-token`).
- `.well-known/apple-app-site-association` — replace `APPLE_TEAM_ID_PLACEHOLDER`. Must be served as `application/json` with no redirect at `https://<domain>/.well-known/apple-app-site-association`.
- `.well-known/assetlinks.json` — replace the SHA-256 placeholder with the Play App Signing certificate fingerprint (Play Console -> App integrity).

Hosting must rewrite `/i/*` to `invite/index.html`. Examples are in `backend/README.md`.
