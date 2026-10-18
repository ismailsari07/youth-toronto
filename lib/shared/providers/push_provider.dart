import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/push/device_identity.dart';
import '../../core/push/push_api.dart';
import '../../core/push/push_platform.dart';
import '../../core/push/push_prompt.dart';
import '../../core/push/push_route.dart';
import '../../core/push/push_sync.dart';
import '../../l10n/l10n.dart';
import '../../l10n/locale_provider.dart';
import 'content_provider.dart';

/// Read in main() before the first frame, like the content bundle. Tests
/// and other platforms get the defaults: push unsupported, nothing shown.
final pushPlatformProvider =
    Provider<PushPlatform>((ref) => const UnsupportedPushPlatform());
final initialPushPermissionProvider =
    Provider<PushPermission>((ref) => PushPermission.unsupported);
final initialPushLocalProvider = Provider<PushLocal>((ref) => const PushLocal());
final launchCountProvider = Provider<int>((ref) => 1);

final pushApiProvider = Provider<PushApi>((ref) => const SupabasePushApi());
final identityStoreProvider =
    Provider<IdentityStore>((ref) => const KeychainIdentityStore());

@immutable
class PushState {
  const PushState({required this.permission, required this.local});

  final PushPermission permission;
  final PushLocal local;

  bool get supported => permission != PushPermission.unsupported;
  bool get denied => permission == PushPermission.denied;
  bool get events => local.events;
  bool get announcements => local.announcements;
  String? get deviceCode => local.deviceCode;
  bool eventEnabled(String eventId) => !local.muted.contains(eventId);

  PushState copyWith({PushPermission? permission, PushLocal? local}) =>
      PushState(
        permission: permission ?? this.permission,
        local: local ?? this.local,
      );
}

final pushProvider =
    NotifierProvider<PushController, PushState>(PushController.new);

/// Push on this device: registration with the server, the switches, the
/// per-event opt-outs, the iOS permission and notification taps.
class PushController extends Notifier<PushState> {
  late final PushSync _sync = PushSync(
    api: ref.read(pushApiProvider),
    identities: ref.read(identityStoreProvider),
  );
  late final PushPlatform _platform = ref.read(pushPlatformProvider);

  String? _token;
  Timer? _debounce;
  bool _started = false;
  bool _promptShown = false;
  OpenedNotifications _opened = OpenedNotifications();
  void Function(String path)? _navigate;

  static const _openedKey = 'push_opened_nids';

  @override
  PushState build() {
    // The server picks each notification's language from the app's.
    ref.listen(localeOverrideProvider, (_, _) => _registerSoon());
    ref.onDispose(() => _debounce?.cancel());
    return PushState(
      permission: ref.read(initialPushPermissionProvider),
      local: ref.read(initialPushLocalProvider),
    );
  }

  /// After the first frame: taps first (someone may be waiting on one),
  /// then a reinstall's restore, the token and the registration.
  Future<void> start({required void Function(String path) navigate}) async {
    if (_started || !state.supported) return;
    _started = true;
    _navigate = navigate;
    try {
      final prefs = await SharedPreferences.getInstance();
      _opened = OpenedNotifications(prefs.getStringList(_openedKey) ?? const []);
    } catch (_) {
      /* no history: a repeat open is merely possible */
    }
    _platform.opened.listen(_open);
    final initial = await _platform.initialOpen();
    if (initial != null) _open(initial);

    final restored = await _sync.restoreIfReinstalled();
    if (restored != null) {
      state = state.copyWith(local: restored);
    } else if (!state.local.saved) {
      await PushSync.saveSwitches(
        events: state.events,
        announcements: state.announcements,
      );
    }
    if (state.permission == PushPermission.authorized) {
      _token = await _platform.token();
    }
    _platform.tokenRefresh.listen((token) {
      _token = token;
      _register();
    });
    await _register();
  }

  /// On resume: the member may have changed the permission in Settings.
  Future<void> onResume() async {
    if (!_started) return;
    final permission = await _platform.status();
    if (permission != state.permission) {
      state = state.copyWith(permission: permission);
    }
    if (permission == PushPermission.authorized && _token == null) {
      _token = await _platform.token();
    }
    await _register();
  }

  DevicePayload? _payload() {
    final version = ref.read(appVersionProvider);
    if (version == null) return null;
    final locale = resolveAppLocale(
      ref.read(localeOverrideProvider),
      PlatformDispatcher.instance.locales,
    );
    return DevicePayload(
      token: _token,
      locale: locale.languageCode,
      appVersion: version,
      pushAuthorized: state.permission == PushPermission.authorized,
      events: state.events,
      announcements: state.announcements,
    );
  }

