import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sign in with Apple / Google helpers that need no network (since 1.1.0).
/// The sign-in calls themselves are in AuthService.

/// Native Apple and Google sign-in exist only in the iOS app (no Android
/// Google config on purpose, as with push). Tests flip it with
/// debugDefaultTargetPlatformOverride.
bool get socialSignInSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// A fresh random nonce for one sign-in: Apple and Google get its SHA-256
/// ([hashNonce]), Supabase the raw value, and Supabase checks they match.
String generateRawNonce([Random? random]) {
  final r = random ?? Random.secure();
  return base64UrlEncode(List<int>.generate(32, (_) => r.nextInt(256)))
      .replaceAll('=', '');
}

String hashNonce(String raw) => sha256.convert(utf8.encode(raw)).toString();

/// Apple's given and family name, as one line, or null when Apple shared
/// none (every sign-in after the first, or the user removed it).
String? appleFullName(String? given, String? family) {
  final parts = [given, family]
      .map((s) => (s ?? '').trim())
      .where((s) => s.isNotEmpty);
  final name = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ');
  return name.isEmpty ? null : name;
}

/// Whether `user_profiles.full_name` is still the value the database chose
/// (empty for Apple, else the part of the email before the @). Same test as
/// `set_my_initial_name()`, which refuses any other name.
bool isAutomaticName(String? fullName, String? email) {
  if (fullName == null) return false;
  if (fullName.isEmpty) return true;
  final e = email ?? '';
  final at = e.indexOf('@');
  return fullName == (at < 0 ? e : e.substring(0, at));
}

/// The name Apple gave on the first sign-in, kept in the Keychain until
/// `set_my_initial_name()` has stored it: Apple never sends it again, so a
/// failed save must not lose it. Tied to the account it came with; never
/// logged.
class PendingAppleName {
  static const _key = 'pending_apple_name';
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> save(String userId, String name) async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({'uid': userId, 'name': name}),
      );
    } catch (_) {
      // Without the Keychain the name is only tried once, right away.
    }
  }

  /// Sends a waiting name for [currentUserId] with [send], which returns
  /// true when the name no longer needs sending (saved, or the server says
  /// it never will be). A name left by another account waits for that
  /// account (it is cleared when an account is deleted).
  static Future<void> flush(
    String? currentUserId,
    Future<bool> Function(String name) send,
  ) async {
    if (currentUserId == null) return;
    final ({String uid, String name})? pending;
    try {
      pending = _parse(await _storage.read(key: _key));
    } catch (_) {
      return;
    }
    if (pending == null) return;
    if (pending.uid != currentUserId) return;
    if (await send(pending.name)) await clear();
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }

  static ({String uid, String name})? _parse(String? raw) {
    if (raw == null) return null;
    try {
      final v = jsonDecode(raw);
      if (v is Map && v['uid'] is String && v['name'] is String) {
        return (uid: v['uid'] as String, name: v['name'] as String);
      }
    } catch (_) {}
    return null;
  }
}
