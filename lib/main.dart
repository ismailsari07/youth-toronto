import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import 'core/auth_service.dart';
import 'core/content/content_repository.dart';
import 'core/donations/donation_funds.dart';
import 'core/mosque_time.dart';
import 'core/notification_service.dart';
import 'core/prayer_service.dart';
import 'core/push/push_platform.dart';
import 'core/push/push_prompt.dart';
import 'core/push/push_sync.dart';
import 'core/prayer_widget_sync.dart';
import 'core/reminder_sync.dart';
import 'core/router.dart';
import 'features/push/push_prompt_sheet.dart';
import 'features/update/screens/update_required_screen.dart';
import 'l10n/l10n.dart';
import 'l10n/locale_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/content_provider.dart';
import 'shared/providers/donations_provider.dart';
import 'shared/providers/push_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';
import 'ui/components/app_text_input.dart';

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
  // Push (iOS only): Firebase, iOS's current answer and the saved choices,
  // so Settings and the event page show the right state on the first frame.
  final pushPlatform = await PushPlatform.start();
  var pushPermission = PushPermission.unsupported;
  try {
    pushPermission = await pushPlatform.status();
  } catch (_) {
    /* push stays off this launch */
  }
  final pushLocal = await PushSync.loadLocal();
  final launchCount = await PushPromptStore.countLaunch();
  final savedLocale = await LocaleStore.load();
  final savedThemeMode = await ThemeModeStore.load();
  // The last good content bundle, else the one shipped in the app. Local
  // only; the network fetch runs after the first frame.
  final content = await ContentRepository.loadLocal();
  final donationFunds = await DonationFunds.loadCached();
  String? appVersion;
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    // Unknown version: the update screen never shows.
  }
  runApp(
    ProviderScope(
      overrides: [
        savedLocaleProvider.overrideWithValue(savedLocale),
        savedThemeModeProvider.overrideWithValue(savedThemeMode),
        initialContentProvider.overrideWithValue(content),
        initialDonationFundsProvider.overrideWithValue(donationFunds),
        appVersionProvider.overrideWithValue(appVersion),
        pushPlatformProvider.overrideWithValue(pushPlatform),
        initialPushPermissionProvider.overrideWithValue(pushPermission),
        initialPushLocalProvider.overrideWithValue(pushLocal),
        launchCountProvider.overrideWithValue(launchCount),
      ],
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
    // Keep the 7-day reminder window and the iOS widget's week of times
    // fresh: once the first frame is up (so the permission prompt never
    // blocks launch) and on every resume. Fire-and-forget: neither sync
    // throws or blocks the UI, and the widget's doesn't wait on the
    // reminders' permission prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSchedules();
      // The panel's content: at every launch, and on resume once it's
      // 15 minutes old. In the background; screens keep what they show.
      ref.read(contentProvider.notifier).refresh(force: true);
      ref.read(donationFundsProvider.notifier).refresh(force: true);
      ref.read(pushProvider.notifier).start(navigate: _openFromNotification);
      // An Apple name whose save failed at sign-in (Apple never resends it).
      AuthService.flushPendingName().then((saved) {
        if (saved && mounted) ref.invalidate(userProfileProvider);
      });
      // From the second launch on, our pre-prompt may ask (once).
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        final context = rootNavigatorKey.currentContext;
        if (mounted && context != null && context.mounted) {
          maybeShowPushPrompt(context, ref, PromptTrigger.launch);
        }
      });
    });
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // The server links this device to whoever registered it last
    // (push_devices.user_id): tell it after every sign-in and sign-out.
    ref.listenManual(authStateProvider, (_, next) {
      final event = next.valueOrNull?.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        ref.read(pushProvider.notifier).onAuthChanged();
      }
    });
  }

  void _onResume() {
    _syncSchedules();
    ref.read(contentProvider.notifier).refresh();
    ref.read(donationFundsProvider.notifier).refresh();
    ref.read(pushProvider.notifier).onResume();
  }

  /// A tapped notification: its event or announcement over the current
  /// screen, or the Community tab when it links to neither.
  void _openFromNotification(String path) {
    if (path == '/community') {
      router.go(path);
    } else {
      router.push(path);
    }
  }

  void _syncSchedules() {
    ReminderSync.sync();
    PrayerWidgetSync.sync();
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
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // Below the panel's minimum version (and only then) the update screen
      // replaces the whole app; nothing else is reachable.
      // Status-bar icons follow the theme: dark over the light ground,
      // light over the dark one (the Prayer hero sets its own).
      // The keyboard's Done bar (iOS) sits over every screen and sheet.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: statusBarOver(Theme.of(context).brightness),
        child: KeyboardAccessoryHost(
          child: ref.watch(updateRequiredProvider)
              ? const UpdateRequiredScreen()
              : child!,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
