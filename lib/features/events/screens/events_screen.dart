import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models.dart';
import '../../../core/theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/events_news_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

enum _ViewMode { list, calendar }

enum _Filter { all, free, paid }

const _monthsFull = <String>[
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _months3Short = <String>[
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDetailDate(DateTime dt) =>
    '${_months3Short[dt.month]} ${dt.day}, ${dt.year} · ${eventTime(dt)}';

// ─── Stagger constants ────────────────────────────────────────────────────────

const _kItemCount = 4;
const _kDelayMs = 25;
const _kDurationMs = 150;
// Total = (itemCount - 1) * delay + duration = 3*25 + 150 = 225ms
const _kTotalMs = (_kItemCount - 1) * _kDelayMs + _kDurationMs;

// ─── Events Screen ────────────────────────────────────────────────────────────

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen>
    with SingleTickerProviderStateMixin {
  _ViewMode _view = _ViewMode.list;
  _Filter _filter = _Filter.all;
  late final AnimationController _controller;
  late final List<Animation<double>> _opacityAnims;
  late final List<Animation<double>> _slideAnims;

  List<YouthEvent> _applyFilter(List<YouthEvent> events) => switch (_filter) {
        _Filter.all => events,
        _Filter.free => events.where((e) => e.isFree).toList(),
        _Filter.paid => events.where((e) => !e.isFree).toList(),
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kTotalMs),
    );

    _opacityAnims = List.generate(_kItemCount, (i) {
      final begin = (i * _kDelayMs) / _kTotalMs;
      final end = (i * _kDelayMs + _kDurationMs) / _kTotalMs;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_kItemCount, (i) {
      final begin = (i * _kDelayMs) / _kTotalMs;
      final end = (i * _kDelayMs + _kDurationMs) / _kTotalMs;
      return Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animate(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, widget) => Opacity(
        opacity: _opacityAnims[index].value,
        child: Transform.translate(
          offset: Offset(0, _slideAnims[index].value),
          child: widget,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animate(0, _buildHeader()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _animate(1, _buildSegmentedControl()),
            ),
            _animate(2, _buildFilterPills()),
            Expanded(
              child: _animate(
                3,
                eventsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load events',
                      style: AppTextStyles.body,
                    ),
                  ),
                  data: (events) {
                    final filtered = _applyFilter(events);
                    return _view == _ViewMode.list
                        ? _buildListView(filtered)
                        : _CalendarView(events: filtered);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNITY', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'Events',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 40,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _view = _ViewMode.list),
              behavior: HitTestBehavior.opaque,
              child: _buildSegment('List', _view == _ViewMode.list),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _view = _ViewMode.calendar),
              behavior: HitTestBehavior.opaque,
              child: _buildSegment('Calendar', _view == _ViewMode.calendar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: isActive
          ? BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.gold, width: 1),
            )
          : null,
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          _buildPill('All', _Filter.all),
          const SizedBox(width: 8),
          _buildPill('Free', _Filter.free),
          const SizedBox(width: 8),
          _buildPill('Paid', _Filter.paid),
        ],
      ),
    );
  }

  Widget _buildPill(String label, _Filter filter) {
    final isActive = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.gold : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<YouthEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'No upcoming events',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: events.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildEventCard(events[i]),
    );
  }

  Widget _buildEventCard(YouthEvent event) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => EventDetailScreen(event: event),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: AppColors.gold),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventCardDate(event.dateTime),
                            style: AppTextStyles.label,
                          ),
                          const Spacer(),
                          _buildBadge(event),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.title,
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location ?? '',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.registrationUri != null
                                ? 'REGISTER →'
                                : 'DETAILS →',
                            style: AppTextStyles.goldAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(YouthEvent event) {
    final label = event.isFree ? 'FREE' : (event.price ?? 'PAID');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
    );
  }
}

// ─── Calendar View ────────────────────────────────────────────────────────────

