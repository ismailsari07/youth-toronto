import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icon.dart';
import '../theme/app_tokens.dart';
import '../ui/components/island_tab_bar.dart';

/// Spec §1 and §5. Three tab roots, each with its own navigation stack, and
/// the floating island over content that flows beneath it.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    IslandTab(icon: AppIcons.mosque, label: 'Prayer'),
    IslandTab(icon: AppIcons.calendar, label: 'Community'),
    IslandTab(icon: AppIcons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.ground,
      extendBody: true, // content must flow under the island
      body: navigationShell,
      bottomNavigationBar: IslandTabBar(
        tabs: _tabs,
        index: navigationShell.currentIndex,
        onSelect: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab returns to that tab's root.
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
