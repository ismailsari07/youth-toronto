import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'motion.dart';

/// Every text field in the app goes through this (a test keeps it that way),
/// so the keyboard always has a way out:
/// - a tap anywhere outside a field closes it (iOS doesn't by itself);
/// - return on a one-line field moves to the next field, or on the last one
///   runs [onSubmit] (else closes the keyboard);
/// - number, phone and multi-line fields have no usable return key, so on
///   iOS they get [KeyboardAccessoryHost]'s Done bar.
/// Scroll views holding fields also set
/// `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
class AppTextInput extends StatefulWidget {
  const AppTextInput({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.style,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.onChanged,
    this.last = false,
    this.onSubmit,
    this.cursorColor,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Color? cursorColor;

  /// The screen's last field: return says "Done" instead of "Next".
  final bool last;

  /// Return on the last field (sign in, save); null just closes the keyboard.
  final VoidCallback? onSubmit;

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  /// Mounted inputs, for the bar's arrows and for "Next".
  static final _mounted = <_AppTextInputState>{};

  final focusNode = FocusNode();

  bool get _multiline => widget.maxLines != 1;

  /// No usable return key: the number and phone pads have none, and return
  /// in a multi-line field is a new line.
  bool get wantsBar =>
      _multiline ||
      widget.keyboardType == TextInputType.phone ||
      widget.keyboardType?.index == TextInputType.number.index;

  bool get _canFocus => mounted && !widget.readOnly && focusNode.canRequestFocus;

  @override
  void initState() {
    super.initState();
    _mounted.add(this);
  }

  @override
  void dispose() {
    _mounted.remove(this);
    focusNode.dispose();
    super.dispose();
  }

  static _AppTextInputState? _focused() =>
      _mounted.where((s) => s.focusNode.hasPrimaryFocus).firstOrNull;

  /// The other focusable inputs on the same route, in reading order.
  List<_AppTextInputState> _siblings() {
    final route = ModalRoute.of(context);
    final list = _mounted
        .where((s) => s._canFocus && ModalRoute.of(s.context) == route)
        .where((s) => s.context.findRenderObject()?.attached ?? false)
        .toList();
    Offset at(_AppTextInputState s) =>
        (s.context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    list.sort((a, b) {
      final (pa, pb) = (at(a), at(b));
      final dy = pa.dy.compareTo(pb.dy);
      return dy != 0 ? dy : pa.dx.compareTo(pb.dx);
    });
    return list;
  }

  _AppTextInputState? _neighbour(int step) {
    final list = _siblings();
    final i = list.indexOf(this);
    final j = i + step;
    return i < 0 || j < 0 || j >= list.length ? null : list[j];
  }

  void _editingComplete() {
    if (widget.last) {
      focusNode.unfocus();
      widget.onSubmit?.call();
      return;
    }
    final next = _neighbour(1);
    if (next != null) {
      next.focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: focusNode,
      decoration: widget.decoration,
      style: widget.style,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      cursorColor: widget.cursorColor,
      textInputAction: _multiline
          ? TextInputAction.newline
          : widget.last
              ? TextInputAction.done
              : TextInputAction.next,
      onEditingComplete: _multiline ? null : _editingComplete,
      // Flutter only does this on desktop and the web.
      onTapOutside: (_) => focusNode.unfocus(),
      // Room below the caret for a counter or an error line.
      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
    );
  }
}

/// Wraps the app (MaterialApp.builder). While an [AppTextInput] that needs it
/// is focused on iOS with the keyboard up, shows the Done bar on top of the
/// keyboard and tells everything below that the keyboard is that much
/// taller, so scaffolds, sheets and the focused field all clear the bar.
class KeyboardAccessoryHost extends StatefulWidget {
  const KeyboardAccessoryHost({super.key, required this.child});

  final Widget child;

  static const height = 44.0;

  @override
  State<KeyboardAccessoryHost> createState() => _KeyboardAccessoryHostState();
}

class _KeyboardAccessoryHostState extends State<KeyboardAccessoryHost> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    super.dispose();
  }

  // Focus can change mid-build or mid-layout; rebuild only when that's safe.
  void _focusChanged() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      if (mounted) setState(() {});
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final field = _AppTextInputState._focused();
    final show = defaultTargetPlatform == TargetPlatform.iOS &&
        keyboard > 0 &&
        field != null &&
        field.wantsBar;
    // The same tree either way, so the app below is never rebuilt from scratch.
    return Stack(
      children: [
        MediaQuery(
          data: show
              ? mq.copyWith(
                  viewInsets: mq.viewInsets.copyWith(
                    bottom: keyboard + KeyboardAccessoryHost.height,
                  ),
                )
              : mq,
          child: widget.child,
        ),
        if (show)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            child: _AccessoryBar(field: field),
          ),
      ],
    );
  }
}

class _AccessoryBar extends StatelessWidget {
  const _AccessoryBar({required this.field});

  final _AppTextInputState field;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final previous = field._neighbour(-1);
    final next = field._neighbour(1);

    Widget arrow(int quarterTurns, String label, _AppTextInputState? to, Key key) => Semantics(
          button: true,
          enabled: to != null,
          label: label,
          child: Pressable(
            key: key,
            onTap: to == null ? null : () => to.focusNode.requestFocus(),
            child: SizedBox(
              width: 44,
              height: KeyboardAccessoryHost.height,
              child: Center(
                child: RotatedBox(
                  quarterTurns: quarterTurns,
                  child: AppIcon(
                    AppIcons.chevronLeft,
                    size: 20,
                    color: to == null ? c.ink4 : c.green,
                  ),
                ),
              ),
            ),
          ),
        );

    // Inside the fields' tap region: tapping the bar isn't "outside".
    return TextFieldTapRegion(
      child: Container(
        key: const Key('keyboard-accessory'),
        height: KeyboardAccessoryHost.height,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barBorder)),
        ),
        child: Row(
          children: [
            arrow(1, l.keyboardPrevious, previous, const Key('keyboard-previous')),
            arrow(3, l.keyboardNext, next, const Key('keyboard-next')),
            const Spacer(),
            Semantics(
              button: true,
              child: Pressable(
                key: const Key('keyboard-done'),
                onTap: field.focusNode.unfocus,
                child: Container(
                  height: KeyboardAccessoryHost.height,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: Text(
                    l.keyboardDone,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)
                        .c(c.green),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
