import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/mosque_time.dart';
import 'core/notification_service.dart';
import 'core/prayer_service.dart';
import 'core/reminder_sync.dart';
import 'core/router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Prayer times and reminders run on Toronto time; load the zone data first.
  try {
    initMosqueTime();
  } catch (e) {
    debugPrint('Time zone init failed: $e');
  }
  try {
    await PrayerService.initialize();
  } catch (e) {
    // Supabase init failed — start anyway; data screens show their error state.
    debugPrint('Supabase init failed: $e');
  }
  try {
    await NotificationService.initialize();
  } catch (e) {
    // Reminders are optional — never let them stop the app from opening.
    debugPrint('Notification init failed: $e');
  }
  runApp(const ProviderScope(child: MytApp()));
}

class MytApp extends StatefulWidget {
  const MytApp({super.key});

  @override
  State<MytApp> createState() => _MytAppState();
}

class _MytAppState extends State<MytApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Keep the 7-day reminder window fresh: once the first frame is up (so
    // the permission prompt never blocks launch) and on every resume.
    // Fire-and-forget: ReminderSync never throws and never blocks the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) => ReminderSync.sync());
    _lifecycle = AppLifecycleListener(onResume: ReminderSync.sync);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pape Mosque',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
