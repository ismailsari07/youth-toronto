import 'package:myt_flutter/core/push/device_identity.dart';
import 'package:myt_flutter/core/push/push_api.dart';

/// Answers from a script, and records every call.
class FakePushApi implements PushApi {
  final calls = <String>[];
  final registered = <DeviceIdentity>[];
  final mutes = <(String, bool)>[];

  /// Errors to throw, in order, per RPC; then success.
  final registerErrors = <PushError>[];
  final eventErrors = <PushError>[];
  bool throttle = false;
  DeviceSettings? settings;
  PushError? settingsError;

  @override
  Future<RegisterResult> register(
    DeviceIdentity id,
    DevicePayload payload,
  ) async {
    calls.add('register');
    if (registerErrors.isNotEmpty) {
      throw PushException(registerErrors.removeAt(0));
    }
    registered.add(id);
    return RegisterResult(deviceCode: 'ABCD2345', throttled: throttle);
  }

  @override
  Future<void> setEventNotifications(
    DeviceIdentity id,
    String eventId, {
    required bool enabled,
  }) async {
    calls.add('event');
    if (eventErrors.isNotEmpty) throw PushException(eventErrors.removeAt(0));
    mutes.add((eventId, enabled));
  }

  @override
  Future<DeviceSettings> deviceSettings(DeviceIdentity id) async {
    calls.add('settings');
    final error = settingsError;
    if (error != null) throw PushException(error);
    return settings!;
  }
}

class MemoryIdentityStore implements IdentityStore {
  MemoryIdentityStore([this.identity]);

  DeviceIdentity? identity;
  int writes = 0;

  @override
  Future<DeviceIdentity?> read() async => identity;

  @override
  Future<void> write(DeviceIdentity identity) async {
    writes++;
    this.identity = identity;
  }
}
