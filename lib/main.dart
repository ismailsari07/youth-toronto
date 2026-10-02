import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/mosque_time.dart';
import 'core/notification_service.dart';
import 'core/prayer_service.dart';
import 'core/reminder_sync.dart';
import 'core/router.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _silencePdfViewerLogs();
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
  final savedLocale = await LocaleStore.load();
  runApp(
    ProviderScope(
      overrides: [savedLocaleProvider.overrideWithValue(savedLocale)],
      child: const MytApp(),
    ),
  );
}

/// pdfrx reports every PDF it opens through `debugPrint` — in release builds
/// too, where that reaches the device log. Opening a marriage-service
/// document must never leave a trace in a log, so its lines are dropped.
/// Everything else still prints as before.
void _silencePdfViewerLogs() {
  final print = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    final text = message ?? '';
    if (text.startsWith('PdfDocument') ||
        text.startsWith('PdfViewer') ||
        text.startsWith('pdfrx')) {
      return;
    }
    print(message, wrapWidth: wrapWidth);
  };
}

class MytApp extends ConsumerStatefulWidget {
  const MytApp({super.key});

  @override
  ConsumerState<MytApp> createState() => _MytAppState();
}

class _MytAppState extends ConsumerState<MytApp> {
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
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: ref.watch(localeOverrideProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (device, _) =>
          resolveAppLocale(null, device ?? const []),
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
