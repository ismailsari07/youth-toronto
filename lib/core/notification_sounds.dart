import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'reminder_settings.dart';

/// The athan recording and the sound picker's previews, via
/// ios/Runner/AppDelegate.swift. Elsewhere (Android, desktop) there is no
/// recording and previews do nothing.
abstract final class NotificationSounds {
  static const _channel =
      MethodChannel('ca.papemosque.app/notification_sound');

  /// The recording's file name in the iOS app bundle. Adding
  /// ios/Runner/Sounds/athan.caf to the Runner target is all it takes for
  /// "Athan" to appear in the picker and become the athan-time default;
  /// nothing here changes. iOS plays it only if it is 30 s or shorter.
  static const athanFile = 'athan.caf';

  static Future<bool>? _athanBundled;

  /// Whether the athan recording ships in this build. Asked once: the
  /// bundle can't change while the app runs.
  static Future<bool> athanBundled() => _athanBundled ??= _askBundled();

  static Future<bool> _askBundled() async {
    try {
      return await _channel.invokeMethod<bool>('athanBundled') ?? false;
    } catch (_) {
      return false; // no bridge on this platform
    }
  }

  /// Plays [sound] once and returns how long it lasts, or null if nothing
  /// played. The standard sound is previewed with iOS's tri-tone: apps
  /// can't play the member's own alert tone.
  static Future<Duration?> preview(ReminderSound sound) async {
    if (sound == ReminderSound.silent) return null;
    try {
      final seconds =
          await _channel.invokeMethod<double>('preview', sound.name);
      if (seconds == null) return null;
      return Duration(milliseconds: (seconds * 1000).round());
    } catch (e) {
      debugPrint('NotificationSounds: preview failed: $e');
      return null;
    }
  }

  static Future<void> stopPreview() async {
    try {
      await _channel.invokeMethod<void>('stopPreview');
    } catch (_) {
      /* nothing was playing */
    }
  }
}
