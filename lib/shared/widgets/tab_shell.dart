import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

const _labels = ['Home', 'Prayer', 'Events', 'News', 'Profile'];
const _icons = [
  Icons.home_outlined,
  Icons.access_time_outlined,
  Icons.calendar_month_outlined,
  Icons.campaign_outlined,
  Icons.person_outline,
];
const _activeIcons = [
  Icons.home,
  Icons.access_time,
  Icons.calendar_month,
  Icons.campaign,
  Icons.person,
];
const _paths = ['/', '/prayer', '/events', '/news', '/profile'];

class TabShell extends StatelessWidget {
  final Widget child;
  final String location;

  const TabShell({super.key, required this.child, required this.location});

  int get _currentIndex {
    if (location.startsWith('/prayer')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/news')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    if (index < _paths.length) context.go(_paths[index]);
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.textMuted, width: 0.3),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (int i = 0; i < _labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(context, i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            i == current ? _activeIcons[i] : _icons[i],
                            color: i == current
                                ? AppColors.gold
                                : AppColors.textMuted,
                            size: i == current ? 26 : 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _labels[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: i == current
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
