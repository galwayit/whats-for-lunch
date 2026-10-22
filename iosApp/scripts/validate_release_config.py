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


def load(path):
    try:
        return plistlib.loads(Path(path).read_bytes())
    except (OSError, ValueError, plistlib.InvalidFileException):
        raise ValueError(f"Missing or invalid configuration file: {path}") from None


def validate(config):
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    args = parser.parse_args()
    try:
        validate(with_google_defaults(load(args.config), load_google_defaults()))
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
    print("Release configuration structure verified; live provider checks are still required.")
