import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth_service.dart';
import '../../../core/theme.dart';
import '../../../shared/providers/auth_provider.dart';
import 'auth_screen.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _RegisteredEvent {
  const _RegisteredEvent({
    required this.date,
    required this.title,
    required this.attended,
  });
  final String date;
  final String title;
  final bool attended;
}

const _registeredEvents = <_RegisteredEvent>[
  _RegisteredEvent(date: 'Apr 15', title: 'Youth Iftar', attended: true),
  _RegisteredEvent(date: 'May 8', title: 'Tafsir Circle', attended: false),
  _RegisteredEvent(date: 'May 23', title: 'Weekend Retreat', attended: false),
];

// ─── Stagger constants ────────────────────────────────────────────────────────

const _kItemCount = 5;
const _kDelayMs = 25;
const _kDurationMs = 150;
const _kTotalMs = (_kItemCount - 1) * _kDelayMs + _kDurationMs;

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsOn = true;
  bool _notificationsInitialized = false;
  String _language = 'EN';
  late final AnimationController _controller;
  late final List<Animation<double>> _opacityAnims;
  late final List<Animation<double>> _slideAnims;

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

  void _showAuthSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AuthScreen(
        onSuccess: () => Navigator.pop(context),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String _memberYear(String? createdAt) {
    if (createdAt == null) return DateTime.now().year.toString();
    return (DateTime.tryParse(createdAt)?.year ?? DateTime.now().year)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    // Restart animation and reset local state whenever the signed-in user changes.
    ref.listen(currentUserProvider, (prev, next) {
      if (prev?.id != next?.id) {
        _controller.reset();
        _controller.forward();
        setState(() {
          _notificationsOn = true;
          _notificationsInitialized = false;
        });
      }
    });

    // Initialise notifications toggle from Supabase once per login session.
    ref.listen(userProfileProvider, (_, next) {
      next.whenData((profile) {
        if (!_notificationsInitialized && profile != null && mounted) {
          setState(() {
            _notificationsOn =
                profile['notifications_enabled'] as bool? ?? true;
            _notificationsInitialized = true;
          });
        }
      });
    });

    final authAsync = ref.watch(authStateProvider);
    final profileData = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: authAsync.when(
          loading: () => _buildLoggedOut(),
          error: (_, _) => _buildLoggedOut(),
          data: (authState) {
            final user = authState.session?.user;
            if (user == null) return _buildLoggedOut();
            return _buildLoggedIn(user, profileData);
          },
        ),
      ),
    );
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACCOUNT', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  'Profile',
                  style: GoogleFonts.cormorantGaramond(
                    color: AppColors.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _buildLangSwitcher(),
        ],
      ),
    );
  }

  Widget _buildLangSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['TR', 'EN'].map((lang) {
          final isActive = _language == lang;
          return GestureDetector(
            onTap: () => setState(() => _language = lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                lang,
                style: GoogleFonts.dmSans(
                  color: isActive ? AppColors.background : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrnamentFooter(String text) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 0.5, color: AppColors.divider),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textMuted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 0.5, color: AppColors.divider),
        ),
      ],
    );
  }

  // ── Logged-out ────────────────────────────────────────────────────────────

  Widget _buildLoggedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _animate(0, _buildHeader()),
        const SizedBox(height: 28),
        _animate(
          1,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildWelcomeCard(),
          ),
        ),
        const SizedBox(height: 36),
        _animate(2, _buildOrnamentFooter('MYT · est. 2024')),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _DashedCirclePainter(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to register for events and personalize your prayer reminders.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _showAuthSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Continue',
                  style: GoogleFonts.dmSans(
                    color: AppColors.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logged-in ─────────────────────────────────────────────────────────────

  String? _formatDob(String? rawDob) {
    if (rawDob == null || rawDob.isEmpty) return null;
    final date = DateTime.tryParse(rawDob);
    if (date == null) return null;
    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget _buildLoggedIn(User user, Map<String, dynamic>? profileData) {
    final fullName = profileData?['full_name'] as String? ??
        user.email?.split('@').first ??
        'Member';
    final email = user.email ?? '';
    final memberYear = _memberYear(profileData?['created_at'] as String?);
    final phone = profileData?['phone'] as String?;
    final dob = _formatDob(profileData?['date_of_birth'] as String?);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _animate(0, _buildHeader()),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animate(1, _buildUserCard(fullName, email, memberYear, phone: phone, dob: dob)),
                const SizedBox(height: 28),
                _animate(2, _buildSectionLabel('MY EVENTS', 'Registered')),
                const SizedBox(height: 12),
                _animate(2, _buildEventsCard()),
                const SizedBox(height: 28),
                _animate(3, Text('SETTINGS', style: AppTextStyles.label)),
                const SizedBox(height: 12),
                _animate(3, _buildSettingsCard()),
                const SizedBox(height: 20),
                _animate(4, _buildLogOutButton()),
                const SizedBox(height: 36),
                _animate(4, _buildOrnamentFooter('MYT · TORONTO · 2026')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    String fullName,
    String email,
    String memberYear, {
    String? phone,
    String? dob,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textMuted, width: 1),
            ),
            child: Center(
              child: Text(
                _initials(fullName),
                style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                if (dob != null && dob.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        color: AppColors.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dob,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Text(
                    'MEMBER · $memberYear',
                    style: AppTextStyles.label.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _registeredEvents.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.cardBorder,
              ),
            _buildEventRow(_registeredEvents[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildEventRow(_RegisteredEvent event) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.date,
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                event.title,
                style: AppTextStyles.body.copyWith(fontSize: 15),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Text(
              event.attended ? 'ATTENDED' : 'UPCOMING',
              style: AppTextStyles.label.copyWith(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text('Notifications', style: AppTextStyles.body),
                const Spacer(),
                Switch(
                  value: _notificationsOn,
                  onChanged: (v) {
                    setState(() => _notificationsOn = v);
                    final userId = ref.read(currentUserProvider)?.id;
                    if (userId != null) {
                      Supabase.instance.client
                          .from('user_profiles')
                          .update({'notifications_enabled': v})
                          .eq('user_id', userId);
                    }
                  },
                  activeThumbColor: AppColors.gold,
                  activeTrackColor: const Color(0x40C8A96B),
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor: AppColors.surfaceHighlight,
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.cardBorder,
          ),
          _buildNavRow(
            icon: Icons.language_outlined,
            label: 'Language',
            value: 'English',
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.cardBorder,
          ),
          _buildNavRow(
            icon: Icons.info_outlined,
            label: 'About',
            value: 'v1.0',
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutButton() {
    return GestureDetector(
      onTap: () => AuthService.signOut(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashed Circle Painter ────────────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 0.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const dashCount = 24;
    const segmentAngle = math.pi * 2 / dashCount;
    const dashAngle = segmentAngle * 0.5;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      canvas.drawArc(rect, startAngle, dashAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
