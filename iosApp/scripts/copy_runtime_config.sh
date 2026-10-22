#!/bin/sh
#
# @file copy_runtime_config.sh
# @description Xcode build phase "Copy runtime config": bundles the git-ignored runtime config as
#   Lunch.plist, picking the file by build configuration so a RevenueCat Test Store key used for
#   Debug can never reach a Release binary.
#     Debug   -> LunchApp/Config/Lunch.plist          (optional; demo builds run without it)
#     Release -> LunchApp/Config/Lunch.Release.plist  (required to archive; must hold an appl_ key)
#   LunchConfig.revenueCatKey(_:allowingTestStore:) repeats the key check at runtime.
# @author AI Assistant
# @date 2026-09-23
#
set -eu

config_dir="$SRCROOT/LunchApp/Config"
dest="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/Lunch.plist"

if [ "$CONFIGURATION" = "Release" ]; then
  src="$config_dir/Lunch.Release.plist"
else
  src="$config_dir/Lunch.plist"
fi

# Never leave a stale copy from an earlier build of the other configuration.
rm -f "$dest"

if [ ! -f "$src" ]; then
  if [ "$CONFIGURATION" = "Release" ]; then
    # ACTION is "install" when archiving: an unconfigured archive would fail App Review.
    if [ "${ACTION:-build}" = "install" ]; then
      echo "error: Archiving needs $src (copy Lunch.plist.example and fill in production values)."
      exit 1
    fi
    echo "warning: $src not found; this Release build will start in setup-required mode."
  fi
  exit 0
fi

if [ "$CONFIGURATION" = "Release" ]; then
  python3 "$SRCROOT/scripts/validate_release_config.py" --config "$src"
  key=$(/usr/libexec/PlistBuddy -c "Print :revenueCatApiKey" "$src" 2>/dev/null || true)
  case "$key" in
    appl_*) ;;
    *)
      echo "error: $src must hold a production RevenueCat Apple key (appl_...). Test Store (test_) keys never charge."
      exit 1
      ;;
  esac
fi

cp "$src" "$dest"
