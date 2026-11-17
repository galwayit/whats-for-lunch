# Runbook

One page for release day and for the first weeks after launch. It gives the order of the steps
and the command for each; the linked documents hold the detail. Run every command from the
repository root unless the step says otherwise.

## 1. Make the App Store build

Before you start: `Lunch.Release.plist` exists with the `appl_` RevenueCat key, Xcode is signed
in to team `RYM9BD2B27`, `sentry-cli` is installed, and CI is green on the commit.

1. Set the build number. `CURRENT_PROJECT_VERSION` in `iosApp/LunchApp.xcodeproj/project.pbxproj`
   must be higher than every build already uploaded. Commit the change.
2. Tag the commit. The tag is how the submitted build is found again.

   ```sh
   git tag -a ios-1.0.0-10 -m "iOS 1.0.0 (10)" && git push origin ios-1.0.0-10
   ```

3. Archive. The build phase "Copy runtime config" stops the archive when the Release config is
   missing or holds a Test Store key.

   ```sh
   xcodebuild -project iosApp/LunchApp.xcodeproj -scheme LunchApp -configuration Release \
     -destination 'generic/platform=iOS' -archivePath build/ios/LunchApp-1.0.0-10.xcarchive \
     -allowProvisioningUpdates archive
   ```

4. Inspect the archive before it leaves the Mac.

   ```sh
   APP=build/ios/LunchApp-1.0.0-10.xcarchive/Products/Applications/LunchApp.app
   codesign -d --entitlements - "$APP"      # only Sign in with Apple and applinks:lunch.iapp.au
   /usr/libexec/PlistBuddy -c "Print :revenueCatApiKey" "$APP/Lunch.plist" | cut -c1-5   # appl_
   ```

   In Xcode Organizer, choose the archive and "Generate Privacy Report". The App Privacy answers
   in App Store Connect come from that report (`design/store-listing.md`).
5. Export and upload.

   ```sh
   xcodebuild -exportArchive -archivePath build/ios/LunchApp-1.0.0-10.xcarchive \
     -exportOptionsPlist iosApp/ExportOptions.plist -exportPath build/ios/export \
     -allowProvisioningUpdates
   ```

   Upload `build/ios/export/LunchApp.ipa` with Transporter, or use Organizer → Distribute App.
6. Upload the debug symbols of this exact archive ([SENTRY_SETUP.md](SENTRY_SETUP.md)).

   ```sh
   sh iosApp/scripts/upload_sentry_symbols.sh "$PWD/build/ios/LunchApp-1.0.0-10.xcarchive"
   ```

7. Record the tag, the commit and the build number under `release-evidence/<date>/`.

CI builds with Xcode 26.6 because the GitHub `macos-26` image has no Xcode 27. The archive is
built on this Mac with Xcode 27.x. Apple accepts both; move the CI pin in
`.github/workflows/ci.yml` when the image gains Xcode 27.

## 2. Deploy the backend

Detail: [backend/README.md](backend/README.md), section "Coordinated deployment".

```sh
cd backend
supabase migration list                    # confirm the linked project is `lunch`
supabase db push --dry-run --skip-vault    # read the exact SQL first
supabase db push --skip-vault              # migrations first: the Places functions need them
make deploy-functions                      # always all functions: they share `_shared/`
```

- After the first deploy with the per-caller limit, confirm that callers are told apart and
  that the daily maintenance job is scheduled. Both checks are in `backend/README.md`, section
  "Scheduled maintenance and per-caller limits".

- Never run `make secrets` or `supabase config push`. The first pushes the wrong file. The
  second overwrites the hosted sign-in settings and has no dry run. Secrets go in with
  `supabase secrets set`, as the header of `backend/supabase/.env.phase1` shows.
- Roll back functions by deploying them again from the previous tag in a separate worktree:
  `git worktree add ../lunch-rollback <tag>`, then `make deploy-functions` there.
- Migrations only go forward. Fix a bad migration with a new one. Take a database backup
  before each `db push`.
- The website is separate: `wrangler pages deploy backend/web --project-name lunch --branch main`
  ([backend/web/README.md](backend/web/README.md)). Deploy it after the backend, because the
  privacy page describes the retention that the migrations introduce. Then compare the live
  privacy and terms pages with the repository copies.

## 3. Emergency switches

| Problem | Action |
|---|---|
| AI provider outage, bad answers or runaway cost | Set `enabled` to `false` in the AI settings row ([backend/AI_PROVIDERS.md](backend/AI_PROVIDERS.md), "Validate, update and roll back"). The app shows its "AI is unavailable" state. No app release is needed. |
| Google Places cost or abuse | Lower the global limits `PLACES_DAILY_REQUEST_LIMIT` (default 1000) and `PHOTOS_DAILY_REQUEST_LIMIT` (3000), or the limits for one caller `PLACES_CALLER_DAILY_REQUEST_LIMIT` (200) and `PHOTOS_CALLER_DAILY_REQUEST_LIMIT` (1000), with `supabase secrets set`. Discover shows "try again later" when a limit is reached; limits reset at 00:00 UTC. |
| A bad app build is live | In App Store Connect, remove the version from sale or submit the previous tag with a higher build number. Subscriptions stay valid. |
| Purchases do not unlock Lunch Pro | Check `supabase secrets list` for `REVENUECAT_PRO_PRODUCT_IDS` and `REVENUECAT_ALLOW_APPLE_SANDBOX`, then the RevenueCat webhook log and the `revenuecat-webhook` function log. |

## 4. Watch

Daily in launch week, then weekly:

- Sentry project `iapp-do/apple`: new issues and crash-free rate. Set one alert rule that emails
  hello@iapp.au for a new issue and for a crash-free rate under 99%.
- Supabase → Logs → Edge Functions: 5xx responses and `RATE_LIMITED` counts.
- RevenueCat overview: new subscriptions against webhook deliveries.
- Provider spend: Google Cloud (Places, Gemini) and OpenAI, against the budget alerts.

## 5. Moderation and support

Reports from invitations wait in `content_reports`. Review open reports at least every two
business days, which is what the support page promises. The query and the review function are in
[backend/MODERATION.md](backend/MODERATION.md). Support mail arrives at hello@iapp.au.

## 6. Restore

- Database: Supabase dashboard → Database → Backups. Point-in-time recovery needs the Pro plan
  with the PITR add-on; without it, restore the latest daily backup.
- After a restore, check the AI settings row before turning traffic back on: a restore to a
  time before the row was written leaves AI disabled.
- The meal journal lives only on each phone. A backend restore neither loses nor recovers it.
