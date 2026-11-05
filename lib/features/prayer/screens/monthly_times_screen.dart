import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/mosque_time.dart';
import '../../../core/prayer_month.dart';
import '../../../core/prayer_refresh.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/prayer_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_scaffolding.dart';

const _columns = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

/// Every day in prayer_cache from today, one row a day: the date stays in view
/// and the prayers scroll sideways. A day without a usable row says so and
/// shows dashes; a time that can't be read is a dash too, never its raw text.
class MonthlyTimesScreen extends ConsumerStatefulWidget {
  const MonthlyTimesScreen({super.key});

  @override
  ConsumerState<MonthlyTimesScreen> createState() => _MonthlyTimesScreenState();
}

class _MonthlyTimesScreenState extends ConsumerState<MonthlyTimesScreen> {
  final _body = ScrollController();
  final _header = ScrollController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _body.addListener(() {
      if (_header.hasClients) _header.jumpTo(_body.offset);
    });
    // Back after a while: a new day, or rows past their age.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted) ref.invalidate(prayerMonthProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _body.dispose();
    _header.dispose();
    super.dispose();
  }

  /// Like a pull on Prayer: a corrected time reaches the reminders too.
  Future<void> _refresh() async {
    await prayerRefresh();
    ref.invalidate(prayerMonthProvider);
    try {
      await ref.read(prayerMonthProvider.future);
    } catch (_) {
      /* the failure card shows it */
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(prayerMonthProvider);
    final rows = async.valueOrNull;
    final days = rows == null ? const <MonthDay>[] : monthDays(rows, mosqueNow());
    final Widget content;
    if (days.isNotEmpty) {
      content = _Table(days: days, body: _body, header: _header, onRefresh: _refresh);
    } else if (rows == null && !async.hasError) {
      content = const Center(child: CircularProgressIndicator.adaptive());
    } else {
      content = _Unavailable(onRetry: () => ref.invalidate(prayerMonthProvider));
    }

    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.theMosque, title: l.monthlyTimes),
          const SizedBox(height: 14),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.pageGutter),
      child: Align(
        alignment: Alignment.topCenter,
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.timesUnavailable, style: AppText.cardTitle.c(context.colors.ink)),
              const SizedBox(height: 6),
              Text(
                l.timesUnavailableShortBody,
                style: const TextStyle(fontSize: 13.5, height: 1.45).c(context.colors.ink2),
              ),
              const SizedBox(height: 16),
              GhostButton(label: l.tryAgain, onTap: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.days,
    required this.body,
    required this.header,
    required this.onRefresh,
  });

  final List<MonthDay> days;
  final ScrollController body;
  final ScrollController header;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    // Heights are fixed so the date column and the prayers stay lined up, so
    // they grow with the text size, up to a limit.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Builder(builder: _table),
    );
  }

  Widget _table(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final sizes = _Sizes(
      date: 122 * scale,
      // 12-hour "12:30 PM" and French "13 h 45" are wider than "13:45".
      cell: (l.localeName.startsWith('tr') ? 62 : 76) * scale,
      row: 66 * scale,
      friday: 86 * scale,
      head: 40 * scale,
    );
    final lastData = days.lastWhere((d) => d.payload != null, orElse: () => days.last);
    final hasData = days.any((d) => d.payload != null);
    final separator = BorderDirectional(end: BorderSide(color: colors.hairline));
    final underline = Border(bottom: BorderSide(color: colors.hairline));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The header follows the table's sideways scroll and stays on top.
        Container(
          height: sizes.head,
          decoration: BoxDecoration(color: colors.card, border: underline),
          child: Row(
            children: [
              Container(
                width: sizes.date,
                height: sizes.head,
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsetsDirectional.only(start: AppSpace.pageGutter, end: 6),
                decoration: BoxDecoration(border: separator),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l.athanIqamah,
                    maxLines: 1,
                    style: AppText.iqamahLabel.c(colors.ink3),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: header,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      for (final name in _columns)
                        SizedBox(
                          width: sizes.cell,
                          child: Text(
                            prayerLabel(l, name),
                            textAlign: TextAlign.center,
                            maxLines: 2, // French "Lever du soleil"
                            style: const TextStyle(fontSize: 12, height: 1.15, fontWeight: FontWeight.w700)
                                .c(colors.ink2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator.adaptive(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: sizes.date,
                        child: Column(
                          children: [
                            for (final (i, d) in days.indexed)
                              _DateCell(day: d, sizes: sizes, today: i == 0),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: body,
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, d) in days.indexed)
                                _TimesRow(day: d, sizes: sizes, today: i == 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasData)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.pageGutter,
                        14,
                        AppSpace.pageGutter,
                        0,
                      ),
                      child: Text(
                        l.monthlyLastDay(longDate(l, lastData.day)),
                        style: AppText.caption.c(colors.ink3),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sizes {
  const _Sizes({
    required this.date,
    required this.cell,
    required this.row,
    required this.friday,
    required this.head,
  });

  final double date, cell, row, friday, head;

  double height(MonthDay d) => _jumuahTime(d) != null ? friday : row;
}

/// The Friday's Jumu'ah time, when the row has one that can be read.
String? _jumuahTime(MonthDay d) {
  if (d.day.weekday != DateTime.friday) return null;
  final time = d.payload?.jumaaPrayerTime;
  return time == null || prayerClock('Dhuhr', time) == null ? null : time;
}

/// Today is green; gold is kept for Jumu'ah, as everywhere else.
Color? _rowColor(BuildContext context, MonthDay d, bool today) => today
    ? context.colors.greenRowBg
    : _jumuahTime(d) != null
        ? context.colors.goldBg
        : null;

class _DateCell extends StatelessWidget {
  const _DateCell({required this.day, required this.sizes, required this.today});

  final MonthDay day;
  final _Sizes sizes;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final payload = day.payload;
    final hijri = hijriTitle(l, payload?.hijriDate);
    final jumuah = _jumuahTime(day);
    return Container(
      width: sizes.date,
      height: sizes.height(day),
      padding: const EdgeInsetsDirectional.only(start: AppSpace.pageGutter, end: 6),
      decoration: BoxDecoration(
        color: _rowColor(context, day, today) ?? colors.card,
        border: BorderDirectional(
          end: BorderSide(color: colors.hairline),
          bottom: BorderSide(color: colors.hairline),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compactDate(l, day.day),
            maxLines: 1,
            style: TextStyle(fontSize: 13, fontWeight: today ? FontWeight.w800 : FontWeight.w700)
                .c(today ? colors.selectedDeep : colors.ink),
          ),
          if (payload == null)
            Text(
              l.monthlyMissingDay,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, height: 1.25, fontWeight: FontWeight.w600)
                  .c(colors.ink3),
            )
          else if (hijri != null)
            Text(
              hijri,
              maxLines: 2,
              style: const TextStyle(fontSize: 10.5, height: 1.25)
                  .c(today ? colors.selectedCaption : colors.ink3),
            ),
          if (jumuah != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l.monthlyJumuahAt(prayerClockText(l, 'Dhuhr', jumuah)),
                maxLines: 1,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)
                    .c(today ? colors.selectedDeep : colors.goldText),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimesRow extends StatelessWidget {
  const _TimesRow({required this.day, required this.sizes, required this.today});

  final MonthDay day;
  final _Sizes sizes;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final items = {
      for (final p in day.payload?.dailyPrayerTimes ?? const <DailyPrayerItem>[]) p.name: p,
    };
    return Container(
      height: sizes.height(day),
      decoration: BoxDecoration(
        color: _rowColor(context, day, today) ?? context.colors.card,
        border: Border(bottom: BorderSide(color: context.colors.hairline)),
      ),
      child: Row(
        children: [
          for (final name in _columns)
            _Cell(name: name, item: items[name], width: sizes.cell, today: today),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.name, required this.item, required this.width, required this.today});

  final String name;
  final DailyPrayerItem? item;
  final double width;
  final bool today;

  static const _dash = '—';
  static const _digits = [FontFeature.tabularFigures()];

  String? _clock(AppLocalizations l, String? stored) =>
      stored == null || prayerClock(name, stored) == null
          ? null
          : prayerClockText(l, name, stored);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final athan = _clock(l, item?.time);
    final iqamah = _clock(l, item?.iqamah);
    final sunrise = name == 'Sunrise';
    final parts = [
      prayerLabel(l, name),
      if (athan != null) sunrise ? athan : l.athanAt(athan),
      if (iqamah != null) l.iqamahAt(iqamah),
    ];
    return Semantics(
      label: parts.join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              athan ?? _dash,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: today ? FontWeight.w800 : FontWeight.w600,
                fontFeatures: _digits,
              ).c(today ? colors.selectedDeep : colors.ink),
            ),
            // Sunrise has no iqamah by nature, so no dash for it.
            if (!sunrise)
              Text(
                iqamah ?? _dash,
                maxLines: 1,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFeatures: _digits)
                    .c(today ? colors.selectedCaption : colors.ink3),
              ),
          ],
        ),
      ),
    );
  }
}
