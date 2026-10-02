import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../core/mosque_info.dart';
import '../../../core/mosque_time.dart';
import '../../../core/notification_service.dart';
import '../../../core/prayer_utils.dart';
import '../../../core/reminder_sync.dart';
import '../../../l10n/l10n.dart';
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
import '../../../ui/components/moon_countdown_card.dart';
import '../../../ui/components/refreshable.dart';

/// Spec §7.1 — the Prayer tab root. The whole daily list lives here; there is
/// deliberately no separate "all times" screen (§7.2).
class PrayerHomeScreen extends ConsumerStatefulWidget {
  const PrayerHomeScreen({super.key});

  @override
  ConsumerState<PrayerHomeScreen> createState() => _PrayerHomeScreenState();
}

class _PrayerHomeScreenState extends ConsumerState<PrayerHomeScreen> {
  bool? _remindersOn;

  @override
  void initState() {
    super.initState();
    ReminderSync.isEnabled().then((on) {
      if (mounted) setState(() => _remindersOn = on);
    });
  }

  Future<void> _setReminders(bool value) async {
    setState(() => _remindersOn = value);
    await ReminderSync.setEnabled(value);
    if (value) {
      await NotificationService.requestPermissions();
    } else {
      await NotificationService.cancelAll();
    }
    ReminderSync.sync();
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      /* nothing to do: the row simply does not navigate */
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prayerProvider);
    final payload = async.valueOrNull;
    final loading = async.isLoading && payload == null;
    final l = context.l10n;

