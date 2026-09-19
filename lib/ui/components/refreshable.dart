import 'package:flutter/cupertino.dart';

/// Spec §7.15: pull-to-refresh on all three tab roots, with the iOS control.
/// Takes the same children a root's ListView had, so screens keep their
/// existing layout.
class RefreshableList extends StatelessWidget {
  const RefreshableList({
    super.key,
    required this.onRefresh,
    required this.padding,
    required this.children,
  });

  final Future<void> Function() onRefresh;
  final EdgeInsets padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: padding.top),
          sliver: CupertinoSliverRefreshControl(onRefresh: onRefresh),
        ),
        SliverPadding(
          padding: padding.copyWith(top: 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(children),
          ),
        ),
      ],
    );
  }
}
