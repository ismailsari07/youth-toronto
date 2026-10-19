import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/core/mosque_time.dart';
import 'package:myt_flutter/core/notification_service.dart';
import 'package:myt_flutter/core/prayer_days.dart';
import 'package:myt_flutter/core/prayer_refresh.dart';
import 'package:myt_flutter/core/prayer_service.dart';
import 'package:myt_flutter/core/reminder_sync.dart';
import 'package:myt_flutter/shared/providers/reminders_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PrayerDay _today() {
  final now = mosqueNow();
  final day = DateTime(now.year, now.month, now.day);
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
  late bool? granted;
  late Object fetchResult;

  setUp(() {
    SharedPreferences.setMockInitialValues({'prayer_reminders_enabled': true});
    asked = checked = 0;
    fetched = [];
    scheduled = [];
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
    ReminderSync.schedule = (reminders, {required channelName}) async {
      scheduled.add(reminders);
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
    test('asks prayer_cache for today and the next 4 days only', () async {
      await ReminderSync.sync();
      expect(fetched.single, (0, 4));
      expect(scheduled.single, isNotEmpty);
    });

    test('a failed fetch keeps what is scheduled (it came from real rows)', () async {
      fetchResult = Exception('offline');
      await ReminderSync.sync();
      expect(scheduled, isEmpty);
    });

    test('no rows: everything pending is cleared, nothing guessed', () async {
      fetchResult = <PrayerDay>[];
      await ReminderSync.sync();
      expect(scheduled.single, isEmpty);
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
      prayerRefresh = () async => refreshes++;
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
      expect(fetched.single, (0, 4));
      expect(asked, 0);
    });
  });
}
