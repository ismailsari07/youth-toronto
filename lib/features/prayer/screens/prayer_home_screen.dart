import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/mosque_time.dart';
import '../../../core/prayer_utils.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Spec §7.1 — the Prayer tab root. Phase B lays out the screen and its data;
/// the countdown arc, Jumu'ah/Eid card and the full state matrix land in
/// phase C.
class PrayerHomeScreen extends ConsumerWidget {
  const PrayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(prayerProvider);
    final payload = prayerAsync.valueOrNull;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        AppSpace.scrollBottomInset,
      ),
      children: [
        _header(context, payload),
        const SizedBox(height: 14),
        _hero(payload),
        const SizedBox(height: AppSpace.cardGapWide),
        const SectionHeader(
          title: 'Today at the mosque',
          trailingText: 'Athan · Iqamah',
        ),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        _timesCard(payload),
      ],
    );
  }

  Widget _header(BuildContext context, PrayerCachePayload? payload) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'PAPE MOSQUE',
                  style: AppText.eyebrow
                      .copyWith(fontSize: 11.5, letterSpacing: 0.9, height: 1.2)
                      .c(AppColor.green),
                ),
                Text(
                  gregorianTitle(payload?.gregorianDate) ?? todayTitle(),
                  style: AppText.dateTitle.c(AppColor.ink),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: AppIcons.bell,
            size: 44,
            iconSize: 21,
            bordered: false,
            shadow: AppShadow.floatingButton,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Placeholder hero until phase C: gradient card carrying the live next
  /// prayer, so the header is never decoration.
  Widget _hero(PrayerCachePayload? payload) {
    final next = payload == null ? null : getNextPrayer(payload.dailyPrayerTimes);
    return GradientTabHeader(
      title: 'Prayer',
      row: HeroRow(
        icon: next == null ? AppIcons.mosque : AppIcons.forPrayer(next.name),
        title: next == null ? 'Times unavailable' : 'Next · ${next.name}',
        subtitle: next == null
            ? 'Pull to refresh'
            : 'Athan ${next.time}'
                '${next.iqamah == null ? '' : ' · Iqamah ${next.iqamah}'}',
      ),
    );
  }

  Widget _timesCard(PrayerCachePayload? payload) {
    if (payload == null) {
      return GroupedRows(
        rows: [
          for (var i = 0; i < 6; i++)
            AppListRow(
              divided: i > 0,
              title: '',
              leading: const Shimmer(width: 38, height: 38, radius: 19),
              trailing: const Shimmer(width: 62, height: 16),
            ),
        ],
      );
    }

    final prayers = payload.dailyPrayerTimes;
    final next = getNextPrayer(prayers);
    final rows = <Widget>[];

    for (var i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final isNext = p.name == next.name;
      final isSunrise = p.name == 'Sunrise';
      final past = _isPast(p);

      rows.add(
        AppListRow(
          divided: i > 0,
          icon: AppIcons.forPrayer(p.name),
          tone: isSunrise ? RowTone.blue : RowTone.neutral,
          iconFill: isNext ? AppColor.greenTintStrong : null,
          iconGlyph: isNext ? AppColor.greenDark : null,
          background: isNext ? AppColor.greenRowBg : null,
          title: p.name,
          titleStyle: isNext
              ? AppText.prayerName
                  .copyWith(fontWeight: FontWeight.w700)
                  .c(AppColor.greenDeep)
              : AppText.prayerName.c(past ? AppColor.ink2 : AppColor.ink),
          subtitle: isSunrise ? 'Fajr window closes' : 'Athan ${p.time}',
          subtitleStyle: AppText.caption.c(AppColor.ink3),
          trailing: _trailing(p, isNext),
        ),
      );
    }

    rows.add(
      AppListRow(
        divided: true,
        icon: AppIcons.bell,
        background: AppColor.cardMuted,
        title: 'Prayer reminders',
        subtitle: '5 minutes before each iqamah',
        trailing: const AppSwitch(value: true),
      ),
    );

    return GroupedRows(rows: rows);
  }

  Widget _trailing(DailyPrayerItem p, bool isNext) {
    final iqamah = p.iqamah;
    if (iqamah == null) {
      return Text(p.time, style: AppText.iqamahValue.c(AppColor.ink2));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'IQAMAH',
          style: AppText.iqamahLabel
              .c(isNext ? const Color(0xFF5C7E6D) : AppColor.ink4),
        ),
        Text(
          iqamah,
          style: isNext
              ? AppText.iqamahValue
                  .copyWith(fontWeight: FontWeight.w700)
                  .c(AppColor.greenDeep)
              : AppText.iqamahValue.c(AppColor.ink),
        ),
      ],
    );
  }

  bool _isPast(DailyPrayerItem p) {
    final now = mosqueNow();
    final moment = prayerMoment(
      DateTime(now.year, now.month, now.day),
      p.name,
      p.time,
    );
    return moment != null && moment.isBefore(now);
  }
}
