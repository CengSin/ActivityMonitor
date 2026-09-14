#!/usr/bin/env python3
"""Resolve the configured identity to a fingerprint without logging credential data."""
import os
import re
import sys
import unicodedata


def resolve(identities, requested):
    normalize = lambda value: unicodedata.normalize("NFC", value)
    matches = [fingerprint for fingerprint, name in
               re.findall(r'^\s*\d+\) ([A-Fa-f0-9]{40}) "([^"]+)"\s*$', identities, re.MULTILINE)
               if name.startswith("Developer ID Application:") and normalize(name) == normalize(requested)]
    if len(matches) != 1:
        raise ValueError("Expected one valid identity matching DEVELOPER_ID_IDENTITY in the imported keychain. "
                         "Check that the P12 includes its certificate and private key, the certificate is valid, "
                         "and the configured identity matches its full name.")
    return matches[0]


if __name__ == "__main__":
    try:
        print(resolve(sys.stdin.read(), os.environ["DEVELOPER_ID_IDENTITY"]))
    except (KeyError, ValueError) as error:
        sys.exit(str(error))
