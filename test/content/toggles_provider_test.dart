import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/models.dart';
import 'package:myt_flutter/shared/providers/content_provider.dart';
import 'package:myt_flutter/shared/providers/events_news_provider.dart';
import 'package:myt_flutter/shared/providers/unread_provider.dart';

void main() {
  ContentBundle withAnnouncements(bool on) => ContentBundle.parse(
    {
      'content': {
        'app_config': {
          'features': {'announcements': on},
        },
      },
    },
    fallback: ContentBundle.empty,
    source: ContentSource.live,
  );

  ProviderContainer container(bool announcementsOn) {
    final c = ProviderContainer(
      overrides: [
        initialContentProvider.overrideWithValue(
          withAnnouncements(announcementsOn),
        ),
        newsProvider.overrideWith(
          (ref) async => [
            Announcement(
              id: 'a',
              title: 'Duyuru',
              description: 'Metin',
              createdAt: DateTime.utc(2026, 10, 8),
              publishedAt: DateTime.utc(2026, 10, 8),
            ),
          ],
        ),
        lastSeenAnnouncementProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('an unread announcement badges the Community tab', () async {
    final c = container(true);
    await c.read(newsProvider.future);
    await c.read(lastSeenAnnouncementProvider.future);
    expect(c.read(hasUnreadAnnouncementsProvider), isTrue);
  });

  test('no badge while announcements are turned off', () async {
    final c = container(false);
    await c.read(newsProvider.future);
    await c.read(lastSeenAnnouncementProvider.future);
    expect(c.read(hasUnreadAnnouncementsProvider), isFalse);
  });
}
