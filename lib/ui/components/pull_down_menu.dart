import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// One action in a [showPullDownMenu]. [icon] sits on the trailing side, as
/// iOS draws an SF Symbol in a menu.
class PullDownItem {
  const PullDownItem({required this.title, required this.onTap, this.icon});

  final String title;
  final String? icon;
  final VoidCallback onTap;
}

/// An iOS pull-down menu (a UIMenu opened from a button), anchored to the
/// widget [context] belongs to: below it when there is room, else above;
/// aligned to its trailing edge when it sits on the right half of the
/// screen. Frosted, 250 pt wide, 13 pt corners, grows out of the anchor's
/// corner. A finger can slide across the items and lift on one, as on iOS.
///
/// [sections] are separated by the thick iOS break; [title] is the small
/// grey line at the top. The picked item's [PullDownItem.onTap] runs as the
/// menu closes.
Future<void> showPullDownMenu(
  BuildContext context, {
  String? title,
  required List<List<PullDownItem>> sections,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final box = context.findRenderObject()! as RenderBox;
  final ancestor = navigator.context.findRenderObject()! as RenderBox;
  final anchor =
      box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  final picked = await navigator.push(
    _PullDownRoute(
      anchor: anchor,
      title: title,
      sections: [
        for (final s in sections)
          if (s.isNotEmpty) s,
      ],
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
  picked?.onTap();
}

const double _kWidth = 250;
const double _kMargin = 16; // from the screen's safe edges
const double _kGap = 8; // between the anchor and the menu
const double _kRadius = 13;
const double _kSectionGap = 8;
const double _kBlur = 30;

/// UIKit's menu spring, approximated: fast out with a slight overshoot.
const Curve _kOpenCurve = Cubic(0.075, 0.82, 0.4, 1.065);
const Duration _kOpen = Duration(milliseconds: 300);
const Duration _kClose = Duration(milliseconds: 200);

class _PullDownRoute extends PopupRoute<PullDownItem> {
  _PullDownRoute({
    required this.anchor,
    required this.title,
    required this.sections,
    required this.barrierLabel,
  });

  final Rect anchor;
  final String? title;
  final List<List<PullDownItem>> sections;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => _kOpen;

  @override
  Duration get reverseTransitionDuration => _kClose;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final below = anchor.center.dy < size.height * 0.6;
    final trailing = anchor.center.dx >= size.width / 2;
    final origin = Alignment(trailing ? 1 : -1, below ? -1 : 1);

    final menu = _PullDownMenu(title: title, sections: sections);
    final Widget moving;
    if (AppMotion.reduced(context)) {
      moving = menu;
    } else {
      moving = ScaleTransition(
        alignment: origin,
        scale: Tween(begin: 0.25, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: _kOpenCurve,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: menu,
      );
    }
    return CustomSingleChildLayout(
      delegate: _MenuPosition(
        anchor: anchor,
        safe: media.padding,
        below: below,
        trailing: trailing,
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.35),
          reverseCurve: Curves.easeIn,
        ),
        // A route of its own has no Material above it: without this, text
        // falls back to the debug style.
        child: Material(type: MaterialType.transparency, child: moving),
      ),
    );
  }
}

class _MenuPosition extends SingleChildLayoutDelegate {
  _MenuPosition({
    required this.anchor,
    required this.safe,
    required this.below,
    required this.trailing,
  });

  final Rect anchor;
  final EdgeInsets safe;
  final bool below;
  final bool trailing;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final room = below
        ? size.height - safe.bottom - _kMargin - anchor.bottom - _kGap
        : anchor.top - _kGap - safe.top - _kMargin;
    return BoxConstraints(
      minWidth: 0,
      maxWidth: math.min(_kWidth, size.width - 2 * _kMargin),
      maxHeight: math.max(room, 0),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (trailing ? anchor.right - child.width : anchor.left)
        .clamp(_kMargin, math.max(_kMargin, size.width - _kMargin - child.width))
        .toDouble();
    final y = below ? anchor.bottom + _kGap : anchor.top - _kGap - child.height;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuPosition old) =>
      old.anchor != anchor ||
      old.safe != safe ||
      old.below != below ||
      old.trailing != trailing;
}

class _PullDownMenu extends StatefulWidget {
  const _PullDownMenu({required this.title, required this.sections});

  final String? title;
  final List<List<PullDownItem>> sections;

  @override
  State<_PullDownMenu> createState() => _PullDownMenuState();
}

class _PullDownMenuState extends State<_PullDownMenu> {
  late final List<PullDownItem> _items = [
    for (final s in widget.sections) ...s,
  ];
  late final List<GlobalKey> _keys = [
    for (final _ in _items) GlobalKey(),
  ];
  int? _highlighted;
  bool _moved = false;

  int? _itemAt(Offset global) {
    for (final (i, key) in _keys.indexed) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final local = box.globalToLocal(global);
      if ((Offset.zero & box.size).contains(local)) return i;
    }
    return null;
  }

  void _track(Offset global) {
    final i = _itemAt(global);
    if (i == _highlighted) return;
    if (_moved && i != null) HapticFeedback.selectionClick();
    setState(() => _highlighted = i);
  }

  void _pick(int i) => Navigator.of(context).pop(_items[i]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hairline = Container(height: 0.5, color: colors.menuSeparator);
    final children = <Widget>[];

    final title = widget.title;
    if (title != null) {
      children
        ..add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 9),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, height: 1.3)
                  .c(colors.ink3),
            ),
          ),
        )
        ..add(hairline);
    }
    var index = 0;
    for (final (s, section) in widget.sections.indexed) {
      if (s > 0) {
        children.add(Container(height: _kSectionGap, color: colors.menuGap));
      }
      for (final (j, item) in section.indexed) {
        if (j > 0) children.add(hairline);
        final i = index++;
        children.add(
          _ItemTile(
            key: _keys[i],
            item: item,
            highlighted: _highlighted == i,
            onTap: () => _pick(i),
          ),
        );
      }
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: context.shadows.menu,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: _kBlur, sigmaY: _kBlur),
            child: ColoredBox(
              color: colors.menuBg,
              // Raw pointers, so a finger can press, slide to another item
              // and lift there; the scroll view only matters at very large
              // text sizes.
              child: Listener(
                onPointerDown: (e) {
                  _moved = false;
                  _track(e.position);
                },
                onPointerMove: (e) {
                  _moved = true;
                  _track(e.position);
                },
                onPointerUp: (e) {
                  final i = _itemAt(e.position);
                  if (i != null) {
                    _pick(i);
                  } else {
                    setState(() => _highlighted = null);
                  }
                },
                onPointerCancel: (_) => setState(() => _highlighted = null),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    super.key,
    required this.item,
    required this.highlighted,
    required this.onTap,
  });

  final PullDownItem item;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = item.icon;
    return Semantics(
      button: true,
      label: item.title,
      onTap: onTap,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        color: highlighted ? colors.menuPressed : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  letterSpacing: -0.4,
                ).c(colors.ink),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 12),
              AppIcon(icon, size: 20, color: colors.ink),
            ],
          ],
        ),
      ),
    );
  }
}
