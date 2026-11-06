#!/usr/bin/env python3
"""Fails if a built Runner.app lost its Siri translations.

    python3 tool/check_siri_bundle.py build/ios/iphonesimulator/Runner.app

Reads the built app, not the source: a file can be in the repo and still not
reach the bundle. Xcode compiles .strings to binary plists, so they are read as
plists; plutil handles the text form where it exists.
"""
import plistlib
import subprocess
import sys
from pathlib import Path

LANGUAGES = ("en", "tr", "fr")
TABLES = ("AppShortcuts", "Localizable", "InfoPlist")
PHRASES = 30  # ten shortcuts, three phrases each


def read(path):
    data = path.read_bytes()
    try:
        return plistlib.loads(data)
    except Exception:
        pass
    try:
        xml = subprocess.run(
            ["plutil", "-convert", "xml1", "-o", "-", str(path)],
            check=True,
            capture_output=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        raise ValueError(f"{path} is unreadable: {error}")
    return plistlib.loads(xml)


def check(app):
    problems = []
    info_path = app / "Info.plist"
    if not info_path.is_file():
        return [f"{info_path} is missing"]
    info = read(info_path)

    declared = info.get("CFBundleLocalizations") or []
    for language in LANGUAGES:
        if language not in declared:
            problems.append(f"CFBundleLocalizations has no {language}: {declared}")
    region = info.get("CFBundleDevelopmentRegion")
    if region != "en":
        problems.append(f"CFBundleDevelopmentRegion is {region!r}, not en")

    tables = {}
    for language in LANGUAGES:
        folder = app / f"{language}.lproj"
        if not folder.is_dir():
            problems.append(f"{folder.name} is missing")
            continue
        for table in TABLES:
            path = folder / f"{table}.strings"
            if not path.is_file():
                problems.append(f"{folder.name}/{path.name} is missing")
                continue
            try:
                tables[language, table] = read(path)
            except ValueError as error:
                problems.append(str(error))

    english = tables.get(("en", "AppShortcuts"), {})
    for language in LANGUAGES:
        phrases = tables.get((language, "AppShortcuts"))
        if phrases is None:
            continue
        if len(phrases) != PHRASES:
            problems.append(f"{language}: {len(phrases)} phrases, expected {PHRASES}")
        for key, value in phrases.items():
            if "${applicationName}" not in value:
                problems.append(f"{language}: no app name in {value!r}")
        if language != "en" and english and sum(phrases.get(k) != v for k, v in english.items()) < PHRASES / 2:
            problems.append(f"{language}: the phrases are still English")

    titles = tables.get(("en", "Localizable"), {})
    for language in ("tr", "fr"):
        table = tables.get((language, "Localizable"))
        if table is None or not titles:
            continue
        if sum(table.get(k) != v for k, v in titles.items()) < len(titles) / 2:
            problems.append(f"{language}: the titles are still English")
    return problems


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    problems = check(Path(sys.argv[1]))
    for problem in problems:
        print(f"PROBLEM: {problem}")
    if problems:
        return 1
    print("en, tr and fr are declared and in the app.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
