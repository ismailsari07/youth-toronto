import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/event_schedule.dart';
import '../../../core/mosque_info.dart';
import '../../../l10n/app_strings.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/prayer_provider.dart';
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
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.upcoming});

  final UpcomingEvent upcoming;

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* the button simply does nothing rather than crashing */
    }
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: eventShareText(upcoming),
          subject: upcoming.event.title,
        ),
      );
    } catch (_) {
      /* share sheet unavailable */
    }
  }

  /// Spec §7.3, detail: for a recurring programme a repeat row, the time row
  /// and a "Next session" row; for a one-off, its date and time. A
  /// prayer-linked session's time row names the prayer, and says roughly
  /// when it begins only if that day's prayer times are known.
  List<Widget> _whenRows(WidgetRef ref) {
    final event = upcoming.event;
    final start = upcoming.startsAt;
    final prayer = event.startsAfterPrayer;
    final repeats = event.repeats;

    Widget? prayerRow({required bool divided}) {
      if (prayer == null) return null;
      final name = prayerDisplay(prayer);
      final estimate = prayerLinkedEstimate(
        prayerKey: prayer,
        day: DateTime(start.year, start.month, start.day),
        cache: ref.watch(prayerProvider).valueOrNull,
      );
      return AppListRow(
        divided: divided,
        icon: AppIcons.forPrayer(name),
        title: 'After $name prayer',
        subtitle: estimate == null
            ? AppStrings.beginsAfterJamaah
            : '${AppStrings.beginsAfterJamaah} — about '
                '${eventTime(estimate)} on ${dayMonthLong(start)}',
      );
    }

    if (repeats.isRecurring) {
      final (cadence, kind) = recurrenceRow(repeats, start);
      return [
        AppListRow(icon: AppIcons.repeat, title: cadence, subtitle: kind),
        prayerRow(divided: true) ??
            AppListRow(
              divided: true,
              icon: AppIcons.clock,
              title: eventTime(start),
              subtitle: AppStrings.startTime,
            ),
        AppListRow(
          divided: true,
          icon: AppIcons.calendar,
          title: AppStrings.nextSession,
          subtitle: longDate(start),
        ),
      ];
    }
    return [
      if (prayer == null)
        AppListRow(
          icon: AppIcons.clock,
          title: longDate(start),
          subtitle: eventTime(start),
        )
      else ...[
        AppListRow(
          icon: AppIcons.calendar,
          title: longDate(start),
          subtitle: AppStrings.date,
        ),
        prayerRow(divided: true)!,
      ],
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = upcoming.event;
    final recurring = event.repeats.isRecurring;
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
            eyebrow: eventEyebrow(event.repeats),
            title: event.title,
            subtitle: recurring
                ? '${recurrenceWhen(event.repeats, upcoming.startsAt)} · '
                    '${nextShort(upcoming.startsAt)}'
                : nextSessionLine(upcoming),
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
                    ..._whenRows(ref),
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
                    // No registration link: a drop-in session. (A weekly
                    // reminder action is a later task, so there is no
                    // sticky button in this case.)
                    if (registration == null)
                      const AppListRow(
                        divided: true,
                        icon: AppIcons.check,
                        title: AppStrings.dropIn,
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
          : StickyBottomBar(
              child: PrimaryButton(
                label: event.isFree ? 'Register · free' : 'Register',
                onTap: () => _open(registration.toString()),
              ),
            ),
    );
  }
}
