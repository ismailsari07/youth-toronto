import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/mosque_info.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.14. The map band uses the placeholder illustration until a real
/// map SDK is wired up; the pin marker and geometry are already in place.
class MosqueInfoScreen extends StatelessWidget {
  const MosqueInfoScreen({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the row simply does not navigate */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PlainNavBar(eyebrow: 'THE MOSQUE', title: 'Mosque & contact'),
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
                              MosqueInfo.name,
                              style: AppText.cardTitle.c(AppColor.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              MosqueInfo.nameSecondary,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ).c(AppColor.ink3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${MosqueInfo.street}\n'
                              '${MosqueInfo.city} ${MosqueInfo.postalCode}',
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
                                    label: 'Directions',
                                    height: 46,
                                    icon: AppIcons.navigate,
                                    onTap: () => _open(MosqueInfo.mapsUri),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GhostButton(
                                    label: 'Call',
                                    height: 46,
                                    icon: AppIcons.phone,
                                    onTap: () => _open(MosqueInfo.phoneUri),
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
                const SizedBox(height: AppSpace.cardGapWide),
                const SectionHeader(title: 'Opening hours'),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                const GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.clock,
                      title: 'Daily prayers',
                      subtitle: 'Open for every prayer, Fajr through Isha',
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.mosque,
                      title: "Jumu'ah",
                      subtitle: 'Fridays',
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.person,
                      title: 'Office',
                      subtitle: 'Call for current hours',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                const SectionHeader(title: 'Get in touch'),
                const SizedBox(height: AppSpace.sectionHeaderGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.phone,
                      title: MosqueInfo.phone,
                      subtitle: 'Phone',
                      trailing: const RowChevron(),
                      onTap: () => _open(MosqueInfo.phoneUri),
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.mail,
                      title: MosqueInfo.email,
                      subtitle: 'Email',
                      trailing: const RowChevron(),
                      onTap: () => _open('mailto:${MosqueInfo.email}'),
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.globe,
                      title: MosqueInfo.website,
                      subtitle: 'Website',
                      trailing: const RowChevron(),
                      onTap: () => _open(MosqueInfo.websiteUri),
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
