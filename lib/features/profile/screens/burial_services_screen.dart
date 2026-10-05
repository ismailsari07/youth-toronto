import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/burial_info.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Profile → Mosque services → Burial services: who to call, and the
/// community's cemetery in Ajax.
class BurialServicesScreen extends StatelessWidget {
  const BurialServicesScreen({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the button simply does not navigate */
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = const TextStyle(fontSize: 14.5, height: 1.5).c(AppColor.ink2);
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.burialEyebrow, title: l.burialServices),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Text(l.burialIntro, style: body),
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.burialContacts),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    for (final (i, c) in BurialInfo.contacts.indexed)
                      AppListRow(
                        divided: i > 0,
                        icon: AppIcons.person,
                        title: c.name,
                        subtitle: c.phone,
                        trailing: SizedBox(
                          width: 104,
                          child: GhostButton(
                            label: l.call,
                            icon: AppIcons.phone,
                            height: 38,
                            onTap: () => _open(c.uri),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.burialCemetery),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.burialCemeteryHistory, style: body),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AppColor.hairline),
                      ),
                      Text(
                        BurialInfo.cemeteryName,
                        style: AppText.cardTitle.c(AppColor.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${BurialInfo.cemeteryStreet}\n'
                        '${BurialInfo.cemeteryCity}',
                        style: const TextStyle(fontSize: 13.5, height: 1.45)
                            .c(AppColor.ink2),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: l.directions,
                        height: 46,
                        icon: AppIcons.navigate,
                        onTap: () => _open(BurialInfo.cemeteryMapsUri),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
