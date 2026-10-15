import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/donations/donation_funds.dart';
import '../../l10n/l10n.dart';
import '../../shared/providers/content_provider.dart';
import '../../shared/providers/donations_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_row.dart';
import '../../ui/components/app_sheet.dart';

/// The donate sheet, opened by the heart on Prayer and the Donate row on
/// Profile: one row per active fund, then "All donation options". Every row
/// closes the sheet and opens the website in Safari; Apple requires
/// donations to happen outside the app, so there is no form or web view
/// here. With no funds (first launch offline), only "All donation options"
/// shows.
Future<void> showDonateSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const DonateSheet(),
  );
}

class DonateSheet extends ConsumerWidget {
  const DonateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final funds = ref.watch(donationFundsProvider);
    final base = ref.watch(contentProvider).links.donation;

    void open(Uri uri) {
      Navigator.of(context).pop();
      _launch(uri);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.ground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.grabber,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.donation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(context.colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              l.donateSheetNote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5).c(context.colors.ink3),
            ),
            const SizedBox(height: 18),
            // Scrolls only when a long fund list or large text needs it.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (funds.isNotEmpty) ...[
                      GroupedRows(
                        rows: [
                          for (final (i, fund) in funds.indexed)
                            AppListRow(
                              divided: i > 0,
                              icon: AppIcons.heart,
                              title: fund.title,
                              trailing: const RowChevron(),
                              onTap: () => open(
                                DonationFunds.pageUri(base, fund: fund.slug),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.cardGapWide),
                    ],
                    GroupedRows(
                      rows: [
                        AppListRow(
                          icon: AppIcons.globe,
                          title: l.allDonationOptions,
                          trailing: const RowChevron(),
                          onTap: () => open(DonationFunds.pageUri(base)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launch(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    /* nothing to do: the sheet has closed and Safari didn't open */
  }
}
