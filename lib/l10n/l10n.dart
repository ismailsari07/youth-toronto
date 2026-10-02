import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_service.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Localisation (spec §9 step 7). Strings live in `app_{en,fr,tr}.arb`;
/// `flutter gen-l10n` (run by `flutter pub get` / build) writes
/// [AppLocalizations]. Widgets read them through `context.l10n`.
///
/// The app follows the device language unless the member picks one in
/// Settings; anything other than French or Turkish falls back to English.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// A language offered in the picker, named in its own language.
typedef AppLanguage = ({String code, String autonym});

const appLanguages = <AppLanguage>[
  (code: 'en', autonym: 'English'),
  (code: 'fr', autonym: 'Français'),
  (code: 'tr', autonym: 'Türkçe'),
];

/// The supported locale for [override] (the member's choice, if any) and
/// [device] (the phone's preferred languages, most preferred first).
/// Matches on language only, so fr_CA and tr_TR resolve; else English.
Locale resolveAppLocale(Locale? override, Iterable<Locale> device) {
  if (override != null) return override;
  for (final locale in device) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return const Locale('en');
}

/// Strings for code that runs without a widget tree (notifications), in
/// the language the app is showing.
Future<AppLocalizations> currentAppLocalizations() async {
  final locale = resolveAppLocale(
    await LocaleStore.load(),
    PlatformDispatcher.instance.locales,
  );
  return lookupAppLocalizations(locale);
}

/// The member's language choice, on this device. Absent means "follow the
/// device".
abstract final class LocaleStore {
  static const _prefKey = 'app_locale';

  static Future<Locale?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      final known = appLanguages.any((l) => l.code == code);
      return known ? Locale(code!) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
  }
}

/// Upper case that knows Turkish: Dart's [String.toUpperCase] ignores the
/// locale, so "İkindi" would become "İKINDI". In Turkish, i → İ (ı → I is
/// already right).
String upper(String text, String localeName) {
  if (localeName.startsWith('tr')) text = text.replaceAll('i', 'İ');
  return text.toUpperCase();
}

/// The localised name of a prayer, from prayer_cache's English name
/// ("Maghrib"). The English name stays the key everywhere else (icons,
/// clock parsing, reminders).
String prayerLabel(AppLocalizations l, String name) =>
    l.prayer(name.toLowerCase());

/// The sentence for an auth failure. Supabase's English text is only shown
/// for failures without one of our own, and only to English readers.
String authErrorText(AppLocalizations l, AuthError error) =>
    switch (error.kind) {
      AuthFailure.invalidCredentials => l.errorInvalidCredentials,
      AuthFailure.emailTaken => l.errorEmailTaken,
      AuthFailure.weakPassword => l.errorWeakPassword,
      AuthFailure.emailNotConfirmed => l.errorEmailNotConfirmed,
      AuthFailure.rateLimited => l.errorRateLimited,
      AuthFailure.network => l.errorNetwork,
      AuthFailure.sessionExpired => l.errorSessionExpired,
      AuthFailure.adminAccount => l.errorAdminAccount,
      AuthFailure.deleteFailed => l.errorDeleteFailed,
      AuthFailure.unexpected =>
        l.localeName == 'en' ? error.serverMessage ?? l.errorUnexpected
            : l.errorUnexpected,
    };
