import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/donations/donation_funds.dart';

/// The cached fund list, read in main() before the first frame. Tests and a
/// first launch get none, and the menu offers only "All donation options".
final initialDonationFundsProvider = Provider<List<DonationFund>>(
  (ref) => const [],
);

/// The funds the donate menu lists. Starts with the cached list and
/// switches to the live one when a fetch succeeds.
final donationFundsProvider =
    NotifierProvider<DonationFundsNotifier, List<DonationFund>>(
  DonationFundsNotifier.new,
);

class DonationFundsNotifier extends Notifier<List<DonationFund>> {
  static const refetchAfter = Duration(minutes: 15);

  DateTime? _fetchedAt;
  bool _fetching = false;

  @override
  List<DonationFund> build() => ref.watch(initialDonationFundsProvider);

  /// Same rhythm as the content bundle: at launch, and on resume once the
  /// last fetch is [refetchAfter] old. A failure keeps what is shown.
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
      state = await DonationFunds.fetch();
      _fetchedAt = DateTime.now();
    } catch (_) {
      debugPrint('Donation funds fetch failed');
    } finally {
      _fetching = false;
    }
  }
}
