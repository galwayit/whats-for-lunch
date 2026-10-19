"""Exercise symbol upload guards with a fake CLI; never contacts Sentry."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("upload_sentry_symbols.sh").resolve()


class SentrySymbolUploadTests(unittest.TestCase):
    def test_empty_directory_is_rejected_before_cli_runs(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(["sh", str(SCRIPT), tmp], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("No dSYM DWARF files found", result.stderr)

    def test_upload_selects_archive_symbols_and_never_uploads_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive = root / "Lunch App.xcarchive"
            symbols = archive / "dSYMs"
            dwarf = symbols / "LunchApp.app.dSYM/Contents/Resources/DWARF/LunchApp"
            dwarf.parent.mkdir(parents=True)
            dwarf.write_bytes(b"fictional-symbol-file")
            cli = root / "sentry-cli"
            output = root / "arguments.txt"
            cli.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$FAKE_SENTRY_ARGUMENTS"\n')
            cli.chmod(0o700)
            env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                       SENTRY_AUTH_TOKEN="fictional-test-token", FAKE_SENTRY_ARGUMENTS=str(output))
            result = subprocess.run(["sh", str(SCRIPT), str(archive)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            arguments = output.read_text().splitlines()
            self.assertEqual(arguments[:-1], [
                "debug-files", "upload", "--org", "iapp-do", "--project", "apple", "--no-sources", "--wait"
            ])
            self.assertEqual(Path(arguments[-1]).resolve(), symbols.resolve())
            self.assertNotIn("fictional-test-token", result.stdout + result.stderr + output.read_text())

    def test_missing_path_is_an_actionable_error(self):
        result = subprocess.run(["sh", str(SCRIPT), "/does-not-exist/Lunch.xcarchive"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("directory does not exist", result.stderr)


if __name__ == "__main__":
    unittest.main()
