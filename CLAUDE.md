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
- Fund titles are Turkish only (one `title` column); translations wait for the panel's fund module.

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
  plugins get every callback. When prayer reminders come back, check that a foreground reminder isn't
  presented twice (both plugins answer `willPresent` for local notifications).
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

## Release checklist

1. `dart run tool/gen_content_defaults.dart` (refreshes `assets/content_defaults.json` from the live bundle;
   the banner is never bundled). Commit the result if it changed.
2. Bump `version:` in `pubspec.yaml`. `flutter analyze` and `flutter test` clean.
3. Codemagic build → TestFlight.
4. Once it ships: set `latest_build` in the panel (İçerik ve Ayarlar → Uygulama ayarları).
