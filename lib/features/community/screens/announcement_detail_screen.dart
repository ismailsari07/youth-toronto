import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../core/mosque_info.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.5. Text only: announcements carry no imagery, which is what makes
/// them read as a different species from events (spec §0).
class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({super.key, required this.item});

  final Announcement item;

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: '${item.title}\n\n${item.description}',
          subject: item.title,
        ),
      );
    } catch (_) {
      /* share sheet unavailable */
    }
  }

  Future<void> _call() async {
    try {
      await launchUrl(
        Uri.parse(MosqueInfo.phoneUri),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* nothing to do */
    }
  }

  @override
  Widget build(BuildContext context) {
    final posted = 'Posted ${timeAgo(item.date)} · Mosque office';

    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: 'ANNOUNCEMENT',
            title: item.title,
            subtitle: posted,
          ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final paragraph in _paragraphs(item.description))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            paragraph,
                            style: AppText.bodyLarge.c(AppColor.ink2),
                          ),
                        ),
                      const SizedBox(height: 6),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColor.hairline,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const IconBubble(
                            icon: AppIcons.mosque,
                            size: 34,
                            iconSize: 17,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mosque office',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ).c(AppColor.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Posted ${timeAgo(item.date)}',
                                style:
                                    const TextStyle(fontSize: 12).c(AppColor.ink3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                GroupedRows(
                  radius: AppRadius.listCard,
                  rows: [
                    AppListRow(
                      icon: AppIcons.share,
                      title: 'Share this announcement',
                      trailing: const RowChevron(),
                      onTap: _share,
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.phone,
                      title: 'Call the mosque office',
                      subtitle: MosqueInfo.phone,
                      trailing: const RowChevron(),
                      onTap: _call,
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

  List<String> _paragraphs(String body) => body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}
