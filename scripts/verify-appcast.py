#!/usr/bin/env python3
"""Reject feed mistakes or an archive signed with a key different from the app's key."""
from pathlib import Path
import base64
import subprocess
import sys
import xml.etree.ElementTree as ET

PUBLIC_KEY = "LSbDjvx0CrpFJpSBbNtUeB9JqgqrHzAjeF6NbgtwGAk="
SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"


def validate(feed, archive, version):
    items = ET.parse(feed).findall("./channel/item")
    if len(items) != 1:
        raise ValueError("Expected exactly one release")
    item = items[0]
    enclosure = item.find("enclosure")
    expected = f"https://github.com/wieslawsoltes/ActivityMonitor/releases/download/v{version}/ActivityMonitor-{version}-universal.zip"
    if enclosure is None or enclosure.get("url") != expected:
        raise ValueError("Incorrect update URL")
    if item.findtext(SPARKLE + "version") != version:
        raise ValueError("Incorrect update version")
    if item.findtext(SPARKLE + "minimumSystemVersion") != "14.0":
        raise ValueError("Incorrect minimum macOS version")
    if int(enclosure.get("length", "0")) != Path(archive).stat().st_size:
        raise ValueError("Incorrect archive size")
    signature = enclosure.get(SPARKLE + "edSignature", "")
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise ValueError("Missing or invalid signature")
    subprocess.run(["swift", str(Path(__file__).with_name("verify-update-signature.swift")),
                    PUBLIC_KEY, signature, str(archive)], check=True)


if __name__ == "__main__":
    validate(*sys.argv[1:])
    print("Update feed URL, version, size and EdDSA archive signature verified.")
