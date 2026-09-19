import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unread announcements are derived on-device: anything published after the
/// last time the reader opened the list is unread. Nothing is written to the
/// server, so this works signed out and across reinstalls without a backend.
abstract final class UnreadStore {
  static const _key = 'announcements_last_seen';

  static Future<DateTime?> lastSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('UnreadStore: read failed: $e');
      return null;
    }
  }

  /// Records [moment] (the newest announcement the reader has seen). Never
  /// moves backwards.
  static Future<void> markSeen(DateTime moment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = DateTime.tryParse(prefs.getString(_key) ?? '');
      if (previous != null && !moment.isAfter(previous)) return;
      await prefs.setString(_key, moment.toIso8601String());
    } catch (e) {
      debugPrint('UnreadStore: write failed: $e');
    }
  }
}
