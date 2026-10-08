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

## Release checklist

1. `dart run tool/gen_content_defaults.dart` (refreshes `assets/content_defaults.json` from the live bundle;
   the banner is never bundled). Commit the result if it changed.
2. Bump `version:` in `pubspec.yaml`. `flutter analyze` and `flutter test` clean.
3. Codemagic build → TestFlight.
4. Once it ships: set `latest_build` in the panel (İçerik ve Ayarlar → Uygulama ayarları).
