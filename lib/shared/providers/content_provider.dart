import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_bundle.dart';
import '../../core/content/content_repository.dart';

/// The cached or bundled content, read in main() before the first frame so
/// no screen is ever empty. Tests get [ContentBundle.empty].
final initialContentProvider = Provider<ContentBundle>(
  (ref) => ContentBundle.empty,
);

/// The content the screens show. Starts with [initialContentProvider] and
/// switches to the live bundle when a fetch succeeds.
final contentProvider = NotifierProvider<ContentNotifier, ContentBundle>(
  ContentNotifier.new,
);

class ContentNotifier extends Notifier<ContentBundle> {
  static const refetchAfter = Duration(minutes: 15);

  DateTime? _fetchedAt;
  bool _fetching = false;

  @override
  ContentBundle build() => ref.watch(initialContentProvider);

  /// Fetches the bundle in the background. Without [force], only when the
  /// last successful fetch is [refetchAfter] old. A failure keeps what is
  /// shown and is retried on the next call.
  Future<void> refresh({bool force = false}) async {
    final last = _fetchedAt;
    if (_fetching ||
        (!force &&
            last != null &&
            DateTime.now().difference(last) < refetchAfter)) {
      return;
    }
    _fetching = true;
    try {
      final bundle = await ContentRepository.fetch();
      if (bundle != null) {
        state = bundle;
        _fetchedAt = DateTime.now();
      }
    } catch (_) {
      debugPrint('Content fetch failed');
    } finally {
      _fetching = false;
    }
  }
}

/// This build's version (`1.0.1`), read in main(); null if it couldn't be
/// read, and then the update screen never shows.
final appVersionProvider = Provider<String?>((ref) => null);

/// True when the panel's minimum supported version is above this build's.
/// See [ContentBundle.requiresUpdate] for when it never blocks.
final updateRequiredProvider = Provider<bool>((ref) {
  final version = ref.watch(appVersionProvider);
  return version != null && ref.watch(contentProvider).requiresUpdate(version);
});
