import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native side of the Siri shortcuts (ios/Runner/AppDelegate.swift). Off
/// iOS, or on any failure, every call answers as if Siri weren't there.
abstract final class SiriBridge {
  static const channel = MethodChannel('ca.papemosque.app/siri');

  static bool get _ios =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether iOS has this app in the background right now.
  static Future<bool> isInBackground() async {
    if (!_ios) return false;
    try {
      return await channel.invokeMethod<bool>('isInBackground') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// A shortcut waiting to be acted on (`donate`), once.
  static Future<String?> takeAction() async {
    if (!_ios) return null;
    try {
      return await channel.invokeMethod<String>('takeAction');
    } catch (_) {
      return null;
    }
  }

  /// Whether a shortcut brought the app forward this session.
  static Future<bool> hadAction() async {
    if (!_ios) return false;
    try {
      return await channel.invokeMethod<bool>('hadAction') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stores one document in the App Group. Never throws.
  static Future<void> write(String key, String json) async {
    if (!_ios) return;
    try {
      await channel.invokeMethod<void>('update', {'key': key, 'json': json});
    } catch (e) {
      debugPrint('SiriBridge: write failed: $e');
    }
  }
}
