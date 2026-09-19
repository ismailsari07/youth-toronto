import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../shared/providers/unread_provider.dart';
import '../theme/app_icon.dart';
import '../theme/app_tokens.dart';
import '../ui/components/island_tab_bar.dart';

/// Spec §1 and §5. Three tab roots, each with its own navigation stack, and
/// the floating island over content that flows beneath it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    IslandTab(icon: AppIcons.mosque, label: AppStrings.tabPrayer),
    IslandTab(icon: AppIcons.calendar, label: AppStrings.tabCommunity),
    IslandTab(icon: AppIcons.person, label: AppStrings.tabProfile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unread announcements dot the Community tab, where they live (spec §5
    // puts it on Profile; moved deliberately).
    final unread = ref.watch(hasUnreadAnnouncementsProvider);
    return Scaffold(
      backgroundColor: AppColor.ground,
      extendBody: true, // content must flow under the island
      body: navigationShell,
      bottomNavigationBar: IslandTabBar(
        tabs: _tabs,
        index: navigationShell.currentIndex,
        badgeIndex: unread ? 1 : null,
        onSelect: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab returns to that tab's root.
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
