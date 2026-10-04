import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../shared/formatters.dart';
import 'mosque_time.dart';
import 'prayer_days.dart';
import 'prayer_service.dart';

/// Feeds the iOS home-screen and lock-screen widgets (ios/PrayerWidget).
///
/// The widget never touches the network: it reads one JSON document the app
/// writes into the shared App Group, holding a week of prayer instants with
/// their names and times already localised and formatted. It builds its own
/// timeline from that, so it stays right for days without the app opening.
///
/// Times come from the same rows and day rules as the reminders
/// ([scheduleDays]), on the mosque's clock. Only prayer times are stored.
class PrayerWidgetSync {
  static const _channel = MethodChannel('ca.papemosque.app/prayer_widget');

  /// Yesterday (so the widget knows which window it starts in) plus 7 days.
  static const _firstDay = -1;
  static const _dayCount = 8;

  static Future<void>? _inFlight;
  static bool _rerun = false;

  /// The last rows fetched, so a language change while offline can still
  /// rewrite the widget in the new language.
  static List<PrayerDay>? _lastDays;

  /// Safe to call any time; never throws. A call during a run queues one
  /// fresh run afterwards. Does nothing off iOS.
  static Future<void> sync() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future.value();
    }
    if (_inFlight != null) {
      _rerun = true;
      return _inFlight!;
    }
    return _inFlight = _loop();
  }

  static Future<void> _loop() async {
    try {
      do {
        _rerun = false;
        await _run();
      } while (_rerun);
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> _run() async {
    try {
      List<PrayerDay>? days;
      try {
        days = _lastDays = await PrayerService.fetchRecentDays();
      } catch (_) {
        // Offline: keep what the widget has, unless we can re-localise it.
        days = _lastDays;
      }
      if (days == null || days.isEmpty) return;

      final l = await currentAppLocalizations();
      final data = buildPrayerWidgetData(days, l, mosqueNow());
      await _channel.invokeMethod<void>('update', jsonEncode(data));
    } catch (e) {
      debugPrint('PrayerWidgetSync: update failed: $e');
    }
  }
}

/// The document the widget reads. Version 1:
///
/// ```json
/// {
///   "version": 1,
///   "locale": "tr",
///   "strings": {"nextPrayer": "SIRADAKİ NAMAZ"},
///   "prayers": [
///     {"key": "Fajr", "name": "İmsak", "at": 1759570980,
///      "time": "5:43 AM", "athan": "Ezan 5:43 AM",
///      "iqamah": "Cemaat 6:45 AM", "day": "2026-10-04"}
///   ]
/// }
/// ```
///
/// `at` is the athan instant in Unix seconds; `iqamah` is absent when the
/// row has none (Sunrise). Prayers are in time order, Sunrise included (the
/// widget lists it but never counts down to it, like the moon card).
@visibleForTesting
Map<String, Object?> buildPrayerWidgetData(
  List<PrayerDay> days,
  AppLocalizations l,
  DateTime now,
) {
  final prayers = <Map<String, Object?>>[];
  for (final (offset: _, :day, :payload) in scheduleDays(
    days,
    now,
    first: PrayerWidgetSync._firstDay,
    count: PrayerWidgetSync._dayCount,
  )) {
    for (final item in payload.dailyPrayerTimes) {
      final moment = prayerMoment(day, item.name, item.time);
      if (moment == null) continue;
      final time = prayerClock12(item.name, item.time);
      final iqamah = item.iqamah;
      prayers.add({
        'key': item.name,
        'name': prayerLabel(l, item.name),
        'at': moment.millisecondsSinceEpoch ~/ 1000,
        'time': time,
        'athan': l.athanAt(time),
        if (iqamah != null)
          'iqamah': l.iqamahAt(prayerClock12(item.name, iqamah)),
        'day': mosqueDateKey(day),
      });
    }
  }
  prayers.sort((a, b) => (a['at']! as int).compareTo(b['at']! as int));

  return {
    'version': 1,
    'locale': l.localeName,
    'strings': {'nextPrayer': l.nextPrayer},
    'prayers': prayers,
  };
}
