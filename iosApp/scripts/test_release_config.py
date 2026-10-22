"""Archive configuration security checks; fixtures never contact a provider."""
import base64
import json
import unittest
from validate_release_config import PROJECT, validate


def jwt(role="anon", project=PROJECT):
    payload = base64.urlsafe_b64encode(json.dumps({"role": role, "ref": project}).encode()).decode().rstrip("=")
    return "fixture." + payload + ".unsigned"


class ReleaseConfigTests(unittest.TestCase):
    def setUp(self):
        self.config = {
            "supabaseUrl": f"https://{PROJECT}.supabase.co",
            "backendBaseUrl": f"https://{PROJECT}.supabase.co/functions/v1",
            "inviteLinkBase": "https://lunch.iapp.au/i/",
            "revenueCatApiKey": "appl_1234567890abcdef",
            "supabaseAnonKey": jwt(),
            "googleIosClientId": "12345-ios.apps.googleusercontent.com",
            "googleServerClientId": "12345-web.apps.googleusercontent.com",
        }

    def test_matching_public_config_passes_structure_only(self):
        validate(self.config)

    def test_google_missing_config_is_rejected(self):
        self.config.pop("googleIosClientId")
        with self.assertRaises(ValueError):
            validate(self.config)

    def test_test_store_cannot_be_archived(self):
        self.config["revenueCatApiKey"] = "test_1234567890abcdef"
        with self.assertRaises(ValueError):
            validate(self.config)

    def test_service_role_key_cannot_be_embedded(self):
        self.config["supabaseAnonKey"] = jwt(role="service_role")
        with self.assertRaises(ValueError):
            validate(self.config)

    def test_another_projects_anon_key_is_rejected(self):
        self.config["supabaseAnonKey"] = jwt(project="another-project")
        with self.assertRaises(ValueError):
            validate(self.config)

    def test_another_backend_is_rejected(self):
        self.config["backendBaseUrl"] = "https://elsewhere.example/functions/v1"
        with self.assertRaises(ValueError):
            validate(self.config)


if __name__ == "__main__":
    unittest.main()
