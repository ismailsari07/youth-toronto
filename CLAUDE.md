# Pape Mosque app (youth-toronto)

Flutter 3.38.5 · Riverpod · go_router · supabase_flutter. iOS, built on Codemagic, shipped through TestFlight.
Three tabs: Prayer (home), Community (events + announcements), Profile.

## Shared context lives in the admin panel

One Supabase project (`onczqxxdvmmmdcuhmyio`) serves this app, the website, pape-api and the admin panel.
The panel repo `github.com/ismailsari07/pape-admin` owns the schema and the shared briefing: read its
CLAUDE.md §2 (prayer pipeline), §3 (tables), §5 (decisions) and §8 (progress) before planning data work.
If this file contradicts it, the panel's CLAUDE.md wins; fix this file.

Rules that matter here:
- Prayer times come only from `prayer_cache`. Never call Diyanet or pape-api from the app.
- Never log personal data (names, emails, phones, document paths or URLs).
- Admins signed into the app get admin RLS: filter explicitly (`is_published`, announcement `status` and
  `expires_at`, banner `enabled`/`ends_at`) instead of trusting RLS to hide drafts.

## Content from the database (since 1.0.1)

Mosque info, opening hours, cemetery, burial contacts, the services list, links, the emergency banner and the
app config (minimum version, feature toggles) are edited in the panel and read with one call,
`rpc('app_content_bundle')` → `{version, content{mosque_info, cemetery, links, app_banner, app_config},
services[], contacts[]}`. Code: `lib/core/content/`.

- Fetched after the first frame and on resume after 15+ minutes; never blocks the UI.
- Order: live → last good bundle (shared_preferences) → `assets/content_defaults.json`. Parsed defensively:
  a bad required field falls back to the default's; a missing optional field (links, socials, lat/lng) is
  empty, because the database omits empty keys.
- Texts are `{tr, en, fr}`; fallback: chosen language → English → Turkish.
- The app checks the banner's `enabled`/`ends_at` itself. The update screen blocks only on fetched or cached
  data, only with an App Store link, and only when the app's version is below `min_supported_version`.
- UI strings stay in the ARB files (`lib/l10n/`); only content comes from the database.

## Donations (since 1.0.5)

