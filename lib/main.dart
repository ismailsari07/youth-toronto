import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notification_service.dart';
import 'core/prayer_service.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await PrayerService.initialize();
  } catch (_) {
    // Supabase credentials are placeholders — skip until configured
  }
  await NotificationService.initialize();
  runApp(const ProviderScope(child: MytApp()));
}

class MytApp extends StatelessWidget {
  const MytApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MYT',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
