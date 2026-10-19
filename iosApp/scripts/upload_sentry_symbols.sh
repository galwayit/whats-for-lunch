#!/bin/sh
# Upload dSYMs from the exact app/archive. This never uploads source context.
# Authentication belongs in SENTRY_AUTH_TOKEN (CI secret) or the ignored root .sentryclirc.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
if [ "$#" -ne 1 ]; then
  echo "Usage: sh iosApp/scripts/upload_sentry_symbols.sh /path/to/LunchApp.xcarchive-or-dSYM-directory" >&2
  exit 2
fi
symbols=$1
case "$symbols" in
  *.xcarchive) symbols="$symbols/dSYMs" ;;
esac
if [ ! -d "$symbols" ]; then
  echo "error: The debug-symbol directory does not exist." >&2
  exit 2
fi
# Reject empty directories instead of reporting a successful upload of zero symbols.
python3 - "$symbols" <<'PY'
import pathlib, sys
base = pathlib.Path(sys.argv[1]).resolve()
files = [p for p in base.rglob("*") if p.is_file() and "/Contents/Resources/DWARF/" in str(p)]
if not files:
    raise SystemExit("error: No dSYM DWARF files found; build with dwarf-with-dsym.")
PY
if [ -z "${SENTRY_AUTH_TOKEN:-}" ] && [ ! -f "$repo_root/.sentryclirc" ]; then
  echo "error: Set SENTRY_AUTH_TOKEN securely or configure the ignored root .sentryclirc." >&2
  exit 2
fi
if ! command -v sentry-cli >/dev/null 2>&1; then
  echo "error: Install the official sentry-cli before uploading debug symbols." >&2
  exit 2
fi
# Resolve a relative input before changing directory for sentry-cli's local config discovery.
symbols=$(CDPATH= cd -- "$symbols" && pwd)
cd "$repo_root"
exec sentry-cli debug-files upload --org iapp-do --project apple --no-sources --wait "$symbols"
