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
    this.header,
  });

  final Future<void> Function() onRefresh;
  final EdgeInsets padding;
  final List<Widget> children;

  /// Full-bleed content above [children], outside [padding] (the Prayer
  /// home's hero). The refresh spinner then sits on it, so it is drawn for
  /// a dark background.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: padding.top),
          sliver: header == null
              ? CupertinoSliverRefreshControl(onRefresh: onRefresh)
              : CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: CupertinoSliverRefreshControl(onRefresh: onRefresh),
                ),
        ),
        if (header != null) SliverToBoxAdapter(child: header),
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
