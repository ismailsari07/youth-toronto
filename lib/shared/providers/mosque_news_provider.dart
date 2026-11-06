import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/news/mosque_news.dart';

/// Published news, newest first. Offline it falls back to the last good list.
final mosqueNewsProvider = FutureProvider<List<MosqueNews>>((ref) async {
  try {
    return await MosqueNewsService.fetch();
  } catch (_) {
    return MosqueNewsService.loadCached();
  }
});

/// The Community tab's segment. Kept here so the home screen's "See all" can
/// open the news segment even before the tab has been built.
enum CommunitySegment { events, announcements, news }

final communitySegmentProvider =
    StateProvider<CommunitySegment>((ref) => CommunitySegment.events);
