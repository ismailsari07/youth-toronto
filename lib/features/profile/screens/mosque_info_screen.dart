import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/content_bundle.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.14. The map band uses the placeholder illustration until a real
/// map SDK is wired up; the pin marker and geometry are already in place.
class MosqueInfoScreen extends ConsumerWidget {
  const MosqueInfoScreen({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the row simply does not navigate */
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mosque = ref.watch(contentProvider.select((c) => c.mosque));
    final secondary = mosque.nameSecondary;
    final website = mosque.website;
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.theMosque, title: l.mosqueAndContact),
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
                  grouped: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _mapBand(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mosque.name,
                              style: AppText.cardTitle.c(AppColor.ink),
                            ),
                            if (secondary != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                secondary,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ).c(AppColor.ink3),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${mosque.street}\n'
                              '${mosque.city} ${mosque.postalCode}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                              ).c(AppColor.ink2),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: l.directions,
                                    height: 46,
                                    icon: AppIcons.navigate,
                                    onTap: () => _open(mosque.mapsUri),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GhostButton(
                                    label: l.call,
                                    height: 46,
                                    icon: AppIcons.phone,
                                    onTap: () => _open(mosque.phoneUri),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (mosque.hours.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.cardGapWide),
                  SectionHeader(title: l.openingHours),
                  const SizedBox(height: AppSpace.sectionHeaderGap),
                  GroupedRows(
                    rows: [
                      for (final (i, h) in mosque.hours.indexed)
                        AppListRow(
                          divided: i > 0,
                          icon: _hoursIcon(i),
                          title: h.label.resolve(l.localeName),
                          subtitle: h.value.resolve(l.localeName),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpace.cardGapWide),
                SectionHeader(title: l.getInTouch),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.phone,
                      title: mosque.phone,
                      subtitle: l.phone,
                      trailing: const RowChevron(),
                      onTap: () => _open(mosque.phoneUri),
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.mail,
                      title: mosque.email,
                      subtitle: l.email,
                      trailing: const RowChevron(),
                      onTap: () => _open('mailto:${mosque.email}'),
                    ),
                    if (website != null)
                      AppListRow(
                        divided: true,
                        icon: AppIcons.globe,
                        title: urlLabel(website),
                        subtitle: l.website,
                        trailing: const RowChevron(),
                        onTap: () => _open(website),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The rows keep the icons they had when the hours were built in: prayers,
  /// Jumu'ah, the office; any further row gets the clock.
  static String _hoursIcon(int index) => switch (index) {
        1 => AppIcons.mosque,
        2 => AppIcons.person,
        _ => AppIcons.clock,
      };

  Widget _mapBand() {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              color: AppColor.photoBandBg,
              alignment: Alignment.center,
              child: const AppIllustration(
                AppIllustration.mapPlaceholder,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: heroGradient,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8008281C),
                  offset: Offset(0, 6),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const AppIcon(
              AppIcons.mosque,
              size: 22,
              color: AppColor.onHero,
            ),
          ),
        ],
      ),
    );
  }
}