  Future<void> _register() async {
    final payload = _payload();
    if (!_started || payload == null) return;
    final code = await _sync.register(payload);
    if (code != null && code != state.deviceCode) {
      state = state.copyWith(local: state.local.copyWith(deviceCode: code));
    }
  }

  /// Sign-in and sign-out: the server links a device to the member who
  /// registered it last (`push_devices.user_id`), so register again even
  /// though the payload didn't change.
  Future<void> onAuthChanged() async {
    final payload = _payload();
    if (!_started || payload == null) return;
    final code = await _sync.register(payload, force: true);
    if (code != null && code != state.deviceCode) {
      state = state.copyWith(local: state.local.copyWith(deviceCode: code));
    }
  }

  /// This device's push identity for the registration RPCs, or null where
  /// push isn't supported. Never logged.
  Future<({String installId, String secret})?> credentials() async {
    if (!state.supported) return null;
    try {
      final id = await _sync.identity();
      return (installId: id.installId, secret: id.secret);
    } catch (_) {
      return null;
    }
  }

  /// The member registered for [eventId]: the server removed this device's
  /// mute, so the toggle shows on again.
  Future<void> registeredFor(String eventId) async {
    if (state.local.muted.contains(eventId)) {
      state = state.copyWith(
        local: state.local.copyWith(muted: {...state.local.muted}..remove(eventId)),
      );
    }
    await _sync.forgetMute(eventId);
  }

  /// Quick toggling sends one call.
  void _registerSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _register);
  }

  /// The iOS prompt (from our sheet, or a switch while iOS hasn't asked).
  Future<void> requestPermission() async {
    final permission = await _platform.request();
    state = state.copyWith(permission: permission);
    if (permission == PushPermission.authorized) {
      _token = await _platform.token();
    }
    await _register();
  }

  Future<void> setEvents(bool on) => _setSwitches(events: on);

  Future<void> setAnnouncements(bool on) => _setSwitches(announcements: on);

  Future<void> _setSwitches({bool? events, bool? announcements}) async {
    final local =
        state.local.copyWith(events: events, announcements: announcements);
    state = state.copyWith(local: local);
    await PushSync.saveSwitches(
      events: local.events,
      announcements: local.announcements,
    );
    final turnedOn = events == true || announcements == true;
    if (turnedOn && state.permission == PushPermission.notDetermined) {
      await requestPermission();
    } else {
      _registerSoon();
    }
  }

  /// Optimistic: the toggle moves at once and moves back if the server
  /// refuses. Returns what happened, so the page can say so on failure.
  Future<MuteOutcome> setEventEnabled(String eventId, bool enabled) async {
    final payload = _payload();
    if (payload == null) return MuteOutcome.failed;
    void apply(bool on) {
      final muted = {...state.local.muted};
      on ? muted.remove(eventId) : muted.add(eventId);
      state = state.copyWith(local: state.local.copyWith(muted: muted));
    }

    apply(enabled);
    final outcome =
        await _sync.setEvent(eventId, enabled: enabled, payload: payload);
    if (outcome == MuteOutcome.registered) {
      apply(true);
    } else if (outcome != MuteOutcome.saved) {
      apply(!enabled);
    }
    return outcome;
  }

  Future<void> openSystemSettings() => _platform.openSystemSettings();

  /// Whether [trigger] should open our pre-prompt sheet now. Claims this
  /// session's one showing when it says yes.
  Future<bool> claimPrompt(PromptTrigger trigger) async {
    if (_promptShown || state.permission != PushPermission.notDetermined) {
      return false;
    }
    final saved = await PushPromptStore.load();
    final show = PushPromptRules.shouldShow(
      trigger: trigger,
      permission: state.permission,
      launchCount: ref.read(launchCountProvider),
      dismissals: saved.dismissals,
      lastDismissedAt: saved.lastDismissedAt,
      shownThisSession: _promptShown,
      now: DateTime.now(),
    );
    if (show) _promptShown = true;
    return show;
  }

  void _open(Map<String, dynamic> data) {
    final nid = data['nid'];
    if (!_opened.firstOpen(nid is String ? nid : null)) return;
    SharedPreferences.getInstance()
        .then((p) => p.setStringList(_openedKey, _opened.seen))
        .ignore();
    _navigate?.call(pushRoute(data));
  }
}
