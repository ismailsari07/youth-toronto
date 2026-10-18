import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_identity.dart';

/// What the push RPCs can answer besides success (pape-admin migration
/// 20261020120000_push_notifications.sql).
enum PushError {
  /// 42501: the secret doesn't match this install id.
  wrongSecret,

  /// P0002: unknown device, or (muting) an unknown or unpublished event.
  notFound,

  /// 53400: over the hourly limit, too many muted events, or the server's
  /// brake on new devices.
  limited,

  /// 22023: the server refused the input. A bug on our side.
  invalid,

  /// P0001 registered: the member is registered for the event, so this
  /// device can't mute it (pape-admin CLAUDE.md §10.6).
  registered,

  /// No answer (offline, timeout) or anything unexpected.
  network,
}

class PushException implements Exception {
  const PushException(this.error);

  final PushError error;

  static PushError classify(Object e) => switch (e) {
        PushException(:final error) => error,
        PostgrestException(code: '42501') => PushError.wrongSecret,
        PostgrestException(code: 'P0002') => PushError.notFound,
        PostgrestException(code: '53400') => PushError.limited,
        PostgrestException(code: '22023') => PushError.invalid,
        PostgrestException(code: 'P0001', message: 'registered') =>
          PushError.registered,
        _ => PushError.network,
      };

  @override
  String toString() => 'PushException($error)';
}

/// Everything `register_device` stores except the identity. Its
/// [fingerprint] decides whether a launch needs to register again.
@immutable
class DevicePayload {
  const DevicePayload({
    required this.token,
    required this.locale,
    required this.appVersion,
    required this.pushAuthorized,
    required this.events,
    required this.announcements,
  });

  final String? token;
  final String locale; // tr, en or fr
  final String appVersion; // x.y.z, no build number
  final bool pushAuthorized;
  final bool events;
  final bool announcements;

  static const platform = 'ios';

  /// SHA-256 of the payload and the install id (a new identity must
  /// register even when nothing else changed). Never the secret.
  String fingerprint(String installId) => sha256
      .convert(utf8.encode(jsonEncode([
        installId,
        token,
        platform,
        locale,
        appVersion,
        pushAuthorized,
        events,
        announcements,
      ])))
      .toString();
}

@immutable
class RegisterResult {
  const RegisterResult({required this.deviceCode, required this.throttled});

  final String deviceCode;

  /// Over the hourly limit: nothing was saved.
  final bool throttled;
}

/// What the server holds for this install, used to restore the switches
/// after a reinstall (the Keychain survives it, local preferences don't).
@immutable
class DeviceSettings {
  const DeviceSettings({
    required this.events,
    required this.announcements,
    required this.deviceCode,
    required this.mutedEventIds,
  });

  final bool events;
  final bool announcements;
  final String deviceCode;
  final Set<String> mutedEventIds;

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => DeviceSettings(
        events: json['events'] as bool? ?? true,
        announcements: json['announcements'] as bool? ?? true,
        deviceCode: json['device_code'] as String,
        mutedEventIds: {
          for (final id in (json['muted_event_ids'] as List? ?? const []))
            id as String,
        },
      );
}

/// The three device RPCs. Every error is thrown as a [PushException].
abstract class PushApi {
  Future<RegisterResult> register(DeviceIdentity id, DevicePayload payload);

  Future<void> setEventNotifications(
    DeviceIdentity id,
    String eventId, {
    required bool enabled,
  });

  Future<DeviceSettings> deviceSettings(DeviceIdentity id);
}

class SupabasePushApi implements PushApi {
  const SupabasePushApi();

  Future<dynamic> _rpc(String name, Map<String, dynamic> params) async {
    try {
      return await Supabase.instance.client.rpc(name, params: params);
    } catch (e) {
      throw PushException(PushException.classify(e));
    }
  }

  @override
  Future<RegisterResult> register(
    DeviceIdentity id,
    DevicePayload payload,
  ) async {
    final json = await _rpc('register_device', {
      'p_install_id': id.installId,
      'p_secret': id.secret,
      'p_token': payload.token,
      'p_platform': DevicePayload.platform,
      'p_locale': payload.locale,
      'p_app_version': payload.appVersion,
      'p_push_authorized': payload.pushAuthorized,
      'p_events': payload.events,
      'p_announcements': payload.announcements,
    }) as Map<String, dynamic>;
    return RegisterResult(
      deviceCode: json['device_code'] as String,
      throttled: json['throttled'] as bool? ?? false,
    );
  }

  @override
  Future<void> setEventNotifications(
    DeviceIdentity id,
    String eventId, {
    required bool enabled,
  }) =>
      _rpc('set_event_notifications', {
        'p_install_id': id.installId,
        'p_secret': id.secret,
        'p_event_id': eventId,
        'p_enabled': enabled,
      });

  @override
  Future<DeviceSettings> deviceSettings(DeviceIdentity id) async {
    final json = await _rpc('device_settings', {
      'p_install_id': id.installId,
      'p_secret': id.secret,
    }) as Map<String, dynamic>;
    return DeviceSettings.fromJson(json);
  }
}
