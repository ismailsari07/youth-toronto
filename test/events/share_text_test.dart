import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/event_schedule.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/l10n/l10n.dart';
import 'package:myt_flutter/shared/formatters.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() async {
    initMosqueTime();
    await initializeDateFormatting();
  });

  // A one-off event: Wednesday 30 Sep 2026, 7:30 PM in Toronto.
  UpcomingEvent upcoming() {
    final e = YouthEvent.fromJson({
      'id': 'e',
      'title': 'Gençlik Buluşması',
      'date_time': '2026-09-30T23:30:00+00:00',
      'category': 'youth',
      'recurrence': 'none',
      'location': 'Main hall',
    });
    return UpcomingEvent(e, tz.TZDateTime.from(e.dateTime, mosqueTz));
  }

  // The links section and the mosque's own website, as the panel sends them.
  ContentBundle content({
    String? website = 'https://papemosque.ca',
    String? appStore,
  }) =>
      ContentBundle.parse(
        {
          'content': {
            'mosque_info': {'website': 'https://www.mosque.example/'},
            'links': {
              'website': ?website,
              'app_store': ?appStore,
            },
          },
        },
        fallback: ContentBundle.empty,
        source: ContentSource.live,
      );

  test('ends with the attribution line, after a blank line', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final lines = eventShareText(en, upcoming(), content()).split('\n');
    expect(lines.first, 'Gençlik Buluşması');
    expect(lines, contains('Main hall'));
    expect(lines.sublist(lines.length - 2), [
      '',
      'Shared from the Pape Mosque app · papemosque.ca',
    ]);
  });

  test('the attribution is translated', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    final tr = lookupAppLocalizations(const Locale('tr'));
    expect(
      eventShareText(fr, upcoming(), content()).split('\n').last,
      "Partagé depuis l'application Pape Mosque · papemosque.ca",
    );
    expect(
      eventShareText(tr, upcoming(), content()).split('\n').last,
      'Pape Camii uygulamasından paylaşıldı · papemosque.ca',
    );
  });

  test('the App Store link follows the attribution once it is set', () {
    final en = lookupAppLocalizations(const Locale('en'));
    const store = 'https://apps.apple.com/ca/app/id1234567890';
    final lines =
        eventShareText(en, upcoming(), content(appStore: store)).split('\n');
    expect(lines.sublist(lines.length - 2), [
      'Shared from the Pape Mosque app · papemosque.ca',
      store,
    ]);
  });

  test("without a links website, the mosque's website is named", () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      eventShareText(en, upcoming(), content(website: null)).split('\n').last,
      'Shared from the Pape Mosque app · mosque.example',
    );
  });
}
