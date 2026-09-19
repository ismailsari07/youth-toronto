import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../core/mosque_info.dart';
import '../../../shared/formatters.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/event_card.dart';

/// Spec §7.6. Pushed onto the root navigator, so the island is not shown and
/// the sticky bar owns the bottom of the screen.
///
/// Registration is external: the mosque publishes a link and we open it in the
/// browser. There is no in-app registration flow and no attendance count.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final YouthEvent event;

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the button simply does nothing rather than crashing */
    }
  }

  Future<void> _share() async {
    final lines = <String>[
      event.title,
      heroDateTime(event.dateTime),
      if (event.location != null && event.location!.trim().isNotEmpty)
        event.location!.trim(),
      if (event.registrationUri != null) 'Register: ${event.registrationUri}',
    ];
    try {
      await SharePlus.instance.share(
        ShareParams(text: lines.join('\n'), subject: event.title),
      );
    } catch (_) {
      /* share sheet unavailable */
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl;
    final registration = event.registrationUri;
    final description = event.description;
    final location = event.location;

    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: 'EVENT',
            title: event.title,
            subtitle: heroDateTime(event.dateTime),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                registration == null ? 40 : 120,
              ),
              children: [
                AppCard(
                  grouped: true,
                  child: imageUrl == null
                      ? const SizedBox(
                          height: 180,
                          child: PhotoBandFallback(),
                        )
                      : PhotoBand(url: imageUrl, height: 180),
                ),
                const SizedBox(height: AppSpace.cardGap),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.clock,
                      title: longDate(event.dateTime),
                      subtitle: eventTime(event.dateTime),
                    ),
                    if (location != null && location.trim().isNotEmpty)
                      AppListRow(
                        divided: true,
                        icon: AppIcons.pin,
                        title: location,
                        subtitle: MosqueInfo.addressLine,
                        trailing: GestureDetector(
                          onTap: () => _open(MosqueInfo.mapsUri),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            child: Text(
                              'Map',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ).c(AppColor.green),
                            ),
                          ),
                        ),
                      ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.users,
                      title: event.isFree ? 'Free to attend' : (event.price ?? 'Ticketed'),
                      subtitle: 'Everyone is welcome',
                    ),
                  ],
                ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpace.cardGapWide),
                  const SectionHeader(title: 'About this event'),
                  const SizedBox(height: AppSpace.sectionHeaderGap),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.cardPadding),
                    child: Text(
                      description,
                      style: AppText.body.c(AppColor.ink2),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.cardGapWide),
                GroupedRows(
                  rows: [
                    AppListRow(
                      icon: AppIcons.phone,
                      title: 'Questions?',
                      subtitle: 'Call the mosque office',
                      trailing: const RowChevron(),
                      onTap: () => _open(MosqueInfo.phoneUri),
                    ),
                    AppListRow(
                      divided: true,
                      icon: AppIcons.share,
                      title: 'Share this event',
                      trailing: const RowChevron(),
                      onTap: _share,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: registration == null
          ? null
          : _StickyBar(
              child: PrimaryButton(
                label: event.isFree ? 'Register · free' : 'Register',
                onTap: () => _open(registration.toString()),
              ),
            ),
    );
  }
}

/// Spec §7.6: white at 82% with a 22-sigma blur and a hairline top border.
class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xD1FFFFFF),
            border: Border(top: BorderSide(color: Color(0x120A3222))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
