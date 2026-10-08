import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../shared/providers/content_provider.dart';
import '../shared/providers/unread_provider.dart';
import '../theme/app_icon.dart';
import '../theme/app_tokens.dart';
import '../ui/components/island_tab_bar.dart';

/// Spec §1 and §5. Three tab roots, each with its own navigation stack, and
/// the floating island over content that flows beneath it. The Community
/// tab leaves the island while the panel turns off both events and
/// announcements; the branches themselves never change.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unread announcements dot the Community tab, where they live (spec §5
    // puts it on Profile; moved deliberately).
    final unread = ref.watch(hasUnreadAnnouncementsProvider);
    final showCommunity =
        ref.watch(contentProvider.select((c) => c.showCommunity));
    final l = context.l10n;
    // The branch behind each island tab.
    final branches = [0, if (showCommunity) 1, 2];
    final current = navigationShell.currentIndex;
    if (!branches.contains(current)) {
      // Community was turned off while open: back to Prayer.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => navigationShell.goBranch(0),
      );
    }
    return Scaffold(
      backgroundColor: AppColor.ground,
      extendBody: true, // content must flow under the island
      body: navigationShell,
      bottomNavigationBar: IslandTabBar(
        tabs: [
          IslandTab(icon: AppIcons.mosque, label: l.tabPrayer),
          if (showCommunity)
            IslandTab(icon: AppIcons.calendar, label: l.tabCommunity),
          IslandTab(icon: AppIcons.person, label: l.tabProfile),
        ],
        index: branches.contains(current) ? branches.indexOf(current) : 0,
        badgeIndex: unread && showCommunity ? 1 : null,
        onSelect: (i) => navigationShell.goBranch(
          branches[i],
          // Tapping the active tab returns to that tab's root.
          initialLocation: branches[i] == current,
        ),
      ),
    );
  }
}
