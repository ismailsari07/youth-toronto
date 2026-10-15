import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/donations/donation_funds.dart';
import '../../l10n/l10n.dart';
import '../../shared/providers/content_provider.dart';
import '../../shared/providers/donations_provider.dart';
import '../../theme/app_icon.dart';
import '../../ui/components/pull_down_menu.dart';

/// The donate menu, opened by the heart on Prayer and the Donate row on
/// Profile: one item per active fund, then "All donation options". Every
/// item opens the website in Safari; Apple requires donations to happen
/// outside the app, so there is no form or web view here. With no funds
/// (first launch offline), only "All donation options" shows.
Future<void> showDonateMenu(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final funds = ref.read(donationFundsProvider);
  final base = ref.read(contentProvider).links.donation;
  return showPullDownMenu(
    context,
    title: l.donateMenuTitle,
    sections: [
      [
        for (final fund in funds)
          PullDownItem(
            title: fund.title,
            onTap: () => _open(DonationFunds.pageUri(base, fund: fund.slug)),
          ),
      ],
      [
        PullDownItem(
          title: l.allDonationOptions,
          icon: AppIcons.globe,
          onTap: () => _open(DonationFunds.pageUri(base)),
        ),
      ],
    ],
  );
}

Future<void> _open(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    /* nothing to do: the menu has closed and Safari didn't open */
  }
}
