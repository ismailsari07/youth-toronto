import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/l10n.dart';
import '../shared/formatters.dart';
import 'content/content_bundle.dart';
import 'eid.dart';
import 'event_schedule.dart';
import 'events_news_service.dart';
import 'models.dart';
import 'mosque_time.dart';
import 'prayer_days.dart';
import 'siri_bridge.dart';

/// Feeds the Siri shortcuts (ios/Runner/Siri): three documents in the App
/// Group, each with its own key, so one failed fetch never touches another.
/// The shortcuts read only these; they have no network.
///
/// Every time is written as an instant and as display text by the code the
/// reminders use, so Siri can't disagree with the app.
abstract final class SiriDataSync {
  static const prayersKey = 'siri_prayers';
  static const eventsKey = 'siri_events';
  static const mosqueKey = 'siri_mosque';
  static const version = 1;

  /// Sessions kept per document. Answers are refused after 7 days, so this
  /// only has to outlast that.
  static const maxEvents = 20;
  static const eventHorizonDays = 45;

  /// Called with the rows the widget just got; no request of its own.
  static Future<void> writePrayers(
    List<PrayerDay> days,
    tz.TZDateTime now, {
    required int firstDay,
    required int dayCount,
  }) =>
      SiriBridge.write(
        prayersKey,
        jsonEncode(buildPrayers(days, now, firstDay: firstDay, dayCount: dayCount)),
      );

  /// Only after a successful fetch: on a failure the older document stays,
  /// with its older `fetchedAt`, and Siri refuses it after 7 days.
  static Future<void> syncEvents() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final events = await EventsNewsService.fetchEvents();
      await SiriBridge.write(eventsKey, jsonEncode(buildEvents(events, mosqueNow())));
    } catch (_) {
      debugPrint('SiriDataSync: events fetch failed');
    }
  }

  static Future<void> writeMosque(ContentBundle content) =>
      SiriBridge.write(mosqueKey, jsonEncode(buildMosque(content)));
}

