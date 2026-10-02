import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/event_schedule.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../shared/providers/prayer_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Spec §7.3: the "when" line of an event card.
///
/// Clock time: "Every Wednesday · 7:30 PM", or "Sat 26 Sep · 6:30 PM" for a
/// one-off event. Prayer-linked: the prayer is the headline — prayer icon,
/// "After Maghrib" (or "Every Friday · after Maghrib") — followed by
/// "· about 7:20 PM" only when that day's prayer times are actually known.
/// They are only ever known for today, so any other day shows no clock time.
class EventWhenLine extends ConsumerWidget {
  const EventWhenLine({super.key, required this.upcoming});

  final UpcomingEvent upcoming;

  static const _main = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final event = upcoming.event;
    final prayer = event.startsAfterPrayer;
    if (prayer == null) {
      return Text(sessionLine(l, upcoming), style: _main.c(AppColor.ink2));
    }

    final start = upcoming.startsAt;
    final estimate = prayerLinkedEstimate(
      prayerKey: prayer,
      day: DateTime(start.year, start.month, start.day),
      cache: ref.watch(prayerProvider).valueOrNull,
    );
    final lead = event.repeats.isRecurring
        ? '${recurrenceWhen(l, event.repeats, start)} · '
            '${l.afterPrayerInline(prayer)}'
        : l.afterPrayer(prayer);
    final about = estimate == null ? null : l.aboutTime(eventTime(estimate));

    return Semantics(
      label: [
        if (event.repeats.isRecurring) recurrenceWhen(l, event.repeats, start),
        l.afterPrayerTitle(prayer),
        ?about,
      ].join(', '),
      excludeSemantics: true,
      // Two lines allowed: "Every Friday · after Maghrib · about 7:20 PM"
      // doesn't fit one line on a phone, and the time must never be cut off.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcon(
              AppIcons.forPrayer(prayerName(prayer)),
              size: 14,
              color: AppColor.green,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: lead,
                style: _main.c(AppColor.ink2),
                children: [
                  if (about != null)
                    TextSpan(
                      text: ' · $about',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ).c(AppColor.ink3),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
