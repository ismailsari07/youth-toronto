import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_row.dart';

/// The event's optional "call this number to contribute" box (pape-admin
/// migration 20261027120000). Information only, no payment. The heading and
/// text are the event's own, single-language like its title; only the
/// fallback subtitle is translated. The screen shows this only when
/// [YouthEvent.hasContribution].
class EventContributionCard extends StatelessWidget {
  const EventContributionCard({
    super.key,
    required this.heading,
    required this.phone,
    required this.onCall,
    this.text,
    this.name,
  });

  final String heading;
  final String phone;
  final String? text;
  final String? name;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final body = text;
    return GroupedRows(
      rows: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.cardPadding,
            AppSpace.cardPadding,
            AppSpace.cardPadding,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(heading, style: AppText.cardTitle.c(context.colors.ink)),
              if (body != null) ...[
                const SizedBox(height: 4),
                Text(body, style: AppText.body.c(context.colors.ink2)),
              ],
            ],
          ),
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.phone,
          title: phone,
          subtitle: name ?? context.l10n.tapToCall,
          trailing: const RowChevron(),
          onTap: onCall,
        ),
      ],
    );
  }
}
