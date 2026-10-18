import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_identity.dart';
import 'push_api.dart';

/// The member's push choices on this device, as last saved.
@immutable
class PushLocal {
  const PushLocal({
    this.events = true,
    this.announcements = true,
    this.muted = const {},
    this.deviceCode,
    this.saved = false,
  });

  final bool events;
  final bool announcements;

  /// Events this device opted out of (`youth_events.id`).
  final Set<String> muted;
  final String? deviceCode;

  /// False when nothing was ever stored: a first launch, or a reinstall
  /// (the Keychain identity may still be there).
  final bool saved;

  PushLocal copyWith({
    bool? events,
    bool? announcements,
    Set<String>? muted,
    String? deviceCode,
  }) =>
      PushLocal(
        events: events ?? this.events,
        announcements: announcements ?? this.announcements,
        muted: muted ?? this.muted,
        deviceCode: deviceCode ?? this.deviceCode,
        saved: saved,
      );
}

/// What happened to a per-event toggle.
enum MuteOutcome {
  saved,

  /// The event is gone or unpublished: put the toggle back, say nothing.
  gone,

  /// Couldn't save: put the toggle back and say so.
  failed,

  /// The member is registered for the event: it stays on, say nothing.
  registered,
}

/// Keeps the server's copy of this device in step with the app, within
/// the server's limits (120 calls an hour per device): `register_device`
/// only when the payload changed or a day has passed, an hour's pause
/// after a refusal, and one retry for the errors that a fresh registration
/// or a fresh identity can fix.
class PushSync {
  PushSync({
    required this.api,
    required this.identities,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final PushApi api;
  final IdentityStore identities;
  final DateTime Function() _now;

  static const refreshAfter = Duration(hours: 24);
  static const pause = Duration(hours: 1);

  static const _events = 'push_events';
  static const _announcements = 'push_announcements';
  static const _muted = 'push_muted_events';
  static const _code = 'push_device_code';
  static const _fingerprint = 'push_last_fingerprint';
  static const _lastOk = 'push_last_ok_ms';
  static const _pausedUntil = 'push_paused_until_ms';

  DeviceIdentity? _identity;

  /// A new identity starts with no muted events on the server; the next
  /// successful registration sends them again.
  bool _resendMutesPending = false;

  /// Whether [payload] must be sent: it differs from the last successful
  /// one, or that one is a day old.
  static bool needsRegister({
    required String fingerprint,
    required String? lastFingerprint,
    required DateTime? lastOkAt,
    required DateTime now,
  }) =>
      fingerprint != lastFingerprint ||
      lastOkAt == null ||
      now.difference(lastOkAt) >= refreshAfter;

  static Future<PushLocal> loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PushLocal(
        events: prefs.getBool(_events) ?? true,
        announcements: prefs.getBool(_announcements) ?? true,
        muted: (prefs.getStringList(_muted) ?? const []).toSet(),
        deviceCode: prefs.getString(_code),
        saved: prefs.containsKey(_events),
      );
    } catch (_) {
      return const PushLocal();
    }
  }

  static Future<void> saveSwitches({
    required bool events,
    required bool announcements,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_events, events);
    await prefs.setBool(_announcements, announcements);
  }

  Future<DeviceIdentity> identity() async {
    final known = _identity ?? await identities.read();
    if (known != null) return _identity = known;
    final fresh = DeviceIdentity.generate();
    await identities.write(fresh);
    return _identity = fresh;
  }

