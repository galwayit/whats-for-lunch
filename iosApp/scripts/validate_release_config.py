"""Validate the release configuration without printing any credential values.
This is a structural archive gate, not proof of provider acceptance.
"""
import argparse
import base64
import json
from pathlib import Path
import plistlib
import sys
from generate_auth_info import google_values, load_google_defaults, with_google_defaults

PROJECT = "cswdcbmywzzisovsgwac"
BUNDLE = "au.iapp.lunch"


def load(path):
    try:
        return plistlib.loads(Path(path).read_bytes())
    except (OSError, ValueError, plistlib.InvalidFileException):
        raise ValueError(f"Missing or invalid configuration file: {path}") from None


def validate(config, firebase=None):
    expected = {
        "supabaseUrl": f"https://{PROJECT}.supabase.co",
        "backendBaseUrl": f"https://{PROJECT}.supabase.co/functions/v1",
        "inviteLinkBase": "https://lunch.iapp.au/i/",
    }
    for field, value in expected.items():
        if config.get(field) != value:
            raise ValueError(f"{field} must match this app's production project")
    key = config.get("revenueCatApiKey", "")
    if not key.startswith("appl_") or len(key) < 15 or any(x in key.lower() for x in ["your", "example", "placeholder", "test"]):
        raise ValueError("revenueCatApiKey must be the real RevenueCat Apple public SDK key")
    anon = config.get("supabaseAnonKey", "")
    if anon.startswith("sb_publishable_") and len(anon) > 25:
        pass
    else:
        try:
            part = anon.split(".")[1]
            claims = json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))
        except (IndexError, ValueError):
            raise ValueError("supabaseAnonKey must be a public client key") from None
        if claims.get("role") != "anon" or claims.get("ref") != PROJECT:
            raise ValueError("supabaseAnonKey must be this project's anon key; never embed a server key")
    if google_values(config) is None:
        raise ValueError("Google sign-in needs real iOS and Web OAuth client IDs in the release config")
    if firebase is not None:
        if firebase.get("BUNDLE_ID") != BUNDLE or not firebase.get("GOOGLE_APP_ID") or not firebase.get("PROJECT_ID"):
            raise ValueError("GoogleService-Info.plist must belong to the Lunch iOS app")
        if firebase.get("IS_GCM_ENABLED") is not True:
            raise ValueError("Firebase Cloud Messaging must be enabled for the release")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--firebase")
    args = parser.parse_args()
    try:
        validate(with_google_defaults(load(args.config), load_google_defaults()), load(args.firebase) if args.firebase else None)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
    print("Release configuration structure verified; live provider checks are still required.")
