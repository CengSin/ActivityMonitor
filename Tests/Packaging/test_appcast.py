"""Reject malformed, substituted, or incorrectly targeted updates before publication."""
import base64
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("appcast", ROOT / "scripts/verify-appcast.py")
appcast = importlib.util.module_from_spec(spec)
spec.loader.exec_module(appcast)


class AppcastTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.archive = Path(self.directory.name) / "test.zip"
        self.archive.write_bytes(b"archive")
        self.feed = Path(self.directory.name) / "appcast.xml"
        self.xml = f'''<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item>
<sparkle:version>1.9.0</sparkle:version><sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
<enclosure url="https://github.com/wieslawsoltes/ActivityMonitor/releases/download/v1.9.0/ActivityMonitor-1.9.0-universal.zip" length="7" sparkle:edSignature="{base64.b64encode(bytes(64)).decode()}"/>
</item></channel></rss>'''

    def validate(self, xml):
        self.feed.write_text(xml)
        appcast.validate(self.feed, self.archive, "1.9.0")

    def test_valid_metadata_still_requires_cryptographic_verification(self):
        with patch.object(appcast.subprocess, "run") as verify:
            self.validate(self.xml)
            self.assertEqual(verify.call_args.args[0][2], appcast.PUBLIC_KEY)
            self.assertTrue(verify.call_args.kwargs["check"])

    def test_reject_incorrect_url_version_size_os_and_missing_signature(self):
        for xml in [self.xml.replace("https://github.com", "https://example.com"),
                    self.xml.replace(">1.9.0<", ">1.9.1<"),
                    self.xml.replace('length="7"', 'length="8"'),
                    self.xml.replace(">14.0<", ">13.0<"),
                    self.xml.replace("edSignature", "unsigned")]:
            with self.subTest(xml=xml), self.assertRaises(ValueError):
                self.validate(xml)

    def test_reject_forged_archive_signature(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.validate(self.xml)


if __name__ == "__main__":
    unittest.main()
