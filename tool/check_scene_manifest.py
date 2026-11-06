#!/usr/bin/env python3
"""Fails unless a built Runner.app declares Flutter's UIScene lifecycle.

Usage: python3 tool/check_scene_manifest.py build/ios/iphonesimulator/Runner.app

An app built with Xcode 27 without this fails at launch, so it is checked in
the built app, after everything that could rewrite the Info.plist.
"""
import plistlib
import sys
from pathlib import Path

ROLE = "UIWindowSceneSessionRoleApplication"
EXPECTED = {
    "UISceneClassName": "UIWindowScene",
    "UISceneDelegateClassName": "FlutterSceneDelegate",
    "UISceneConfigurationName": "flutter",
    "UISceneStoryboardFile": "Main",
}


def problems(app: Path) -> list[str]:
    info = app / "Info.plist"
    if not info.is_file():
        return [f"{info} is missing"]
    with info.open("rb") as file:
        plist = plistlib.load(file)

    manifest = plist.get("UIApplicationSceneManifest")
    if not isinstance(manifest, dict):
        return ["UIApplicationSceneManifest is missing"]

    found = []
    if manifest.get("UIApplicationSupportsMultipleScenes") is not False:
        found.append("UIApplicationSupportsMultipleScenes must be false")

    configurations = manifest.get("UISceneConfigurations", {}).get(ROLE)
    if not isinstance(configurations, list) or len(configurations) != 1:
        return [*found, f"expected exactly one {ROLE} configuration"]
    for key, value in EXPECTED.items():
        if configurations[0].get(key) != value:
            found.append(f"{key} is {configurations[0].get(key)!r}, not {value!r}")

    # The scene loads this to create the Flutter view and so the engine.
    if not list(app.glob("**/Main.storyboardc")):
        found.append("Main.storyboardc is not in the app")
    return found


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    found = problems(Path(sys.argv[1]))
    for problem in found:
        print(f"Scene manifest: {problem}")
    if found:
        return 1
    print("Scene manifest: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
