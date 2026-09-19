import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/unread_store.dart';
import 'events_news_provider.dart';

/// The last announcement the reader has seen, from this device's storage.
final lastSeenAnnouncementProvider = FutureProvider<DateTime?>((ref) async {
  return UnreadStore.lastSeen();
});

/// Announcements published since then.
final unreadAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final items = ref.watch(newsProvider).valueOrNull ?? const <Announcement>[];
  final lastSeen = ref.watch(lastSeenAnnouncementProvider).valueOrNull;
  if (lastSeen == null) return items;
  return items.where((a) => a.date.isAfter(lastSeen)).toList();
});

final hasUnreadAnnouncementsProvider = Provider<bool>(
  (ref) => ref.watch(unreadAnnouncementsProvider).isNotEmpty,
);

/// Marks everything up to the newest announcement as seen, then refreshes the
/// derived state. Takes the container so it works from widgets and providers
/// alike.
Future<void> markAnnouncementsSeen(ProviderContainer container) async {
  final items =
      container.read(newsProvider).valueOrNull ?? const <Announcement>[];
  if (items.isEmpty) return;
  final newest =
      items.map((a) => a.date).reduce((a, b) => a.isAfter(b) ? a : b);
  await UnreadStore.markSeen(newest);
  container.invalidate(lastSeenAnnouncementProvider);
}
