import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

class IslandTab {
  const IslandTab({required this.icon, required this.label});

  final String icon;
  final String label;
}

/// Spec §5. A detached frosted pill, not a full-width bar: 16 from each side,
/// 64 tall, radius 32, white at 82% over a 24-sigma blur of the content
/// passing beneath it. Use with `Scaffold(extendBody: true)` and a 96 bottom
/// inset on every scroll view.
class IslandTabBar extends StatelessWidget {
  const IslandTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.badgeIndex,
  });

  final List<IslandTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  /// Shows the unread dot on this tab, if any.
  final int? badgeIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.islandInset,
          0,
          AppSpace.islandInset,
          8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.island),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: AppSpace.islandHeight,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xD1FFFFFF), // white 82%
                borderRadius: BorderRadius.circular(AppRadius.island),
                border: Border.all(color: const Color(0xBFFFFFFF)), // white 75%
                boxShadow: AppShadow.island,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _IslandItem(
                        tab: tabs[i],
                        active: i == index,
                        showBadge: badgeIndex == i,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandItem extends StatelessWidget {
  const _IslandItem({
    required this.tab,
    required this.active,
    required this.onTap,
    this.showBadge = false,
  });

  final IslandTab tab;
  final bool active;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    // The tint eases between tabs instead of snapping.
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: active ? AppColor.green : AppColor.tabInactive),
      duration: AppMotion.fast,
      curve: Curves.easeOut,
      builder: (context, color, _) => _item(color!),
    );
  }

  Widget _item(Color color) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSpace.islandHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppIcon(tab.icon, size: 23, color: color),
                if (showBadge)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2453B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: (active ? AppText.tabLabelActive : AppText.tabLabelIdle)
                  .c(color),
            ),
          ],
        ),
      ),
    );
  }
}
