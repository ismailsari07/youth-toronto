# Releasing the app

The iOS app is built on Codemagic, because this project is developed without a Mac, and shipped through TestFlight and App Store Connect. Codemagic and App Store Connect menu names change, so treat them as a guide. The checklist is at the end.

## 1. Version and build numbers

- `pubspec.yaml` has `version: 1.4.0+1`. **You only bump the part before the `+`** (the version name).
- Codemagic auto-increments the build number and ignores the `+1`. The widget extension takes the same numbers.
- App Store Connect refuses a build number it has already seen, so never set one by hand.

## 2. Branches

- `main` is the shipped or in-review code. Don't commit work to it directly.
- Each feature or release goes on its own branch, such as `feature/siri`. TestFlight rounds can build from that branch.
- Once TestFlight passes, merge into `main` and make the App Store build from `main`.

## 3. Before building

```sh
dart run tool/gen_content_defaults.dart   # refreshes assets/content_defaults.json from the live bundle
flutter analyze
flutter test
bash tool/siri_swift_test.sh              # Foundation-only Swift logic, in Docker
```

Commit `assets/content_defaults.json` if it changed. It's what a first launch without a network shows. The script is read-only and never bundles the banner.

## 4. `siri-check` (compile check)

This is the only place the App Intents, SwiftUI and `AppDelegate` code gets compiled before a release build, so run it first. It's defined in `codemagic.yaml`. There's one Codemagic app, because Codemagic doesn't allow adding the same repo twice, so it's switched temporarily:

1. Switch the Codemagic app to YAML configuration.
2. Start a build: your branch, workflow **Siri check**.
3. Switch the app back to Workflow Editor and confirm its settings are intact, including the Xcode version and publishing options. Don't start a release build until you have.

It runs the Flutter tests, a simulator build and the Swift tests. It also checks the built app for the shortcuts, weak-linked `AppIntents`, translations and scene manifest, and launches it on a simulator. `WARNING` in the launch step means the app stayed running but the scene path wasn't confirmed.

`siri-check` uses `xcode: latest`, which can differ from the release build's pinned Xcode.

## 5. Release build

This lives in the **Workflow Editor** app, not in `codemagic.yaml`.

- **Flutter:** 3.38.5.
- **Xcode:** pinned to 26.6, the version of the last successful builds. Change it on purpose, as its own step, followed by a full TestFlight round.
- **Publishing:** upload to App Store Connect for **TestFlight only**. Don't submit to App Store review automatically.
- **Push:** the signed app must have `aps-environment = production`. If push is missing, the provisioning profile predates it: delete the old profile so a new one is created.

## 6. TestFlight

Wait for App Store Connect to finish processing the build.

- **Internal testers:** App Store Connect team members. There's no review, and they get the build once it's processed.
- **External testers:** anyone invited by email or public link. The first build of a version needs **Beta App Review**, so allow time for it. Fill in the test information and reuse the demo account.

Test on a real phone, because simulators can't confirm notification taps, push, Siri or sign-in. Check the app closed, in the background and in the foreground.

## 7. App Store submission

1. **Screenshots:** the `screenshots` workflow is on the `screenshots` branch, and the app is switched to YAML and back for it, as in section 4. It takes 10 shots at 6.9" (1320×2868) in **English and Turkish** and saves them as build artifacts, with no signing. That branch doesn't follow `main`, so merge the release into it first. French isn't covered.
2. **Metadata:** "What's New" in each store language, plus description or keywords if they changed. Update App Privacy if data use changed.
3. **Review notes:** include the following.
   - The email demo account and how to reach the main features.
   - Donations open the website in Safari; there are no in-app payments.
   - New features since the last version, with a phrase to try for anything voice-driven.
4. **Build:** select the build made from `main`.
5. **Version release:** choose **Manually release this version**, so approval doesn't publish it before you're ready.

## 8. After it's live

Do these only once the version is **on the App Store**, not when it's approved.

**Panel, İçerik ve Ayarlar**

| Setting | What to do |
|---|---|
| `links.app_store` (Bağlantılar) | Must hold the real App Store link. Without it the update screen never blocks. |
| `latest_build` (Uygulama ayarları) | Set to the new version, e.g. `1.4.0`. Informational: the app reads it but doesn't act on it. |
| `min_supported_version` (Uygulama ayarları) | **Raise only when you want to force an update.** Anyone below it is blocked until they update, so it must never be above the version on the store. |

**Constants in the `pape-admin` repo.** These only change what the panel tells editors. Set to `true`, commit and deploy the panel.

| Constant | File | True when the App Store version has |
|---|---|---|
| `APP_READS_CONTENT` | `src/components/content/ContentHeader.tsx` | Content from the database (1.0.1 or later) |
| `APP_SHOWS_CONTRIBUTION` | `src/lib/event-contribution.ts` | The contribution box (1.4.0) |
| `APP_SHOWS_FUND_TRANSLATIONS` | `src/lib/funds.ts` | Translated fund titles (1.4.0) |
| `APP_SHOWS_NEWS` | `src/lib/news.ts` | Camimizden Haberler (1.4.0) |

## 9. Problems we've hit

**ITMS-90626: invalid App Intent text (upload rejected).** App Store Connect rejects any intent title, description, parameter, phrase or spoken text that names Apple products. Build 23 of 1.4.0 failed with "cannot contain 'siri'" and "'apple'", and this only shows at upload, after a full build. Reword neutrally ("Opens directions to the mosque in Maps"). `test/siri/siri_trademark_test.dart` now catches it in `flutter test`.

**403 from App Store Connect: PLA update.** Apple published a new Program License Agreement, and the build stopped with:

> GET https://api.appstoreconnect.apple.com/v1/bundleIds ... returned 403: Unable to process request - PLA Update available - You currently don't have access to this membership resource. To resolve this issue, your team's Account Holder, Ismail Sari, must agree to the latest Program License Agreement.

Nothing is wrong with the code. The Account Holder accepts the new agreement at developer.apple.com/account, then you rebuild.

## Checklist

**Prepare**
- [ ] Version name bumped in `pubspec.yaml`; build number left alone
- [ ] `dart run tool/gen_content_defaults.dart`, committed if changed
- [ ] `flutter analyze`, `flutter test` and `tool/siri_swift_test.sh` clean
- [ ] `siri-check` passed on the branch, with no `WARNING` in the launch step
- [ ] Codemagic app switched back to Workflow Editor, settings intact

**TestFlight**
- [ ] Release build uses the pinned Xcode (26.6) and uploads to TestFlight only
- [ ] Internal round passed on a real phone
- [ ] External round and Beta App Review, if needed

**App Store**
- [ ] Merged to `main`, final build made from `main`
- [ ] Screenshots regenerated if the UI changed
- [ ] "What's New", review notes and demo account up to date
- [ ] **Manually release this version** selected
- [ ] Submitted and approved, then released by hand

**After it's live**
- [ ] `links.app_store` correct
- [ ] `latest_build` set
- [ ] `min_supported_version` raised only if forcing an update
- [ ] `APP_*` constants for this version set to `true`, panel deployed
