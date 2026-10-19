import unittest
from generate_auth_info import generate, with_google_defaults


class AuthInfoTests(unittest.TestCase):
    def test_shared_defaults_supply_only_public_identifiers(self):
        merged = with_google_defaults({}, {
            "googleIosClientId": "12345-ios.apps.googleusercontent.com",
            "googleServerClientId": "12345-web.apps.googleusercontent.com",
            "clientSecret": "fixture-never-bundle",
        })
        self.assertNotIn("clientSecret", merged)
        self.assertEqual(generate({}, merged)["GIDClientID"], "12345-ios.apps.googleusercontent.com")

    def test_build_specific_values_override_shared_defaults(self):
        defaults = {"googleIosClientId": "12345-ios.apps.googleusercontent.com", "googleServerClientId": "12345-web.apps.googleusercontent.com"}
        merged = with_google_defaults({"googleIosClientId": "67890-ios.apps.googleusercontent.com", "googleServerClientId": "67890-web.apps.googleusercontent.com"}, defaults)
        self.assertEqual(generate({}, merged)["CFBundleURLTypes"][0]["CFBundleURLSchemes"], ["com.googleusercontent.apps.67890-ios"])
        # An explicit empty override is invalid; it must not quietly activate another project.
        self.assertNotIn("GIDClientID", generate({}, with_google_defaults({"googleIosClientId": ""}, defaults)))

    def test_generates_matching_callback_and_server_audience(self):
        info = generate({"CFBundleIdentifier": "au.iapp.lunch"}, {
            "googleIosClientId": "12345-ios.apps.googleusercontent.com",
            "googleServerClientId": "12345-web.apps.googleusercontent.com",
        })
        self.assertEqual(info["CFBundleURLTypes"][0]["CFBundleURLSchemes"], ["com.googleusercontent.apps.12345-ios"])
        self.assertEqual(info["GIDServerClientID"], "12345-web.apps.googleusercontent.com")

    def test_incomplete_config_cannot_register_a_broken_callback(self):
        info = generate({}, {"googleIosClientId": "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com"})
        self.assertNotIn("CFBundleURLTypes", info)
        self.assertNotIn("GIDClientID", info)

    def test_preserves_existing_url_handlers(self):
        existing = {"CFBundleURLSchemes": ["lunch-existing"]}
        info = generate({"CFBundleURLTypes": [existing]}, {
            "googleIosClientId": "12345-ios.apps.googleusercontent.com", "googleServerClientId": "12345-web.apps.googleusercontent.com",
        })
        self.assertEqual(info["CFBundleURLTypes"][0], existing)


if __name__ == "__main__":
    unittest.main()
