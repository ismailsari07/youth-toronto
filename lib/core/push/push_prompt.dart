import 'package:shared_preferences/shared_preferences.dart';

/// Where iOS stands on notifications for this app. [unsupported]: not iOS,
/// or Firebase didn't start; nothing push-related is shown.
enum PushPermission { unsupported, notDetermined, authorized, denied }

/// What can open our own "turn on notifications" sheet.
enum PromptTrigger { communityVisit, eventTap, launch }

/// The rules for our pre-prompt sheet: only while iOS hasn't asked yet,
/// once per app session, never on the first launch, three days after a
/// "Not now", and never on its own after three of them. Settings always
/// works regardless.
abstract final class PushPromptRules {
  static const maxDismissals = 3;
  static const wait = Duration(days: 3);

  static bool shouldShow({
    required PromptTrigger trigger,
    required PushPermission permission,
    required int launchCount,
    required int dismissals,
    required DateTime? lastDismissedAt,
    required bool shownThisSession,
    required DateTime now,
  }) {
    if (permission != PushPermission.notDetermined) return false;
    if (shownThisSession || dismissals >= maxDismissals) return false;
    if (trigger == PromptTrigger.launch && launchCount < 2) return false;
    return lastDismissedAt == null || now.difference(lastDismissedAt) >= wait;
  }
}

/// The launch count and the sheet's dismissals, on this device.
abstract final class PushPromptStore {
  static const _launches = 'app_launch_count';
  static const _dismissals = 'push_prompt_dismissals';
  static const _lastDismissed = 'push_prompt_last_dismissed_ms';

  /// Counts this launch and returns the total (1 on the first launch).
  static Future<int> countLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = (prefs.getInt(_launches) ?? 0) + 1;
      await prefs.setInt(_launches, n);
      return n;
    } catch (_) {
      return 1;
    }
  }

  static Future<({int dismissals, DateTime? lastDismissedAt})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastDismissed);
    return (
      dismissals: prefs.getInt(_dismissals) ?? 0,
      lastDismissedAt:
          last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
    );
  }

  static Future<void> recordDismissal(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissals, (prefs.getInt(_dismissals) ?? 0) + 1);
    await prefs.setInt(_lastDismissed, now.millisecondsSinceEpoch);
  }
}