  /// The secret was refused (42501): this install starts over with a new
  /// id, so it gets a new device code.
  Future<DeviceIdentity> _replaceIdentity() async {
    final fresh = DeviceIdentity.generate();
    await identities.write(fresh);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fingerprint);
    _resendMutesPending = true;
    return _identity = fresh;
  }

  Future<bool> _paused(SharedPreferences prefs) async {
    final until = prefs.getInt(_pausedUntil);
    return until != null && _now().millisecondsSinceEpoch < until;
  }

  Future<void> _pauseAnHour(SharedPreferences prefs) => prefs.setInt(
        _pausedUntil,
        _now().add(pause).millisecondsSinceEpoch,
      );

  /// After a reinstall the Keychain still has the identity but the local
  /// choices are gone: bring them back from the server. Returns what was
  /// restored, or null when there was nothing to do (or it failed).
  Future<PushLocal?> restoreIfReinstalled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_events)) return null;
    final existing = await identities.read();
    if (existing == null) return null;
    _identity = existing;
    try {
      final s = await api.deviceSettings(existing);
      await saveSwitches(events: s.events, announcements: s.announcements);
      await prefs.setStringList(_muted, s.mutedEventIds.toList());
      await prefs.setString(_code, s.deviceCode);
      return PushLocal(
        events: s.events,
        announcements: s.announcements,
        muted: s.mutedEventIds,
        deviceCode: s.deviceCode,
        saved: true,
      );
    } on PushException catch (e) {
      if (e.error == PushError.wrongSecret) await _replaceIdentity();
      _log('device_settings', e.error);
      return null;
    }
  }

  /// Sends [payload] when it changed or a day has passed ([force]: when
  /// anything at all might be stale). Returns the device code, new or
  /// last known; null before the first success.
  Future<String?> register(DevicePayload payload, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (await _paused(prefs)) return prefs.getString(_code);
    var id = await identity();
    final lastOk = prefs.getInt(_lastOk);
    if (!force &&
        !needsRegister(
          fingerprint: payload.fingerprint(id.installId),
          lastFingerprint: prefs.getString(_fingerprint),
          lastOkAt: lastOk == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(lastOk),
          now: _now(),
        )) {
      return prefs.getString(_code);
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await api.register(id, payload);
        await prefs.setString(_code, result.deviceCode);
        if (result.throttled) {
          // Nothing was saved; the next launch or resume after the pause
          // tries again.
          await _pauseAnHour(prefs);
        } else {
          await prefs.setString(_fingerprint, payload.fingerprint(id.installId));
          await prefs.setInt(_lastOk, _now().millisecondsSinceEpoch);
          if (_resendMutesPending) {
            _resendMutesPending = false;
            await _resendMutes(id, prefs);
          }
        }
        return result.deviceCode;
      } on PushException catch (e) {
        _log('register_device', e.error);
        switch (e.error) {
          case PushError.wrongSecret when attempt == 0:
            id = await _replaceIdentity();
          case PushError.limited:
            await _pauseAnHour(prefs);
            return prefs.getString(_code);
          default:
            return prefs.getString(_code);
        }
      }
    }
    return prefs.getString(_code);
  }

  Future<void> _resendMutes(DeviceIdentity id, SharedPreferences prefs) async {
    final muted = prefs.getStringList(_muted) ?? const [];
    final kept = <String>[];
    for (final eventId in muted) {
      try {
        await api.setEventNotifications(id, eventId, enabled: false);
        kept.add(eventId);
      } on PushException catch (e) {
        // Gone, or registered (can't be muted any more): dropped.
        if (e.error != PushError.notFound && e.error != PushError.registered) {
          kept.add(eventId);
        }
      }
    }
    await prefs.setStringList(_muted, kept);
  }

  /// Turns notifications for one event off ([enabled] false) or back on.
  /// An unknown device (P0002) or a refused secret (42501) is fixed by
  /// registering and retrying once; a second P0002 while muting means the
  /// event is gone.
  Future<MuteOutcome> setEvent(
    String eventId, {
    required bool enabled,
    required DevicePayload payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (await _paused(prefs)) return MuteOutcome.failed;
    var id = await identity();
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await api.setEventNotifications(id, eventId, enabled: enabled);
        final muted = (prefs.getStringList(_muted) ?? const []).toSet();
        enabled ? muted.remove(eventId) : muted.add(eventId);
        await prefs.setStringList(_muted, muted.toList());
        return MuteOutcome.saved;
      } on PushException catch (e) {
        _log('set_event_notifications', e.error);
        switch (e.error) {
          case PushError.registered:
            await forgetMute(eventId);
            return MuteOutcome.registered;
          case PushError.notFound when attempt == 0:
            await register(payload, force: true);
            id = await identity();
          case PushError.notFound:
            return enabled ? MuteOutcome.failed : MuteOutcome.gone;
          case PushError.wrongSecret when attempt == 0:
            id = await _replaceIdentity();
            await register(payload, force: true);
          default:
            return MuteOutcome.failed;
        }
      }
    }
    return MuteOutcome.failed;
  }

  /// The server dropped this device's mute for [eventId] (the member
  /// registered for it): drop the local copy too.
  Future<void> forgetMute(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final muted = prefs.getStringList(_muted) ?? const [];
    if (!muted.contains(eventId)) return;
    await prefs.setStringList(_muted, [...muted]..remove(eventId));
  }

  static void _log(String rpc, PushError error) {
    // The RPC and the error kind only: never ids, secrets or tokens.
    debugPrint('Push: $rpc failed (${error.name})');
  }
}
