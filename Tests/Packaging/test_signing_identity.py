"""Reject missing, invalid or ambiguous signing identities without Apple credentials."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("identity", Path(__file__).resolve().parents[2] /
                                            "scripts/resolve-signing-identity.py")
identity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(identity)


class SigningIdentityTests(unittest.TestCase):
    name = "Developer ID Application: Test É (TEAM123456)"
    fingerprint = "A" * 40

    def listing(self, name=None):
        return f'  1) {self.fingerprint} "{name or self.name}"\n     1 valid identities found\n'

    def test_resolves_exact_identity(self):
        self.assertEqual(identity.resolve(self.listing(), self.name), self.fingerprint)

    def test_resolves_equivalent_unicode_name(self):
        self.assertEqual(identity.resolve(self.listing(), self.name.replace("É", "E\u0301")), self.fingerprint)

    def test_rejects_missing_identity(self):
        with self.assertRaises(ValueError):
            identity.resolve("     0 valid identities found\n", self.name)

    def test_rejects_wrong_name_or_team(self):
        with self.assertRaises(ValueError):
            identity.resolve(self.listing(), self.name.replace("TEAM123456", "OTHER12345"))

    def test_rejects_ambiguous_identity(self):
        with self.assertRaises(ValueError):
            identity.resolve(self.listing() * 2, self.name)

    def test_rejects_development_certificate(self):
        name = "Apple Development: Test (TEAM123456)"
        with self.assertRaises(ValueError):
            identity.resolve(self.listing(name), name)