class _CalendarView extends StatefulWidget {
  const _CalendarView({required this.events});
  final List<YouthEvent> events;

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  Set<int> get _eventDaysInMonth => widget.events
      .where((e) =>
          e.dateTime.year == _month.year && e.dateTime.month == _month.month)
      .map((e) => e.dateTime.day)
      .toSet();

  List<YouthEvent> get _selectedDayEvents => widget.events
      .where((e) =>
          e.dateTime.year == _selected.year &&
          e.dateTime.month == _selected.month &&
          e.dateTime.day == _selected.day)
      .toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthGrid(),
          const SizedBox(height: 12),
          _buildSelectedDaySection(),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startCol = firstDay.weekday % 7; // Sunday = 0
    final eventDays = _eventDaysInMonth;
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthsFull[_month.month]} ${_month.year}',
                    style: AppTextStyles.body.copyWith(fontSize: 15),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(d, style: AppTextStyles.label),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            ((startCol + daysInMonth) / 7).ceil(),
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final dayNum = week * 7 + col - startCol + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 42));
                  }
                  final date = DateTime(_month.year, _month.month, dayNum);
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isSelected = date.year == _selected.year &&
                      date.month == _selected.month &&
                      date.day == _selected.day;
                  final hasEvent = eventDays.contains(dayNum);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = date),
                      child: SizedBox(
                        height: 42,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.surfaceHighlight
                                    : Colors.transparent,
                                border: (isSelected || isToday)
                                    ? Border.all(
                                        color: AppColors.gold,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNum',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 13,
                                    color: (isSelected || isToday)
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (hasEvent)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDaySection() {
    final dateLabel =
        '${_monthsFull[_selected.month]} ${_selected.day}, ${_selected.year}';
    final dayEvents = _selectedDayEvents;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS DAY', style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (dayEvents.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'No events on this day.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (int i = 0; i < dayEvents.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.cardBorder,
                  ),
                ),
              _buildDayEventRow(dayEvents[i]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDayEventRow(YouthEvent event) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: AppTextStyles.body.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                event.location ?? '',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            eventTime(event.dateTime),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────────────────────

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});
  final YouthEvent event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageArea(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryPill(),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: GoogleFonts.cormorantGaramond(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                  if (event.registrationUri != null) ...[
                    const SizedBox(height: 24),
                    _buildRegisterButton(context),
                  ],
                  if (event.attendingCount > 0) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${event.attendingCount} attending',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    final imageUrl = event.imageUrl;
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          Positioned.fill(
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    // Missing/broken image (e.g. no storage bucket) → gradient.
                    errorBuilder: (_, _, _) => _buildImageFallback(),
                  )
                : _buildImageFallback(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOverlayButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildOverlayButton(
                    icon: Icons.ios_share_outlined,
                    onTap: () => _share(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final lines = <String>[
      event.title,
      _fmtDetailDate(event.dateTime),
      if (event.location != null && event.location!.trim().isNotEmpty)
        event.location!.trim(),
      if (event.registrationUri != null) 'Register: ${event.registrationUri}',
    ];
    try {
      await SharePlus.instance.share(
        ShareParams(text: lines.join('\n'), subject: event.title),
      );
    } catch (e) {
      debugPrint('Sharing event failed: $e');
    }
  }

  Future<void> _openRegistration(BuildContext context) async {
    final uri = event.registrationUri;
    if (uri == null) return;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Opening registration link failed: $e');
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the registration link")),
      );
    }
  }

  Widget _buildOverlayButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  Widget _buildCategoryPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: Text(
        event.category.toUpperCase(),
        style: AppTextStyles.label,
      ),
    );
  }

  Widget _buildInfoCard() {
    final priceStr = event.isFree ? 'Free' : (event.price ?? 'Paid');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'DATE & TIME',
            value: _fmtDetailDate(event.dateTime),
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.cardBorder,
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'LOCATION',
            value: event.location ?? '—',
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.cardBorder,
          ),
          _buildInfoRow(label: 'PRICE', value: priceStr),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    IconData? icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.textMuted, size: 15),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.label),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openRegistration(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Register',
            style: GoogleFonts.dmSans(
              color: AppColors.background,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
