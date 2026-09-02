#!/usr/bin/env bash
# Fails when a screen or component file declares a colour literal instead of using the tokens.
# Allowed: the generated token files and the Android XML theme resources (launch background).
set -euo pipefail
cd "$(dirname "$0")/.."
status=0

# Android: Color(0x...) anywhere under ui/ except the generated Tokens.kt and Theme.kt (which maps tokens to Material).
if [ -d androidApp/src/main/kotlin/au/iapp/lunch ]; then
  hits=$(grep -rnE "Color\(0[xX][0-9A-Fa-f]{6,8}\)" androidApp/src/main/kotlin --include='*.kt' \
    | grep -vE "ui/theme/(Tokens|Theme)\.kt" || true)
  if [ -n "$hits" ]; then echo "Android literal colours:"; echo "$hits"; status=1; fi
fi

# iOS: Color(red:, UIColor(red:, or hex helpers outside DesignSystem/Tokens.swift.
if [ -d iosApp/LunchApp ]; then
  hits=$(grep -rnE "Color\(red:|UIColor\(red:|Color\(hex|\"#[0-9A-Fa-f]{6}\"" iosApp/LunchApp --include='*.swift' \
    | grep -vE "DesignSystem/Tokens\.swift" || true)
  if [ -n "$hits" ]; then echo "iOS literal colours:"; echo "$hits"; status=1; fi
fi

if [ $status -eq 0 ]; then echo "No literal colours outside token files."; fi
exit $status
