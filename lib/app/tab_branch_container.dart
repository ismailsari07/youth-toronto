import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../ui/components/stagger.dart';

/// The tab roots, kept alive in an indexed stack exactly as go_router's
/// default container keeps them: hidden tabs are offstage with their tickers
/// off (the moon card relies on `TickerMode` to stop its timer).
///
/// Each time a tab becomes active — and once at launch — its sections play
/// the staggered entrance ([StaggerItem]); that cascade *is* the tab
/// transition, so there is no separate fade. Only the index changing starts
/// it: refreshes, data arriving and popping a pushed screen (pushes sit on
/// the root navigator, so the tab never changed) leave it alone. Under
/// Reduce Motion everything appears at once.
class TabBranchContainer extends StatefulWidget {
  const TabBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<TabBranchContainer> createState() => _TabBranchContainerState();
}

class _TabBranchContainerState extends State<TabBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.staggerTotal,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  @override
  void didUpdateWidget(TabBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) _play();
  }

  void _play() {
    if (AppMotion.reduced(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentIndex,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.currentIndex,
            child: TickerMode(
              enabled: i == widget.currentIndex,
              // Only the active tab follows the entrance; the others sit
              // fully arrived, ready to be shown.
              child: TabEntrance(
                animation: i == widget.currentIndex
                    ? _entrance
                    : kAlwaysCompleteAnimation,
                child: widget.children[i],
              ),
            ),
          ),
      ],
    );
  }
}
