import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  test('ends with the attribution line, after a blank line', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final lines = eventShareText(en, upcoming()).split('\n');
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
      eventShareText(fr, upcoming()).split('\n').last,
      "Partagé depuis l'application Pape Mosque · papemosque.ca",
    );
    expect(
      eventShareText(tr, upcoming()).split('\n').last,
      'Pape Camii uygulamasından paylaşıldı · papemosque.ca',
    );
  });
}
