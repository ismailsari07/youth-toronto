import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// The tab roots, kept alive in an indexed stack exactly as go_router's
/// default container keeps them: hidden tabs are offstage with their tickers
/// off (the moon card relies on `TickerMode` to stop its timer). The tab
/// being shown fades in over [AppMotion.fast]; under Reduce Motion it
/// appears at once.
class FadingBranchContainer extends StatefulWidget {
  const FadingBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadingBranchContainer> createState() => _FadingBranchContainerState();
}

class _FadingBranchContainerState extends State<FadingBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    value: 1,
  );
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _fade, curve: Curves.easeOut);

  @override
  void didUpdateWidget(FadingBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    if (AppMotion.reduced(context)) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
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
              child: FadeTransition(
                // Only the active tab follows the fade; the others sit at
                // full opacity, ready to be shown.
                opacity: i == widget.currentIndex
                    ? _opacity
                    : kAlwaysCompleteAnimation,
                child: widget.children[i],
              ),
            ),
          ),
      ],
    );
  }
}
