import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/push/push_prompt.dart';
import 'package:myt_flutter/core/push/push_route.dart';

void main() {
  const event = '0b9f3c8e-2d1a-4c5b-9e7f-112233445566';
  const announcement = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';

  group('tap routing', () {
    test('event, with or without its session date', () {
      expect(
        pushRoute({'type': 'event', 'event_id': event}),
        '/community/event/$event',
      );
      expect(
        pushRoute({
          'type': 'event',
          'event_id': event,
          'occurrence': '2026-10-20',
        }),
        '/community/event/$event?occurrence=2026-10-20',
      );
    });

    test('announcement', () {
      expect(
        pushRoute({'type': 'announcement', 'announcement_id': announcement}),
        '/community/announcement/$announcement',
      );
    });

    test('an event link wins over an announcement link', () {
      expect(
        pushRoute({'event_id': event, 'announcement_id': announcement}),
        '/community/event/$event',
      );
    });

    test('neither, an unknown type or a malformed id: Community', () {
      expect(pushRoute({'type': 'broadcast', 'nid': 'x'}), '/community');
      expect(pushRoute({'type': 'something-new'}), '/community');
      expect(pushRoute({'event_id': '../profile'}), '/community');
      expect(pushRoute({'announcement_id': 42}), '/community');
      expect(pushRoute(const {}), '/community');
    });

    test('a malformed session date is dropped', () {
      expect(
        pushRoute({'event_id': event, 'occurrence': 'tomorrow'}),
        '/community/event/$event',
      );
    });
  });

  group('opened notifications', () {
    test('the same nid opens once', () {
      final opened = OpenedNotifications();
      expect(opened.firstOpen('n1'), isTrue);
      expect(opened.firstOpen('n1'), isFalse);
      expect(opened.firstOpen('n2'), isTrue);
    });

    test('remembers across launches, the last 50 only', () {
      final opened = OpenedNotifications(['n0']);
      expect(opened.firstOpen('n0'), isFalse);
      for (var i = 1; i <= 60; i++) {
        opened.firstOpen('n$i');
      }
      expect(opened.seen.length, OpenedNotifications.keep);
      expect(opened.firstOpen('n60'), isFalse);
      expect(opened.firstOpen('n5'), isTrue);
    });

    test('a notification without an id always opens', () {
      final opened = OpenedNotifications();
      expect(opened.firstOpen(null), isTrue);
      expect(opened.firstOpen(null), isTrue);
    });
  });

  group('pre-prompt', () {
    final now = DateTime(2026, 10, 15, 12);

    bool show({
      PromptTrigger trigger = PromptTrigger.communityVisit,
      PushPermission permission = PushPermission.notDetermined,
      int launchCount = 1,
      int dismissals = 0,
      DateTime? lastDismissedAt,
      bool shownThisSession = false,
    }) =>
        PushPromptRules.shouldShow(
          trigger: trigger,
          permission: permission,
          launchCount: launchCount,
          dismissals: dismissals,
          lastDismissedAt: lastDismissedAt,
          shownThisSession: shownThisSession,
          now: now,
        );

    test('first Community visit or event tap, even on the first launch', () {
      expect(show(trigger: PromptTrigger.communityVisit), isTrue);
      expect(show(trigger: PromptTrigger.eventTap), isTrue);
    });

    test('a launch counts from the second one', () {
      expect(show(trigger: PromptTrigger.launch, launchCount: 1), isFalse);
      expect(show(trigger: PromptTrigger.launch, launchCount: 2), isTrue);
    });

    test('once per session', () {
      expect(show(shownThisSession: true), isFalse);
    });

    test('only while iOS has not asked', () {
      for (final p in [
        PushPermission.authorized,
        PushPermission.denied,
        PushPermission.unsupported,
      ]) {
        expect(show(permission: p), isFalse, reason: '$p');
      }
    });

    test('three days after "Not now"', () {
      final dismissed = now.subtract(const Duration(days: 3));
      expect(show(dismissals: 1, lastDismissedAt: dismissed), isTrue);
      expect(
        show(
          dismissals: 1,
          lastDismissedAt: dismissed.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('never on its own after three dismissals', () {
      final long = now.subtract(const Duration(days: 90));
      expect(show(dismissals: 2, lastDismissedAt: long), isTrue);
      expect(show(dismissals: 3, lastDismissedAt: long), isFalse);
    });
  });
}
