import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../core/mosque_time.dart';
import '../../../core/prayer_utils.dart';
import '../../../core/prayer_widget_sync.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../../shared/providers/reminders_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/emergency_banner.dart';
import '../../../ui/components/moon_countdown_card.dart';
import '../../../ui/components/motion.dart';
import '../../../ui/components/refreshable.dart';
import '../../../ui/components/stagger.dart';
import '../widgets/community_section.dart';
import '../widgets/reminders_sheet.dart';

/// Spec §7.1 — the Prayer tab root. The whole daily list lives here; there is
/// deliberately no separate "all times" screen (§7.2).
class PrayerHomeScreen extends ConsumerStatefulWidget {
  const PrayerHomeScreen({super.key});

  @override
  ConsumerState<PrayerHomeScreen> createState() => _PrayerHomeScreenState();
}

class _PrayerHomeScreenState extends ConsumerState<PrayerHomeScreen> {
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
        // The panel's content too, so a new banner shows on a pull.
        ref.read(contentProvider.notifier).refresh(force: true);
        await ref.read(prayerProvider.future);
        // The home-screen widget picks up any corrected times too.
        PrayerWidgetSync.sync();
      },
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        AppSpace.scrollBottomInset,
      ),
      // The tab's entrance cascade, top to bottom: the emergency banner,
      // date and moon, the Community section, the times, the occasion card,
      // the mosque card.
      children: [
        StaggerItem(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EmergencyBanner(),
              _header(payload, loading),
              const SizedBox(height: 14),
              MoonCountdownCard(prayers: payload?.dailyPrayerTimes),
            ],
          ),
        ),
        // Next event and latest announcement; brings its own top gap and
        // hides entirely when there is nothing to show.
        const StaggerItem(index: 1, child: CommunitySection()),
        const SizedBox(height: AppSpace.cardGapWide),
        StaggerItem(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: l.todayAtTheMosque,
                trailingText: l.athanIqamah,
              ),
              const SizedBox(height: AppSpace.sectionHeaderGap),
              // Shimmer rows, the real rows and the failure card cross-fade,
              // and the card eases to its new height.
              FadeSwitch(
                animateSize: true,
                child: KeyedSubtree(
                  key: ValueKey(
                    payload != null ? 'times' : loading ? 'loading' : 'failed',
                  ),
                  child: _timesCard(payload, loading),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        StaggerItem(index: 3, child: _occasionCard(payload)),
        const SizedBox(height: AppSpace.cardGapWide),
        StaggerItem(index: 4, child: _mosqueCard()),
      ],
    );
  }

  /// Who we are, then today. Row 1: the app icon's mosque on its green, the
  /// organisation and the mosque, and the reminders bell. Row 2: the
  /// Gregorian date and the Hijri date in a pill, on one line.
  Widget _header(PrayerCachePayload? payload, bool loading) {
    final l = context.l10n;
    final hijri = hijriTitle(l, payload?.hijriDate);
    final remindersOn =
        ref.watch(reminderSettingsProvider).valueOrNull?.active ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _BrandTile(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // One line always: on a narrow phone the name scales down
                  // a touch rather than wrapping.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l.organisationName,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ).c(AppColor.ink),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l.homeMosqueLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3)
                        .c(AppColor.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: l.prayerReminders,
              button: true,
              child: CircleIconButton(
                icon: remindersOn ? AppIcons.bell : AppIcons.bellOff,
                size: 44,
                iconSize: 21,
                bordered: false,
                shadow: AppShadow.floatingButton,
                onTap: () => showRemindersSheet(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Always one line, so the moon card sits at the same height in every
        // language: the date keeps 20pt when it fits and only shrinks (to
        // about 17-18pt for French or long English dates) when it doesn't.
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  gregorianTitle(l, payload?.gregorianDate) ?? todayTitle(l),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ).c(AppColor.ink),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FadeSwitch(
              alignment: AlignmentDirectional.centerEnd,
              child: loading
                  ? const Shimmer(
                      key: ValueKey('loading'),
                      width: 120,
                      height: 26,
                      radius: AppRadius.pill,
                    )
                  : hijri != null
                      ? _HijriPill(hijri, key: const ValueKey('hijri'))
                      : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ],
        ),
      ],
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
          const RemindersRow(divided: true, background: AppColor.cardMuted),
        ],
      );
    }

    final prayers = payload.dailyPrayerTimes;
    // The prayer time we are in now (Sunrise from sunrise until Dhuhr).
    final current = currentTimetableRow(prayers);
    final rows = <Widget>[];

    for (var i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final isCurrent = p.name == current;
      final isSunrise = p.name == 'Sunrise';
      final past = _isPast(p);

      rows.add(
        AppListRow(
          divided: i > 0,
          icon: AppIcons.forPrayer(p.name),
          tone: isSunrise ? RowTone.blue : RowTone.neutral,
          iconFill: isCurrent ? AppColor.greenTintStrong : null,
          iconGlyph: isCurrent ? AppColor.greenDark : null,
          background: isCurrent ? AppColor.greenRowBg : null,
          title: prayerLabel(l, p.name),
          titleStyle: isCurrent
              ? AppText.prayerName
                  .copyWith(fontWeight: FontWeight.w700)
                  .c(AppColor.greenDeep)
              : AppText.prayerName.c(past ? AppColor.ink2 : AppColor.ink),
          subtitle: isSunrise
              ? l.fajrWindowCloses
              : l.athanAt(prayerClock12(p.name, p.time)),
          subtitleStyle: AppText.caption.c(AppColor.ink3),
          trailing: _trailing(p, isCurrent),
        ),
      );
    }

    rows.add(
      const RemindersRow(divided: true, background: AppColor.cardMuted),
    );
    return GroupedRows(rows: rows);
  }

  Widget _trailing(DailyPrayerItem p, bool isCurrent) {
    final iqamah = p.iqamah;
    if (iqamah == null) {
      return Text(
        prayerClock12(p.name, p.time),
        style: isCurrent
            ? AppText.iqamahValue
                .copyWith(fontWeight: FontWeight.w700)
                .c(AppColor.greenDeep)
            : AppText.iqamahValue.c(AppColor.ink2),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.iqamah,
          style: AppText.iqamahLabel
              .c(isCurrent ? const Color(0xFF5C7E6D) : AppColor.ink4),
        ),
        Text(
          prayerClock12(p.name, iqamah),
          style: isCurrent
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
      title: l.jumuah,
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
    final mosque = ref.watch(contentProvider.select((c) => c.mosque));
    return AppCard(
      radius: AppRadius.listCard,
      grouped: true,
      child: Column(
        children: [
          AppListRow(
            icon: AppIcons.pin,
            title: mosque.name,
            subtitle: '${mosque.street}, ${mosque.city}',
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
                    onTap: () => _open(mosque.mapsUri),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton(
                    label: l.callOffice,
                    icon: AppIcons.phone,
                    onTap: () => _open(mosque.phoneUri),
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

/// The app icon's mosque, cream on the icon's green, as a small tile.
class _BrandTile extends StatelessWidget {
  const _BrandTile();

  static const _iconGreen = Color(0xFF0F4D3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _iconGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/brand/mosque-mark.png',
        width: 24,
        height: 24,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _HijriPill extends StatelessWidget {
  const _HijriPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: AppColor.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColor.greenTintStrong),
      ),
      // Hugs the text: centred vertically without taking the full width.
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)
              .c(AppColor.greenDeep),
        ),
      ),
    );
  }
}
