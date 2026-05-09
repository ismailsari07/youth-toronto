import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';

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
// Total = (itemCount - 1) * delay + duration = 4*60 + 300 = 540ms
const _kTotalMs = (_kItemCount - 1) * _kDelayMs + _kDurationMs;

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  bool _notificationsOn = true;
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
      builder: (_) => _AuthSheet(
        onAuth: () {
          Navigator.pop(context);
          setState(() => _isLoggedIn = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoggedIn ? _buildLoggedIn() : _buildLoggedOut(),
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
          child: Divider(thickness: 0.5, color: Color(0x335A5F52)),
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
          child: Divider(thickness: 0.5, color: Color(0x335A5F52)),
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

  Widget _buildLoggedIn() {
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
                _animate(1, _buildUserCard()),
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

  Widget _buildUserCard() {
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
                'YK',
                style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yusuf Kaya',
                style: AppTextStyles.body.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'yusuf.kaya@example.com',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
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
                  'MEMBER · 2024',
                  style: AppTextStyles.label.copyWith(fontSize: 9),
                ),
              ),
            ],
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
                  onChanged: (v) => setState(() => _notificationsOn = v),
                  activeThumbColor: AppColors.gold,
                  activeTrackColor: const Color(0x40C9A97A),
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
      onTap: () => setState(() => _isLoggedIn = false),
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

// ─── Auth Sheet ───────────────────────────────────────────────────────────────

class _AuthSheet extends StatelessWidget {
  const _AuthSheet({required this.onAuth});
  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'MYT',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.gold,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hoş geldin',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textMuted,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 28),
          _buildAuthButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            bgColor: const Color(0xFF111111),
            textColor: Colors.white,
          ),
          const SizedBox(height: 10),
          _buildAuthButton(
            icon: Icons.language,
            label: 'Continue with Google',
            bgColor: AppColors.background,
            textColor: AppColors.textPrimary,
            border: true,
          ),
          const SizedBox(height: 10),
          _buildAuthButton(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            bgColor: AppColors.background,
            textColor: AppColors.textPrimary,
            border: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Signing in lets you register for events with one tap.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    bool border = false,
  }) {
    return GestureDetector(
      onTap: onAuth,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border
              ? Border.all(color: AppColors.cardBorder, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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
