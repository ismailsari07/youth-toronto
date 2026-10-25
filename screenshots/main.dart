import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myt_flutter/core/push/device_identity.dart';
import 'package:myt_flutter/core/push/push_api.dart';
import 'package:myt_flutter/core/reminder_sync.dart';
import 'package:myt_flutter/core/router.dart';
import 'package:myt_flutter/features/prayer/widgets/reminders_sheet.dart';
import 'package:myt_flutter/main.dart';
import 'package:myt_flutter/shared/providers/events_news_provider.dart';
import 'package:myt_flutter/shared/providers/prayer_provider.dart';
import 'package:myt_flutter/shared/providers/push_provider.dart';
import 'package:myt_flutter/shared/providers/registration_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App Store screenshots (screenshots/take.sh on Codemagic's macOS machines).
// The real app on live Supabase data, signed out, opened on one screen per
// launch. take.sh writes `<shot> <lang>` to `tmp/shot_request` in the app's
// data container before each launch (SIMCTL_CHILD_* variables never reached
// the app on Codemagic), and photographs the simulator once `tmp/shot_ready`
// exists. shot_ready holds the `<shot> <lang>` the app actually used, which
// take.sh compares with what it asked for, or `failed: <reason>` when the
// screen can't be opened. Nothing is written to the database: no device
// registration, no event view.

/// The screens, in App Store order.
const shots = [
  'prayer_light',
  'prayer_dark',
  'community',
  'event',
  'mosque',
  'reminders',
];

/// The event the `event` shot opens, matched by title.
const eventTitle = 'Gençlik Buluşması';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (shot, lang) = await _request();

  final prefs = await SharedPreferences.getInstance();
  // The push pre-prompt never opens on its own after three "Not now"s.
  await prefs.setInt('push_prompt_dismissals', 3);
  // Prayer reminders on, all five prayers, as a member would have them.
  await prefs.setBool('prayer_reminders_enabled', true);
  // The simulator can't grant notifications: show them as allowed and
  // schedule nothing.
  // ignore: invalid_use_of_visible_for_testing_member
  ReminderSync.permissionGranted = () async => true;
  // ignore: invalid_use_of_visible_for_testing_member
  ReminderSync.schedule = (_, {required channelName, notice}) async {};

  await startApp(
    locale: Locale(lang),
    themeMode: shot == 'prayer_dark' ? ThemeMode.dark : ThemeMode.light,
    overrides: [
      pushApiProvider.overrideWithValue(const _NoWritePushApi()),
      deviceCredentialsProvider.overrideWithValue(() async => null),
    ],
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _open(shot, lang));
}

/// The shot and language take.sh asked for. Without a readable request it
/// opens the first shot in English, and shot_ready says so: take.sh then
/// fails instead of keeping a wrong picture.
Future<(String, String)> _request() async {
  try {
    final words = (await File(
      '${Directory.systemTemp.path}/shot_request',
    ).readAsString()).trim().split(RegExp(r'\s+'));
    if (words.length == 2) return (words[0], words[1]);
  } catch (_) {
    /* no request: defaults */
  }
  return (shots.first, 'en');
}

Future<void> _open(String shot, String lang) async {
  final context = rootNavigatorKey.currentContext!;
  final container = ProviderScope.containerOf(context);
  Future<void> loaded(Future<Object?> future) =>
      future.timeout(const Duration(seconds: 30)).then((_) {}, onError: (_) {});

  switch (shot) {
    case 'community':
      router.go('/community');
      await loaded(container.read(eventsProvider.future));
      await loaded(container.read(newsProvider.future));
    case 'event':
      final events = await container
          .read(eventsProvider.future)
          .timeout(const Duration(seconds: 30));
      final pick = events
          .where((e) => e.event.title.contains(eventTitle))
          .firstOrNull;
      // Never another event in its place: take.sh fails the run on this.
      if (pick == null) {
        return _ready(
          'failed: no upcoming event titled "$eventTitle" '
          '(${events.length} upcoming)',
        );
      }
      router.go('/community');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      router.push('/community/event/${pick.event.id}');
    case 'mosque':
      router.go('/profile');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      router.push('/profile/mosque');
    case 'reminders':
      router.go('/profile');
      await Future<void>.delayed(const Duration(seconds: 1));
      final profile = rootNavigatorKey.currentContext!;
      if (profile.mounted) unawaited(showRemindersSheet(profile));
    default: // prayer_light, prayer_dark
      await loaded(container.read(prayerProvider.future));
  }

  // Pages fetch their own details and photos, then animate in.
  await Future<void>.delayed(const Duration(seconds: 5));
  await _ready('$shot $lang');
}

/// Tells take.sh the screen is up (`<shot> <lang>`) or why it isn't
/// (`failed: …`). Written aside and renamed, so take.sh never reads it
/// half-written.
Future<void> _ready(String status) async {
  final temp = Directory.systemTemp.path;
  final ready = await File('$temp/shot_ready.part').writeAsString(status);
  await ready.rename('$temp/shot_ready');
}

/// The device RPCs, answered as if offline, so a screenshot run never adds
/// a device to push_devices.
class _NoWritePushApi implements PushApi {
  const _NoWritePushApi();

  @override
  Future<RegisterResult> register(DeviceIdentity id, DevicePayload payload) =>
      throw const PushException(PushError.network);

  @override
  Future<void> setEventNotifications(
    DeviceIdentity id,
    String eventId, {
    required bool enabled,
  }) => throw const PushException(PushError.network);

  @override
  Future<DeviceSettings> deviceSettings(DeviceIdentity id) =>
      throw const PushException(PushError.network);
}
