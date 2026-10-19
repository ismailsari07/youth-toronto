import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/notification_service.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/prayer_refresh.dart';
import 'package:myt_flutter/core/prayer_service.dart';
import 'package:myt_flutter/core/reminder_settings.dart';
import 'package:myt_flutter/core/reminder_sync.dart';
import 'package:myt_flutter/shared/providers/reminders_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

PrayerDay _today() => _day(0);

/// A row [offset] days from today with all five prayers at 00:01–00:05
/// (iqamah a minute later), except today, which keeps one late Isha.
PrayerDay _day(int offset) {
  final now = mosqueNow();
  final day = DateTime(now.year, now.month, now.day + offset);
  if (offset > 0) {
    return (
      date: mosqueDateKey(day),
      payload: PrayerCachePayload(
        dailyPrayerTimes: const [
          DailyPrayerItem(name: 'Fajr', time: '00:01', iqamah: '00:02'),
          DailyPrayerItem(name: 'Dhuhr', time: '12:01', iqamah: '12:02'),
          DailyPrayerItem(name: 'Asr', time: '15:01', iqamah: '15:02'),
          DailyPrayerItem(name: 'Maghrib', time: '18:01', iqamah: '18:02'),
          DailyPrayerItem(name: 'Isha', time: '21:01', iqamah: '21:02'),
        ],
        hijriDate: '',
        gregorianDate: diyanetDate(day),
        jumaaPrayerTime: '13:30',
      ),
    );
  }
  return (
    date: mosqueDateKey(day),
    payload: PrayerCachePayload(
      dailyPrayerTimes: const [
        DailyPrayerItem(name: 'Fajr', time: '00:01', iqamah: '00:02'),
        DailyPrayerItem(name: 'Isha', time: '11:58', iqamah: '11:59'),
      ],
      hijriDate: '',
      gregorianDate: diyanetDate(day),
    ),
  );
}