Apple rule: donations happen OUTSIDE the app. The Donate pill on Prayer and the Donate row on Profile open one
standard bottom sheet, `showDonateSheet` (`lib/features/donations/donate_sheet.dart`, via `showAppSheet`, styled
like the Appearance sheet; since 1.0.7, replacing 1.0.5's pull-down menu). Each row closes the sheet and opens
the website in Safari (`LaunchMode.externalApplication`); never add a form or a web view.

- The pill (since 1.1.1, replacing the hero's heart circle; `HeroIdentityRow` in
  `lib/features/prayer/widgets/hero_identity_row.dart`): heart + `donatePill`, white with the hero button's green
  text, no animation, 44 pt tap target, VoiceOver reads `donation`. French is "Donner": "Faire un don" cut the mosque
  line on an iPhone SE. `test/prayer/hero_identity_row_test.dart` measures it with the bundled Manrope at 375 pt.
- Rows: active `donation_funds` (public read) in `display_order`, `is_active` filtered in the app, `unassigned`
  never shown, then "All donation options". Code: `lib/core/donations/`, `lib/features/donations/`.
- Cached like the content bundle (launch, resume after 15+ minutes); with nothing cached only "All donation
  options" shows.
- URL: `links.donation` from the bundle, else `https://papemosque.ca/donation`; a fund adds `?fund=<slug>`,
  which the website turns into that fund's open form.
- Fund titles (since 1.4.0): `title_i18n` from the panel's Fonlar, in the app language, then EN, then TR. The plain
  `title` column is a copy of Turkish and the fallback, also for lists cached before 1.4.0.

## Push notifications (since 1.0.8)

FCM, iOS only (no Android Firebase config on purpose; `PushPlatform.start()` returns the unsupported
platform elsewhere, and every push UI hides itself). The server side (`push_devices`, the sender) lives in
pape-admin (§3 `push_devices`, §5). Code: `lib/core/push/`, `lib/shared/providers/push_provider.dart`,
`lib/features/push/`.

- Per device, no login: `install_id` + secret in the Keychain (`first_unlock`; survives reinstall), never
  logged. RPCs `register_device`, `set_event_notifications`, `device_settings`; error codes in `push_api.dart`.
- `register_device` only when the payload's fingerprint changed or 24 h passed; 1 h pause after a throttle or
  53400. The FCM token comes from `getToken()` (not 17.x's FID API: the sender targets registration tokens).
- Pre-prompt sheet before the iOS prompt: only while iOS hasn't asked, once per session, 3 days after
  "Şimdi değil", never on its own after 3 (`push_prompt.dart`). If it never appears on a test phone, check
  iOS Settings first: when an earlier build already got permission, iOS has asked, so the sheet correctly
  stays hidden (seen on the 1.0.8 TestFlight check). To see it, use a phone that hasn't granted or refused
  the app's notifications. Taps route via `pushRoute()` to
  `/community/event/:id` / `/community/announcement/:id` (loaded by id, published filter), else Community.
- `AppDelegate` keeps itself as the notification-center delegate, so Firebase doesn't replace it; both
  plugins get every callback. Prayer reminders are back (1.3.0): on the phone, check that a foreground reminder
  isn't presented twice (both plugins answer `willPresent` for local notifications).
- Firebase pinned to `firebase_core` 4.x / `firebase_messaging` 16.x; 17.0 (Firebase iOS SDK 13) is untested.

## Sign in with Apple and Google (since 1.1.0)

**1.1.0 ships Apple only.** Google is postponed behind `kGoogleSignInEnabled` (`lib/core/feature_flags.dart`,
false; the button is hidden, the code stays). To turn it on: create the GCP iOS + Web OAuth clients, enable the
Supabase Google provider (both client IDs; keep "Skip nonce check" off), add the `Info.plist` entries below, set
the flag to true. Apple is required as soon as Google is offered (App Review 4.8).

Native only, iOS only (`socialSignInSupported`), both through `signInWithIdToken` with a fresh nonce (SHA-256 to
Apple/Google, raw to Supabase; Google's `initialize(nonce:)` is called per sign-in). Never a web redirect. Code:
`lib/core/auth_service.dart`, `lib/core/social_auth.dart`, `lib/features/profile/widgets/social_sign_in_buttons.dart`.

- Buttons above the email form on sign-in and sign-up: Apple first, same size as Google once it's on. Social
  sign-ups have no phone or date of birth (the marriage flow asks for the date of birth).
- Apple sends the name only on the first authorization. It goes to `set_my_initial_name()` and waits in the Keychain
  (`PendingAppleName`) until saved; retried at launch. An Apple account without a name has `full_name = ''`; Profile
  shows "İsim ekle" while the name is still automatic (`isAutomaticName`, same rule as the RPC).
- Same verified email → Supabase links to the existing account (pape-admin CLAUDE.md §5, incl. the risk until SMTP).
- Delete: an Apple account gets 428 from `delete-account`, confirms with Apple once more, and the function revokes
  the Apple tokens before deleting (secrets `APPLE_TEAM_ID`, `APPLE_SIWA_KEY_ID`, `APPLE_SIWA_PRIVATE_KEY`; Deno tests
  in `supabase/functions/delete-account/`, run with `npx deno@2.5.6 test supabase/functions/delete-account/`).
- iOS config: `com.apple.developer.applesignin` in `Runner.entitlements`. For Google later: `GIDClientID`,
  `GIDServerClientID` and the reversed iOS client ID URL scheme in `Info.plist` (GCP project `pape-mosquee`; client
  IDs aren't secrets). Not there in 1.1.0.

## Event registration (since 1.2.0)

Contract: pape-admin CLAUDE.md §10 (the server enforces everything; the app's checks only warn earlier). Decided
2026-10-18 (D1–D8, plan with screenshots: https://claude.ai/artifact/SuzywhUZgD5KgZG4HP4FmL). Code:
`lib/core/registration/`, `lib/shared/providers/registration_provider.dart`, `lib/features/registration/`.

- An event with `registration_form` gets a "Kayıt" badge on its card (no button: the list doesn't know the state)
  and registers in the app; `registration_link` events are unchanged. The page calls `event_registration_state`
  (always the source of the form and `form_version`, refetched on sign-in/out) and `record_event_view` (once per
  event per session, device credentials, errors ignored; "X kişi görüntüledi" only when `views` isn't null).
- What shows per state, and every error's text (TR/EN/FR ARB keys `reg*`): `event_registration_section.dart`,
  `registration_errors.dart`, `registration_text.dart`. `no_profile` has its own text (D2). Deadlines read
  "Son kayıt tarihi: …" (no Turkish suffix, D3), on the mosque's clock. Kill switch off hides everything except a
  member's own "Kayıtlısın" (D4). Unknown status = closed; an unknown required question type blocks sending with
  "update the app", an unknown optional one is skipped (D6).
- A number question without `integer` allows decimals, as the server reads it (D1; §10 fixed to match in
  pape-admin 3bc50b0). `test/fixtures/registration-forms.json` is a copy of pape-admin's shared fixture: refresh it when the
  server's form rules change (the test compares the app's parse with the server's signature).
- Nothing personal on disk: state in Riverpod memory, the draft (D8) in a session-only provider cleared on success
  and on member change.
- Push link: `register_device` is forced after every sign-in/sign-out (`main.dart`), because the payload's
  fingerprint has no member. After registering, the event leaves the local mute list (the server dropped its
  mute); `set_event_notifications` answering `P0001 registered` is `PushError.registered` (toggle stays on). The
  event's notification row is on and locked only while push can arrive (D5).

## Contribution box (next version after 1.3.1)

Optional "call this number to contribute" card on the event page, after "About this event"
(`lib/features/community/widgets/event_contribution_card.dart`). Information only, no payment. Columns
`youth_events.contribution_phone/_heading/_text/_name`: no phone means no card. The phone is always
`416 555 0142` (Canada/US, set by the panel), so `telUri` dials it. The heading and text are single-language, like
the event title; only "Tap to call" is translated. **When this version is on the App Store:** set
`APP_SHOWS_CONTRIBUTION = true` in pape-admin `src/lib/event-contribution.ts`.

## Keyboard (since 1.2.1)

The keyboard always has a way out (TestFlight 1.2.0: number, phone and multi-line fields had none). Code:
`lib/ui/components/app_text_input.dart`; tests `test/widget/keyboard_test.dart` and the iPhone SE group in
`test/registration/registration_screen_test.dart`.

- Every text field is an `AppTextInput` (`AppField` and `BoxInput` use it; a test fails on a raw `TextField`). A tap
  outside closes the keyboard (Flutter only does this on desktop/web) without eating the tap. One-line fields
  say Next (moves to the next field on the screen, skipping read-only ones) or, with `last: true`, Done (runs
  `onSubmit`: sign in, create account, save name; delete-account and the registration form only close).
- `KeyboardAccessoryHost` (MaterialApp.builder) shows "Bitti / Done / Terminé" with up/down arrows on top of the iOS
  keyboard for number, phone and multi-line fields, and adds its 44 pt to `viewInsets` so scaffolds and sheets clear it.
- Scroll views holding fields set `keyboardDismissBehavior: onDrag` (a test checks every feature file).
- A submit button that must stay visible while typing lives in the body, not `bottomNavigationBar` (the keyboard covers
  that slot). The registration form does this and hides its "can't be cancelled" line while the keyboard is up: on an
  iPhone SE that leaves about 150 pt of form between the nav bar and Send.

## Prayer reminders (back since 1.3.0; budget and notice since 1.3.1; athan only since 1.4.0)

Owner's hard rule: a prayer notification must NEVER fire at a wrong time. If real data runs out, reminders stop; no
estimates, no filling, no carrying a day forward (pape-admin `docs/prayer-range-migrations.md`). `prayer_cache` holds a
rolling ~30-day window, one validated row per Toronto date. Code: `lib/core/reminder_sync.dart`, `prayer_days.dart`,
`prayer_refresh.dart`; tests `test/reminders/`, `test/widget/prayer_widget_data_test.dart`. Decided 2026-10-19.

- `scheduleDays` uses a day only if it has its own row whose `gregorianDate` is that date; nothing is ever filled. The
  reminders and the widget share it. Widget: yesterday + 14 days; after the last row it shows "open the app".
- Reminders fill iOS's 64 pending slots (1.3.1, decided with the owner): 63 for reminders (`reminderBudget`), 1 for the
  notice, `otherLocalNotifications = 0` (event/announcement pushes are remote; count any new local notification there).
  Whole days only, in date order from today, until the next day doesn't fit or the rows run out: 12 days with all five
  prayers, 21 with three.
- The notice (`buildNotice`, id 9999, payload `open_prayer` → Prayer): "your reminders stop tomorrow, open the app" at
  10:00 Toronto on the last scheduled day; if that has passed, the middle of the next prayer gap still ahead, never in
  21:30–08:00, else none. Rebuilt with every sync, so a regular user never sees it; none when reminders are off.
- Every reminder fires at the athan; the owner removed "5 minutes before the iqamah" in 1.4.0. `loadSettings` deletes the old
  `prayer_reminders_timing` key, and the launch's sync replaces what was pending. Offline, or until the updated app first
  runs, the old iqamah-time reminders stay pending; the next successful sync replaces them.
- Friday's Dhuhr fires at the Dhuhr athan; its body gives that row's `jumaaPrayerTime` ("Öğle ezanı · Cuma namazı 13:00'te",
  `reminderFridayBody`, `clockInSentence` adds the Turkish suffix). No readable Jumu'ah time: the plain athan text, never an
  invented time. Follows the Dhuhr switch. The notice's gaps still go around Jumu'ah.
- Default: a saved on/off wins; with none, on only if iOS already allows notifications (e.g. after the push pre-prompt).
  The iOS prompt never appears on its own: only `sync(ask: true)` from the reminders sheet asks. The owner rejected a
  "reminders stop" notice on 2026-10-10 and decided the local one above for 1.3.1.
- Rescheduled on launch, resume, pull-to-refresh on Prayer, settings/language changes, and the `prayer_refresh` silent
  push (pape-admin sends it after any change to a row dated today or later, debounced; FCM data
  `{"type":"prayer_refresh"}`, `content-available`). Foreground: `PushPlatform.received`; background:
  `onBackgroundPush`, on the app's own engine, so the widget bridge is there too. It needs a running engine (see "UIScene lifecycle").
  iOS may not deliver it (app swiped away, Low Power Mode, Background App Refresh off); the notice asks the member to open the app
  before the schedule runs out.
  A failed fetch keeps what's scheduled (it came from real rows); an empty answer clears it. A background
  prayer_refresh that rescheduled is recorded locally and shown in Profil → Uygulama hakkında as "Son arka plan
  yenileme" (`BackgroundRefreshLog`), to check delivery on TestFlight.
- No bell on the Prayer hero: next to the Donate pill it cut the mosque line on an iPhone SE. Reminders open from the
  row under the prayer times, Profile and Settings.

## Monthly times (since 1.4.0)

`/prayer/monthly` (`monthly_times_screen.dart`), from the row under the times on Prayer: every date from today to the last
`prayer_cache` row, athan over iqamah, Toronto dates. `monthDays` uses `scheduleDays`' rule, so a date without its own valid
row is listed as missing and nothing is filled or listed past the last row; an unreadable time is a dash, never its raw text.
Today is green, Fridays gold with the Jumu'ah time in the date column, which stays in view while the prayers scroll sideways.
Rows: `PrayerRows` (`prayer_month.dart`) keeps the reminders' fetch in memory for 15 minutes, so opening it usually makes no
call; `refreshPrayerSchedules` (pull, `prayer_refresh`) drops them. With reminders off or after 15 minutes it fetches once.

## French (audited 2026-11-02)

Canadian French, `vous`, gender-neutral wording. Terms: prière, adhan, iqama, Fajr/Dhohr/Asr/Maghrib/Icha, "Prière du
vendredi (Joumou'a)", mosquée, don, courriel. Typography: no space before `?`, `!`, `;`; no-break space before `:`; "2e".
`test/l10n/french_strings_test.dart` enforces keys, placeholders and typography; `test/l10n/french_layout_test.dart`
renders every main screen and sheet at 390 pt and fails on an overflow or cut text (`SHOT_DIR=<dir>` also saves PNGs).
Native: permission prompts in `ios/Runner/{fr,tr}.lproj/InfoPlist.strings`; the widget's own texts in `WidgetText`
(`PrayerWidget.swift`). The app name stays "Pape Mosque" on the home screen, as iOS Settings shows it.

## Siri and Shortcuts (since 1.4.0)

iOS 16+, ten App Shortcuts (Apple's limit) in EN/TR/FR. Same hard rule as the reminders: never a wrong or estimated time.
Code: `ios/Runner/Siri/`, `lib/core/siri_data_sync.dart`, `lib/core/siri_bridge.dart`, `lib/core/launch_gate.dart`.

- Data: three versioned JSON documents in the App Group (`siri_prayers`, `siri_events`, `siri_mosque`; shapes in
  `siri_data_sync.dart`), each written separately so one failed fetch can't touch another. Intents read only these, no
  network. Flutter writes every time as an instant and as text with the reminders' code; Swift compares instants and
  repeats the text. Prayers: with the widget sync, same rows. Events: after a successful fetch (launch, resume, pull,
  silent push); refused after 7 days. Mosque: after a content refresh and at launch.
- Spoken answers and cards follow Siri's language (`INPreferences.siriLanguageCode()`), then the device's, then English;
  never the app's setting. They are said in Siri's voice, and `Bundle.main.preferredLocalizations` only knows the device. Events
  are written in all three. iOS itself picks the titles in the Shortcuts app and Spotlight (`Localizable.strings`), from the
  device's language or the app's language in iOS Settings, not Siri's: Apple documents Siri's language as able to differ. So
  test those with the device in that language; `tool/check_siri_bundle.py` (in `siri-check`) proves the translations shipped. `test/siri/siri_terms_test.dart` keeps Swift's terms and phrases in step with the ARB files.
- Intents are in the Runner target (Apple's rule for App Shortcuts), so a question launches the app in the background, with
  Flutter only if iOS connects a scene (see "UIScene lifecycle"). They read only the App Group, so they answer either way.
  `LaunchGate` keeps a Flutter launch invisible: no launch counted, no pre-prompt, no `register_device`, no reminder reschedule, no
  sync of the panel's content, until the app really comes forward, then all of it once. (The unseen first frame can still
  run the home screen's read-only loads, like prayer times and events; they write nothing.)
  (`test/siri/launch_gate_test.dart` pumps the real `MytApp`). Silent pushes get the same gate and still reschedule through
  `onBackgroundPush`. The pre-prompt also never fires over a shortcut that brought the app forward.
- Directions and Call: Siri confirms, then `HandoffIntent` brings the app forward for a moment to open Maps or `tel:`; a
  background intent can't open another app. iOS adds its own `tel:` alert. Donate opens `showDonateSheet`.
- `AppIntents` is weak-linked (`-weak_framework`) because the app still runs on iOS 15.
- App names: `INAlternativeAppNames` with per-language values in `InfoPlist.strings`, limit three per language. Turkish's
  third is "Pape Camii'nde" so "Pape Camii'nde sıradaki namaz" matches. Apple's docs ask for an Intents extension; an Apple
  engineer wrote (June 2026) that it keeps working for App Shortcuts. If a phone ignores them, that extension is next.
- Prayer parameter: Siri matches the name in the phrase's language (Turkish İmsak, Öğle, İkindi, Akşam, Yatsı). No synonyms like
  "Sabah": that initializer needs iOS 17 and the table is read at build time, so it can't vary by iOS version.
- Turkish sentences say "13:07'de", "16:30'da" (`TurkishTime`: the suffix follows the last number said; on the hour, the
  hour: "16:00'da"); cards keep "13:07". Each time in `siri_prayers` is `{en, tr, fr}` (document version 2): Siri's language can
  differ from the app's, and a document missing a language is refused.
- No Apple names in any intent text: title, description, parameter, phrase, short title, spoken or snippet text, in any language.
  App Store Connect rejects the upload otherwise (ITMS-90626, build 23 of 1.4.0, "cannot contain 'siri'"), and only at upload.
  `test/siri/siri_trademark_test.dart` scans the code's string literals and every `.strings` file for these names.
- Tests: `tool/siri_swift_test.sh` runs the Foundation-only logic in Docker; workflow `siri-check` in `codemagic.yaml`
  compiles everything (the only compile of `AppIntents` and SwiftUI code; this machine has no Xcode) and runs RunnerTests.

## UIScene lifecycle (since 1.4.0)

Apple requires it from Xcode 27: an app built with that SDK without UIScene fails at launch. Flutter's official migration, on
3.38.5: `UIApplicationSceneManifest` in `Info.plist` with the stock `FlutterSceneDelegate` and no `SceneDelegate` of our own.
`AppDelegate` is a `FlutterImplicitEngineDelegate`: plugins and the three channels are registered in
`didInitializeImplicitFlutterEngine`; only the notification delegate is set in `didFinishLaunching`. Launch options are nil
now, and `UIApplication.delegate.window` is nil: never use them (`test/ios/ui_scene_test.dart`).

- The engine starts when the scene loads the storyboard. A launch with no scene runs no Dart. **Decided by the owner on 2026-11-05:**
  if a `prayer_refresh` push on a cold background launch does nothing because of this, accept it and document it here; don't add
  a custom engine or `SceneDelegate`. Reminders then update at the next launch or resume. The 12-day window and the notice cover
  running out; a corrected time reaches a phone like that only when the app next runs. Pushes to a suspended app with a live engine are not affected.
- iOS can drop a suspended app's scene and connect a new one, which starts a new engine, so registration must be repeatable.
- `siri-check`: `tool/check_scene_manifest.py` reads the built `Info.plist`; `tool/check_simulator_launch.sh` launches the app
  on a simulator and looks for the Debug-only "PapeScene" log line, which only the scene's engine can write.

## Camimizden Haberler (since 1.4.0)

`lib/core/news/mosque_news.dart` reads `mosque_news` (published only; admins can read drafts), keeps the last good list in
shared_preferences. Named apart from `newsProvider`, which means announcements. Home: `NewsRail` under the emergency banner,
featured first, 188 pt cards so the times stay near; hidden with no news. Community: third segment, shown once something is
published; the segment lives in `communitySegmentProvider` so the rail's "See all" can open it. Detail: `NewsDetailScreen`
(4:5 `PageView`, dots, tap for `NewsViewer`, pinch to zoom). `NewsPhotoFrame`: a crop fills it; `fit: contain` shows the whole
photo over `PosterBackdrop`, and the viewer shows it clean. Push: `news_id` → `/community/news/:id`. Kill switch
`features.news`. With Events and Announcements both off there's no Community tab, so the rail has no "See all".

## Announcement photos on cards (since 1.4.0)

`PosterFrame` (`announcement_photo.dart`), the website's rule: the card keeps its 16:9 frame and the whole image shows
(contain), over a blurred, darkened copy of itself. Within 2% of 16:9 it just fills the frame, so photos look as before. The
detail page keeps the natural size. Event photos (`PhotoBand`) still crop.

## Clock times (since 1.4.0)

English "4:55 PM", Turkish "16:55" (morning "05:43"), French "16 h 55" (no-break spaces; on the hour "16 h"). One function,
`clockText` in `lib/shared/formatters.dart`, behind `prayerClockText` and `eventTime`; the widget and Siri get its text from
Flutter. Display only: instants and scheduling never read it (`test/l10n/clock_format_test.dart`, DST days included).
`french_layout_test.dart` fails on a 12-hour or colon time on any French screen. Free text from the panel isn't converted.

## Release checklist

Full guide: `docs/RELEASE.md`.

1. `dart run tool/gen_content_defaults.dart` (refreshes `assets/content_defaults.json` from the live bundle;
   the banner is never bundled). Commit the result if it changed.
2. Bump `version:` in `pubspec.yaml`. `flutter analyze` and `flutter test` clean.
3. Codemagic build → TestFlight.
4. Once it ships: set `latest_build` in the panel (İçerik ve Ayarlar → Uygulama ayarları).