int _seconds(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

/// The prayers document: real rows only ([scheduleDays]), nothing filled in.
/// Version 1:
///
/// ```json
/// {"version": 1, "writtenAt": 1793600000,
///  "days": [{"date": "2026-11-06",
///    "prayers": [{"key": "Fajr", "at": 1793620980, "time": "5:43 AM",
///                 "iqamahAt": 1793622780, "iqamah": "6:13 AM"}],
///    "jumuah": {"at": 1793640000, "time": "1:30 PM"}}],
///  "eid": [{"which": "fitr", "date": "2027-03-09",
///           "firstAt": 1804000000, "first": "8:00 AM",
///           "secondAt": 1804001800, "second": "8:30 AM"}]}
/// ```
///
/// `jumuah` only on a Friday, from that Friday's own row, as the reminders
/// do; a Sunrise has no iqamah. Eid comes from today's row, panel overrides
/// included: without a row for today there is none.
@visibleForTesting
Map<String, Object?> buildPrayers(
  List<PrayerDay> days,
  tz.TZDateTime now, {
  required int firstDay,
  required int dayCount,
}) {
  final rows = scheduleDays(days, now, first: firstDay, count: dayCount);
  final out = <Map<String, Object?>>[];
  for (final (offset: _, :day, :payload) in rows) {
    final prayers = <Map<String, Object?>>[];
    for (final item in payload.dailyPrayerTimes) {
      final moment = prayerMoment(day, item.name, item.time);
      if (moment == null) continue;
      final iqamah = item.iqamah;
      final iqamahMoment =
          iqamah == null ? null : prayerMoment(day, item.name, iqamah);
      prayers.add({
        'key': item.name,
        'at': _seconds(moment),
        'time': prayerClock12(item.name, item.time),
        if (iqamahMoment != null) 'iqamahAt': _seconds(iqamahMoment),
        if (iqamahMoment != null) 'iqamah': prayerClock12(item.name, iqamah!),
      });
    }
    final jumaa = day.weekday == DateTime.friday ? payload.jumaaPrayerTime : null;
    final jumaaMoment = jumaa == null ? null : prayerMoment(day, 'Dhuhr', jumaa);
    out.add({
      'date': mosqueDateKey(day),
      'prayers': prayers,
      if (jumaaMoment != null)
        'jumuah': {
          'at': _seconds(jumaaMoment),
          'time': prayerClock12('Dhuhr', jumaa!),
        },
    });
  }
  final today = [for (final r in rows) if (r.offset == 0) r.payload];
  return {
    'version': SiriDataSync.version,
    'writtenAt': _seconds(now),
    'days': out,
    'eid': today.isEmpty ? const [] : _eid(today.first.eidPrayerTimes),
  };
}

List<Map<String, Object?>> _eid(EidPrayerTimes? eid) {
  if (eid == null) return const [];
  final out = <Map<String, Object?>>[];
  for (final (which, entry) in [('fitr', eid.eidFitr), ('adha', eid.eidAdha)]) {
    final date = parseEidDate(entry.date);
    if (date == null) continue;
    // Eid prayers are morning prayers, so they read like Fajr's clock.
    final first = prayerMoment(date, 'Fajr', entry.firstIqamah);
    if (first == null) continue;
    final second = prayerMoment(date, 'Fajr', entry.secondIqamah);
    out.add({
      'which': which,
      'date': mosqueDateKey(date),
      'firstAt': _seconds(first),
      'first': prayerClock12('Fajr', entry.firstIqamah),
      if (second != null) 'secondAt': _seconds(second),
      if (second != null) 'second': prayerClock12('Fajr', entry.secondIqamah),
    });
  }
  return out;
}

/// The events document. Each line in all three languages, from the app's own
/// wording, because Siri's language can differ from the app's. Prayer-linked
/// sessions say "after Maghrib" with no clock time: no estimates here. Version
/// 1:
///
/// ```json
/// {"version": 1, "fetchedAt": 1793600000,
///  "items": [{"id": "…", "title": "…", "day": "2026-11-04",
///    "startsAt": 1793700000,
///    "when": {"tr": "Her Çarşamba · akşam namazından sonra", "en": "…", "fr": "…"},
///    "next": {"tr": "sıradaki: …", "en": "…", "fr": "…"}}]}
/// ```
@visibleForTesting
Map<String, Object?> buildEvents(Iterable<YouthEvent> events, tz.TZDateTime now) {
  final horizon = tz.TZDateTime(
    mosqueTz,
    now.year,
    now.month,
    now.day + SiriDataSync.eventHorizonDays,
  );
  final sessions = <UpcomingEvent>[];
  for (final first in upcomingEvents(events, now)) {
    sessions.add(first);
    final event = first.event;
    if (!event.repeats.isRecurring) continue;
    var at = first.startsAt;
    while (true) {
      // The next session on or after the day after this one.
      final dayAfter = tz.TZDateTime(mosqueTz, at.year, at.month, at.day + 1);
      final next = nextOccurrence(event, dayAfter);
      if (!next.isAfter(at) || next.isAfter(horizon)) break;
      sessions.add(UpcomingEvent(event, next));
      at = next;
    }
  }
  sessions.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final locales = {
    for (final code in const ['en', 'tr', 'fr'])
      code: lookupAppLocalizations(Locale(code)),
  };
  return {
    'version': SiriDataSync.version,
    'fetchedAt': _seconds(now),
    'items': [
      for (final u in sessions.take(SiriDataSync.maxEvents))
        {
          'id': u.event.id,
          'title': u.event.title,
          'day': mosqueDateKey(u.startsAt),
          'startsAt': _seconds(u.startsAt),
          'when': {
            for (final MapEntry(:key, :value) in locales.entries)
              key: sessionLine(value, u),
          },
          if (u.event.repeats.isRecurring)
            'next': {
              for (final MapEntry(:key, :value) in locales.entries)
                key: nextShort(value, u.startsAt),
            },
        },
    ],
  };
}

/// The mosque document, from the content bundle. Version 1:
///
/// ```json
/// {"version": 1, "name": "…", "phone": "647 834 2000",
///  "tel": "tel:+16478342000", "address": "336 Pape Avenue, Toronto, ON M4M 2W7",
///  "lat": null, "lng": null, "eventsEnabled": true}
/// ```
@visibleForTesting
Map<String, Object?> buildMosque(ContentBundle content) {
  final m = content.mosque;
  final phone = m.phone.trim();
  return {
    'version': SiriDataSync.version,
    'name': m.name,
    'phone': phone.isEmpty ? null : phone,
    'tel': phone.isEmpty ? null : telUri(phone),
    'address': m.street.trim().isEmpty
        ? null
        : '${m.street}, ${m.city} ${m.postalCode}'.trim(),
    'lat': m.lat,
    'lng': m.lng,
    'eventsEnabled': content.showEvents,
  };
}
