import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.5. Text only: announcements carry no imagery, which is what makes
/// them read as a different species from events (spec §0).
class AnnouncementDetailScreen extends ConsumerWidget {
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

  Future<void> _call(String phoneUri) async {
    try {
      await launchUrl(
        Uri.parse(phoneUri),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* nothing to do */
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mosque = ref.watch(contentProvider.select((c) => c.mosque));
    final l = context.l10n;
    final ago = l.postedAgo(timeAgo(l, item.date));
    final posted = '$ago · ${l.mosqueOffice}';

    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.announcementEyebrow,
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
                                l.mosqueOffice,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ).c(AppColor.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ago,
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
                      title: l.shareThisAnnouncement,
                      trailing: const RowChevron(),
                      onTap: _share,
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.phone,
                      title: l.callTheOffice,
                      subtitle: mosque.phone,
                      trailing: const RowChevron(),
                      onTap: () => _call(mosque.phoneUri),
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
