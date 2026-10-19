"""Generate the build's Info.plist from its own public Google OAuth configuration.
Deriving the callback scheme from the client ID prevents Debug/Release mismatches.
No OAuth client secret belongs in the app.
"""
import os
import json
from pathlib import Path
import plistlib
import re


def with_google_defaults(config, public_config):
    # Only allow public identifiers from the shared defaults into the app's configuration.
    defaults = {key: public_config[key] for key in ("googleIosClientId", "googleServerClientId") if key in public_config}
    return {**defaults, **config}


def load_google_defaults():
    return json.loads((Path(__file__).resolve().parents[2] / "config/google-oauth.json").read_text())


def google_values(config):
    ios = config.get("googleIosClientId", "")
    server = config.get("googleServerClientId", "")
    pattern = r"[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com"
    if not re.fullmatch(pattern, ios) or not re.fullmatch(pattern, server):
        return None
    return ios, server, ".".join(reversed(ios.split(".")))


def generate(template, config):
    info = dict(template)
    values = google_values(config)
    if values:
        ios, server, scheme = values
        info["GIDClientID"] = ios
        info["GIDServerClientID"] = server
        info["CFBundleURLTypes"] = info.get("CFBundleURLTypes", []) + [
            {"CFBundleTypeRole": "Editor", "CFBundleURLSchemes": [scheme]}
        ]
    return info


if __name__ == "__main__":
    root = Path(os.environ["SRCROOT"])
    config_name = "Lunch.Release.plist" if os.environ["CONFIGURATION"] == "Release" else "Lunch.plist"
    config_path = root / "LunchApp/Config" / config_name
    config = plistlib.loads(config_path.read_bytes()) if config_path.exists() else {}
    config = with_google_defaults(config, load_google_defaults())
    info = generate(plistlib.loads((root / "LunchApp/Info.plist").read_bytes()), config)
    output = Path(os.environ["DERIVED_FILE_DIR"]) / "LunchInfo.plist"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(plistlib.dumps(info))