/// When the reminders sync, what it may ask iOS, and what it does with the
/// answer from prayer_cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initMosqueTime);

  late int asked, checked;
  late List<(int, int)> fetched;
  late List<List<Reminder>> scheduled;
  late List<Reminder?> notices;
  late bool? granted;
  late Object fetchResult;

  setUp(() {
    SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': true});
    asked = checked = 0;
    fetched = [];
    scheduled = [];
    notices = [];
    granted = true;
    fetchResult = [_today()];
    ReminderSync.askPermission = () async {
      asked++;
      return granted ?? false;
    };
    ReminderSync.permissionGranted = () async {
      checked++;
      return granted;
    };
    ReminderSync.fetchDays = ({required first, required last}) async {
      fetched.add((first, last));
      final r = fetchResult;
      if (r is Exception) throw r;
      return r as List<PrayerDay>;
    };
    ReminderSync.schedule = (reminders, {required channelName, notice}) async {
      scheduled.add(reminders);
      notices.add(notice);
    };
  });

  tearDown(() {
    ReminderSync.askPermission = NotificationService.requestPermissions;
    ReminderSync.permissionGranted = NotificationService.notificationsAllowed;
    ReminderSync.fetchDays = PrayerService.fetchDays;
    ReminderSync.schedule = NotificationService.scheduleReminders;
    prayerRefresh = refreshPrayerSchedules;
  });

  group('permission', () {
    test('launch, resume, refresh and push never show the iOS prompt', () async {
      granted = null; // iOS hasn't asked yet
      await ReminderSync.sync();
      expect(asked, 0);
      expect(checked, greaterThan(0));
    });

    test('turning reminders on asks; turning them off does not', () async {
      SharedPreferences.setMockInitialValues({});
      granted = false;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reminderSettingsProvider.notifier);
      expect((await container.read(reminderSettingsProvider.future)).enabled, isFalse);
      await notifier.setEnabled(true);
      expect(asked, 1);
      await notifier.setEnabled(false);
      expect(asked, 1);
    });

    test('not allowed: nothing fetched, nothing replaced', () async {
      granted = false;
      await ReminderSync.sync();
      expect(fetched, isEmpty);
      expect(scheduled, isEmpty);
    });
  });

  group('data', () {
    test('asks prayer_cache for as many days as the budget could use', () async {
      expect(await ReminderSync.sync(), isTrue);
      expect(fetched.single, (0, 89));
      expect(scheduled.single, isNotEmpty);
    });

    test('never more than 64 pending, notice included', () async {
      fetchResult = [for (var i = 0; i < 80; i++) _day(i)];
      for (final prayers in [
        ReminderSettings.allPrayers,
        {'Fajr', 'Asr', 'Isha'},
        {'Asr'},
        {'Dhuhr'}, // Fridays: Jumu'ah
      ]) {
        await ReminderSync.saveSettings(ReminderSettings(prayers: prayers));
        await ReminderSync.sync();
        final pending = scheduled.last.length + (notices.last == null ? 0 : 1);
        expect(pending, lessThanOrEqualTo(iosPendingLimit), reason: '$prayers');
        expect(scheduled.last.length, lessThanOrEqualTo(reminderBudget));
        expect(notices.last, isNotNull);
      }
      // One prayer a day fills the budget exactly: 63 + the notice = 64.
      expect(scheduled.last.length + 1, 64);
    });

    test('every reschedule moves the notice to the new last day', () async {
      fetchResult = [for (var i = 0; i < 3; i++) _day(i)];
      await ReminderSync.sync();
      fetchResult = [for (var i = 0; i < 6; i++) _day(i)];
      await ReminderSync.sync();
      final today = mosqueNow();
      final days = notices.map((n) => n!.at.difference(
            tz.TZDateTime(mosqueTz, today.year, today.month, today.day),
          ).inDays);
      expect(days, [2, 5]);
      expect(notices.every((n) => n!.at.hour == 10 && n.id == noticeId), isTrue);
    });

    test('reminders off: nothing scheduled, so no notice', () async {
      SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': false});
      expect(await ReminderSync.sync(), isFalse);
      expect(scheduled, isEmpty);
      expect(notices, isEmpty);
    });

    test('a failed fetch keeps what is scheduled (it came from real rows)', () async {
      fetchResult = Exception('offline');
      expect(await ReminderSync.sync(), isFalse);
      expect(scheduled, isEmpty);
    });

    test('no rows: everything pending is cleared, nothing guessed', () async {
      fetchResult = <PrayerDay>[];
      await ReminderSync.sync();
      expect(scheduled.single, isEmpty);
      expect(notices.single, isNull);
    });

    test('a change during a sync runs one more sync afterwards', () async {
      final first = ReminderSync.sync();
      final second = ReminderSync.sync();
      final third = ReminderSync.sync();
      await Future.wait([first, second, third]);
      expect(fetched, hasLength(2));
    });
  });

  group('prayer_refresh silent push', () {
    late int refreshes;
    setUp(() {
      refreshes = 0;
      prayerRefresh = () async {
        refreshes++;
        return true;
      };
    });

    test('open app: refreshes', () async {
      await handlePushData({'type': 'prayer_refresh'});
      expect(refreshes, 1);
    });

    test('in the background: refreshes', () async {
      await onBackgroundPush(const RemoteMessage(data: {'type': 'prayer_refresh'}));
      expect(refreshes, 1);
    });

    test('event and announcement pushes do not', () async {
      await handlePushData({'type': 'event', 'id': 'x'});
      await handlePushData({'type': 'announcement', 'id': 'x'});
      await handlePushData({});
      expect(refreshes, 0);
    });

    test('runs the reminder sync', () async {
      prayerRefresh = refreshPrayerSchedules;
      await handlePushData({'type': 'prayer_refresh'});
      expect(fetched.single, (0, 89));
      expect(asked, 0);
    });

    group('last background refresh (About sheet)', () {
      test('never: null', () async {
        expect(await BackgroundRefreshLog.load(), isNull);
      });

      test('recorded when a background push rescheduled', () async {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        await onBackgroundPush(const RemoteMessage(data: {'type': 'prayer_refresh'}));
        final at = await BackgroundRefreshLog.load();
        expect(at, isNotNull);
        expect(at!.isAfter(before), isTrue);
        expect(at.isUtc, isFalse); // shown in the phone's time
      });

      test('not when it did not reschedule, in the foreground, or for other pushes',
          () async {
        prayerRefresh = () async => false;
        await onBackgroundPush(const RemoteMessage(data: {'type': 'prayer_refresh'}));
        prayerRefresh = () async => true;
        await handlePushData({'type': 'prayer_refresh'});
        await onBackgroundPush(const RemoteMessage(data: {'type': 'event', 'id': 'x'}));
        expect(await BackgroundRefreshLog.load(), isNull);
      });

      test('a real sync that fails to fetch is not recorded', () async {
        prayerRefresh = refreshPrayerSchedules;
        fetchResult = Exception('offline');
        await onBackgroundPush(const RemoteMessage(data: {'type': 'prayer_refresh'}));
        expect(await BackgroundRefreshLog.load(), isNull);
      });
    });
  });
}