    return RefreshableList(
      onRefresh: () async {
        ref.invalidate(prayerProvider);
        await ref.read(prayerProvider.future);
      },
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        AppSpace.scrollBottomInset,
      ),
      children: [
        _header(payload, loading),
        const SizedBox(height: 14),
        MoonCountdownCard(prayers: payload?.dailyPrayerTimes),
        const SizedBox(height: AppSpace.cardGapWide),
        SectionHeader(
          title: l.todayAtTheMosque,
          trailingText: l.athanIqamah,
        ),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        _timesCard(payload, loading),
        const SizedBox(height: AppSpace.cardGapWide),
        _occasionCard(payload),
        const SizedBox(height: AppSpace.cardGapWide),
        _mosqueCard(),
      ],
    );
  }

  /// Eyebrow, Gregorian date and the Hijri date beneath it (spec §0 note).
  Widget _header(PrayerCachePayload? payload, bool loading) {
    final l = context.l10n;
    final hijri = hijriTitle(l, payload?.hijriDate);
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
                  l.mosqueEyebrow,
                  style: AppText.eyebrow
                      .copyWith(fontSize: 11.5, letterSpacing: 0.9, height: 1.2)
                      .c(AppColor.green),
                ),
                Text(
                  gregorianTitle(l, payload?.gregorianDate) ?? todayTitle(l),
                  style: AppText.dateTitle.c(AppColor.ink),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Shimmer(width: 120, height: 12),
                  )
                else if (hijri != null)
                  Text(hijri, style: AppText.caption.c(AppColor.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
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

  /// Spec §7.1 step 4, and §7.1b for the shimmer variant.
  Widget _timesCard(PrayerCachePayload? payload, bool loading) {
    final l = context.l10n;
    if (payload == null && !loading) {
      // Spec §7.15: an inline failure with a way out, never a blank screen.
      return AppCard(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.timesUnavailableTitle,
              style: AppText.cardTitle.c(AppColor.ink),
            ),
            const SizedBox(height: 6),
            Text(
              l.timesUnavailableBody,
              style: const TextStyle(fontSize: 13.5, height: 1.45)
                  .c(AppColor.ink2),
            ),
            const SizedBox(height: 16),
            GhostButton(
              label: l.tryAgain,
              onTap: () => ref.invalidate(prayerProvider),
            ),
          ],
        ),
      );
    }
    if (payload == null) {
      return GroupedRows(
        rows: [
          for (var i = 0; i < 6; i++)
            AppListRow(
              divided: i > 0,
              title: '',
              leading: const Shimmer(width: 38, height: 38, radius: 19),
              trailing: const Shimmer(width: 64, height: 18),
            ),
          _remindersRow(),
        ],
      );
    }

    final prayers = payload.dailyPrayerTimes;
    final window = currentPrayerWindow(prayers);
    final next = window?.next.name ?? getNextPrayer(prayers).name;
    final rows = <Widget>[];

    for (var i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final isNext = p.name == next;
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
          title: prayerLabel(l, p.name),
          titleStyle: isNext
              ? AppText.prayerName
                  .copyWith(fontWeight: FontWeight.w700)
                  .c(AppColor.greenDeep)
              : AppText.prayerName.c(past ? AppColor.ink2 : AppColor.ink),
          subtitle: isSunrise
              ? l.fajrWindowCloses
              : l.athanAt(prayerClock12(p.name, p.time)),
          subtitleStyle: AppText.caption.c(AppColor.ink3),
          trailing: _trailing(p, isNext),
        ),
      );
    }

    rows.add(_remindersRow());
    return GroupedRows(rows: rows);
  }

  Widget _remindersRow() => AppListRow(
        divided: true,
        icon: AppIcons.bell,
        background: AppColor.cardMuted,
        title: context.l10n.prayerReminders,
        subtitle: context.l10n.prayerRemindersDetail,
        trailing: AppSwitch(
          value: _remindersOn ?? true,
          onChanged: _remindersOn == null ? null : _setReminders,
        ),
      );

  Widget _trailing(DailyPrayerItem p, bool isNext) {
    final iqamah = p.iqamah;
    if (iqamah == null) {
      return Text(
        prayerClock12(p.name, p.time),
        style: AppText.iqamahValue.c(AppColor.ink2),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.iqamah,
          style: AppText.iqamahLabel
              .c(isNext ? const Color(0xFF5C7E6D) : AppColor.ink4),
        ),
        Text(
          prayerClock12(p.name, iqamah),
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
    final moment =
        prayerMoment(DateTime(now.year, now.month, now.day), p.name, p.time);
    return moment != null && moment.isBefore(now);
  }

  /// Gold is reserved for Jumu'ah and Eid (spec §0). Eid replaces Jumu'ah when
  /// its date is near.
  Widget _occasionCard(PrayerCachePayload? payload) {
    final l = context.l10n;
    final eid = _upcomingEid(payload?.eidPrayerTimes);
    if (eid != null) {
      final name = eid.fitr ? l.eidFitr : l.eidAdha;
      return _goldCard(
        title: '$name · ${longDate(l, eid.date)}',
        subtitle: l.eidTimes(eid.first, eid.second),
      );
    }
    final jumaa = payload?.jumaaPrayerTime;
    return _goldCard(
      title: l.jumuahThisFriday,
      // Only what the data actually carries: there is no khutbah time in
      // prayer_cache, so none is shown.
      subtitle: jumaa == null
          ? l.jumuahEveryFriday
          : l.salahAt(prayerClock12('Dhuhr', jumaa)),
    );
  }

  Widget _goldCard({required String title, required String subtitle}) {
    return AppCard(
      radius: AppRadius.listCard,
      color: AppColor.goldBg,
      border: Border.all(color: AppColor.goldBorder),
      shadow: const [
        BoxShadow(color: Color(0x0D503C0A), offset: Offset(0, 1), blurRadius: 2),
        BoxShadow(
          color: Color(0x38503C0A),
          offset: Offset(0, 10),
          blurRadius: 26,
          spreadRadius: -12,
        ),
      ],
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        children: [
          const IconBubble(
            icon: AppIcons.mosque,
            tone: RowTone.gold,
            size: 42,
            iconSize: 22,
          ),
          const SizedBox(width: AppSpace.rowGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.rowTitle
                      .copyWith(fontWeight: FontWeight.w700)
                      .c(AppColor.goldText),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)
                      .c(AppColor.goldTextSoft),
                ),
              ],
            ),
          ),
          const RowChevron(color: Color(0xFF8A6516), size: 18),
        ],
      ),
    );
  }

  /// The Eid that falls within the next week, if any.
  ///
  /// NOTE: `eidPrayerTimes.date` arrives as a Turkish string from the upstream
  /// Diyanet feed ("20 Mart 2026 Cuma"), so this parse is deliberately
  /// defensive — an unparseable date simply leaves the Jumu'ah card in place.
  /// The parsed date is shown, formatted for the app's language.
  ({bool fitr, DateTime date, String first, String second})? _upcomingEid(
    EidPrayerTimes? eid,
  ) {
    if (eid == null) return null;
    for (final entry in [(true, eid.eidFitr), (false, eid.eidAdha)]) {
      final date = _parseTurkishDate(entry.$2.date);
      if (date == null) continue;
      final now = mosqueNow();
      final days = date.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (days >= 0 && days <= 7) {
        return (
          fitr: entry.$1,
          date: date,
          first: entry.$2.firstIqamah,
          second: entry.$2.secondIqamah,
        );
      }
    }
    return null;
  }

  static const _turkishMonths = {
    'ocak': 1, 'şubat': 2, 'subat': 2, 'mart': 3, 'nisan': 4, 'mayıs': 5,
    'mayis': 5, 'haziran': 6, 'temmuz': 7, 'ağustos': 8, 'agustos': 8,
    'eylül': 9, 'eylul': 9, 'ekim': 10, 'kasım': 11, 'kasim': 11, 'aralık': 12,
    'aralik': 12,
  };

  DateTime? _parseTurkishDate(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _turkishMonths[parts[1].toLowerCase()];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Spec §7.1 step 8.
  Widget _mosqueCard() {
    final l = context.l10n;
    return AppCard(
      radius: AppRadius.listCard,
      grouped: true,
      child: Column(
        children: [
          AppListRow(
            icon: AppIcons.pin,
            title: MosqueInfo.name,
            subtitle: '${MosqueInfo.street}, ${l.city}',
            trailing: const RowChevron(),
            onTap: () => context.push('/profile/mosque'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: l.directions,
                    icon: AppIcons.navigate,
                    onTap: () => _open(MosqueInfo.mapsUri),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton(
                    label: l.callOffice,
                    icon: AppIcons.phone,
                    onTap: () => _open(MosqueInfo.phoneUri),
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
