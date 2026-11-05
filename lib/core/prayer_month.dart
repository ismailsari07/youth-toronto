import 'package:flutter/foundation.dart';

import 'models.dart';
import 'prayer_days.dart';
import 'prayer_service.dart';

/// One calendar day of the monthly view; no [payload] means no usable row.
typedef MonthDay = ({DateTime day, PrayerCachePayload? payload});

/// Every calendar day from [now]'s date to the last row in [rows]. Same rule
/// as the reminders and the widget ([scheduleDays]): a day without its own row,
/// or with another day's data under its date, has no payload, and nothing is
/// filled. Nothing is listed after the last row, because there is no data there.
List<MonthDay> monthDays(List<PrayerDay> rows, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime? last;
  for (final row in rows) {
    final date = DateTime.tryParse(row.date);
    if (date == null || date.isBefore(today)) continue;
    if (last == null || date.isAfter(last)) last = date;
  }
  if (last == null) return const [];

  // Counted in UTC: a local day can be 23 hours long, and DST can't change this.
  final count = DateTime.utc(last.year, last.month, last.day)
          .difference(DateTime.utc(today.year, today.month, today.day))
          .inDays +
      1;
  final real = {
    for (final d in scheduleDays(rows, today, count: count)) d.offset: d.payload,
  };
  return [
    for (var i = 0; i < count; i++)
      (day: DateTime(today.year, today.month, today.day + i), payload: real[i]),
  ];
}

/// The rows the reminders already fetched, so the monthly view usually needs no
/// call of its own. In memory only, like today's times on the home screen.
abstract final class PrayerRows {
  /// As far ahead as anything asks: more than prayer_cache's ~30 days.
  static const windowLastDay = 89;

  /// Same rhythm as the panel's content on resume.
  static const maxAge = Duration(minutes: 15);

  @visibleForTesting
  static Future<List<PrayerDay>> Function({required int first, required int last}) load =
      PrayerService.fetchDays;
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Ticks when the rows are known to be out of date, so an open view reloads.
  static final changed = ValueNotifier<int>(0);

  static List<PrayerDay>? _rows;
  static DateTime? _at;
  static Future<List<PrayerDay>>? _loading;
  static int _generation = 0;

  /// [PrayerService.fetchDays], keeping the result when it covers the window.
  /// Calls for the window while one is running share it. Throws as that does.
  static Future<List<PrayerDay>> fetchDays({required int first, required int last}) {
    if (first != 0 || last != windowLastDay) return load(first: first, last: last);
    final running = _loading;
    if (running != null) return running;
    final future = _loadWindow(_generation);
    _loading = future;
    future.whenComplete(() {
      if (identical(_loading, future)) _loading = null;
    }).ignore();
    return future;
  }

  static Future<List<PrayerDay>> _loadWindow(int generation) async {
    final rows = await load(first: 0, last: windowLastDay);
    // Forgotten while loading: this answer may be the old one.
    if (generation == _generation) {
      _rows = rows;
      _at = clock();
    }
    return rows;
  }

  /// The kept rows while they're fresh, else a call. When that fails, the kept
  /// rows if any (they were real, and [forget] drops any known to be wrong).
  static Future<List<PrayerDay>> window() async {
    final rows = _rows, at = _at;
    if (rows != null && at != null && clock().difference(at) < maxAge) return rows;
    try {
      return await fetchDays(first: 0, last: windowLastDay);
    } catch (_) {
      final kept = _rows;
      if (kept != null) return kept;
      rethrow;
    }
  }

  /// A row changed or a refresh was asked for.
  static void forget() {
    _rows = null;
    _at = null;
    _loading = null;
    _generation++;
    changed.value++;
  }

  @visibleForTesting
  static void reset() {
    _rows = null;
    _at = null;
    _loading = null;
    _generation++;
    load = PrayerService.fetchDays;
    clock = DateTime.now;
  }
}
