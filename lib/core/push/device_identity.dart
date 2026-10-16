import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

/// Who this install is to the push server: a random id and a secret only
/// this device knows (the server keeps its SHA-256). Never logged, and the
/// secret is sent nowhere but the push RPCs.
@immutable
class DeviceIdentity {
  const DeviceIdentity({required this.installId, required this.secret});

  final String installId;
  final String secret;

  /// A new UUID v4 and 32 random bytes as unpadded base64url (43 chars;
  /// the server accepts `[A-Za-z0-9_-]{32,128}`), both from a secure source.
  factory DeviceIdentity.generate([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return DeviceIdentity(
      installId: const Uuid().v4(config: V4Options(null, CryptoRNG())),
      secret: base64Url.encode(bytes).replaceAll('=', ''),
    );
  }
}

/// Where the identity lives. The Keychain one survives a reinstall, which
/// is what brings the same device code and settings back.
abstract class IdentityStore {
  Future<DeviceIdentity?> read();
  Future<void> write(DeviceIdentity identity);
}

class KeychainIdentityStore implements IdentityStore {
  const KeychainIdentityStore();

  static const _installKey = 'push_install_id';
  static const _secretKey = 'push_device_secret';

  // first_unlock: readable after a reboot once the phone has been unlocked
  // once, so a token refresh in the background can still register.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<DeviceIdentity?> read() async {
    final installId = await _storage.read(key: _installKey);
    final secret = await _storage.read(key: _secretKey);
    if (installId == null || secret == null) return null;
    return DeviceIdentity(installId: installId, secret: secret);
  }

  @override
  Future<void> write(DeviceIdentity identity) async {
    await _storage.write(key: _installKey, value: identity.installId);
    await _storage.write(key: _secretKey, value: identity.secret);
  }
}
