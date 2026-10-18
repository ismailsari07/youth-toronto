import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/registration/registration_form.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_row.dart';
import '../../ui/components/app_sheet.dart';
import '../../ui/components/motion.dart';
import 'registration_text.dart';

/// One widget per question type (pape-admin CLAUDE.md §10.2), each in its
/// own card: the label (asterisk when required), a hint, the input, and the
/// error under it.

/// A field label; required ones get a red asterisk, read as "Required".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ).c(context.colors.ink);
    return Semantics(
      label: required ? '$text, ${context.l10n.regRequired}' : text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: text,
          style: style,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: style.copyWith(color: context.colors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

/// The red line under a field.
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AppIcon(AppIcons.alert, size: 14, color: context.colors.danger),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ).c(context.colors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A filled text input with a red outline on error.
class BoxInput extends StatelessWidget {
  const BoxInput({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.error = false,
    this.counter = false,
    this.formatters,
    this.onChanged,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final bool error;

  /// "12/2000" under the box (long text).
  final bool counter;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.neutralTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error ? c.danger : Colors.transparent,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            inputFormatters: formatters,
            onChanged: onChanged,
            cursorColor: c.green,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500).c(c.ink),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 15.5).c(c.placeholder),
              semanticCounterText: '',
            ),
          ),
        ),
        if (counter && maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) => Text(
                '${value.text.characters.length}/$maxLength',
                style: AppText.caption.c(c.ink3),
              ),
            ),
          ),
      ],
    );
  }
}

/// One question in its card. [value] is the answer as it will be sent;
/// [controller] backs the text-based types.
class QuestionField extends StatelessWidget {
  const QuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.controller,
    this.error,
  });

  final Question question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = formLanguage(context);
    final hint = _hint(l);
    return AppCard(
      radius: AppRadius.listCard,
      border: error != null ? Border.all(color: context.colors.dangerBorder) : null,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(pickLabel(question.label, lang), required: question.required),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint, style: AppText.caption.c(context.colors.ink3)),
          ],
          const SizedBox(height: 12),
          _input(context, lang),
          if (error case final e?) FieldError(e),
        ],
      ),
    );
  }

  String? _hint(AppLocalizations l) {
    final q = question;
    switch (q.type) {
      case QuestionType.number:
        final min = q.min, max = q.max;
        final parts = [
          if (min != null && max != null)
            l.regRange(_n(min), _n(max))
          else if (min != null)
            l.regAtLeast(_n(min))
          else if (max != null)
            l.regAtMost(_n(max)),
          if (q.integer) l.regWholeNumber,
        ];
        return parts.isEmpty ? null : parts.join(' · ');
      case QuestionType.multipleChoice:
        return l.regChooseAny;
      default:
        return null;
    }
  }

  static String _n(num v) =>
      v == v.truncate() ? v.toInt().toString() : v.toString();

  Widget _input(BuildContext context, String lang) {
    final l = context.l10n;
    final q = question;
    final hasError = error != null;
    switch (q.type) {
      case QuestionType.shortText:
        return BoxInput(
          controller: controller,
          maxLength: Question.shortMax,
          error: hasError,
          onChanged: onChanged,
        );
      case QuestionType.longText:
        return BoxInput(
          controller: controller,
          maxLength: Question.longMax,
          minLines: 4,
          maxLines: 8,
          counter: true,
          keyboardType: TextInputType.multiline,
          error: hasError,
          onChanged: onChanged,
        );
      case QuestionType.number:
        return BoxInput(
          controller: controller,
          error: hasError,
          keyboardType: TextInputType.numberWithOptions(
            decimal: !q.integer,
            signed: (q.min ?? 0) < 0,
          ),
          formatters: [
            FilteringTextInputFormatter.allow(
              RegExp(q.integer ? r'^-?\d*' : r'^-?\d*[.,]?\d{0,6}'),
            ),
          ],
          onChanged: (s) => onChanged(parseNumberAnswer(s)),
        );
      case QuestionType.phone:
        return BoxInput(
          controller: controller,
          error: hasError,
          hint: '(416) 555-0123',
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
        );
      case QuestionType.singleChoice when q.options.length > Question.radioLimit:
        final picked = q.options.where((o) => o.id == value).firstOrNull;
        return PickerRow(
          key: const Key('choice-picker'),
          text: picked == null ? l.regChoose : pickLabel(picked.label, lang),
          placeholder: picked == null,
          icon: AppIcons.chevronRight,
          error: hasError,
          onTap: () async {
            final id = await showAppSheet<String>(
              context: context,
              builder: (_) => OptionSheet(question: q, selected: value as String?),
            );
            if (id != null) onChanged(id);
          },
        );
      case QuestionType.singleChoice:
      case QuestionType.multipleChoice:
        final multi = q.type == QuestionType.multipleChoice;
        final picked = multi ? {...(value is List ? value as List : const [])} : {value};
        return _ChoiceList(
          multi: multi,
          options: [for (final o in q.options) (o.id, pickLabel(o.label, lang))],
          picked: picked,
          onTap: (id) {
            if (!multi) return onChanged(id);
            final next = [
              for (final o in q.options)
                if (o.id == id ? !picked.contains(id) : picked.contains(o.id)) o.id,
            ];
            onChanged(next.isEmpty ? null : next);
          },
        );
      case QuestionType.yesNo:
        return _YesNo(
          value: value is bool ? value as bool : null,
          onChanged: onChanged,
        );
      case QuestionType.date:
        final day = value is String ? DateTime.tryParse(value as String) : null;
        return PickerRow(
          key: const Key('date-picker'),
          text: day == null ? l.regPickDate : dayMonthYear(l, day),
          placeholder: day == null,
          icon: AppIcons.calendar,
          error: hasError,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: day ?? DateTime(now.year, now.month, now.day),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100, 12, 31),
            );
            if (picked != null) onChanged(isoDate(picked));
          },
        );
      case QuestionType.unknown:
        return Text(l.regUpdateApp, style: AppText.caption.c(context.colors.amber));
    }
  }
}

/// A number field's text → the answer: a number, null when empty, or the
/// text itself when it isn't a number yet (the local check then says so).
Object? parseNumberAnswer(String text) {
  final s = text.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  return num.tryParse(s) ?? text;
}

/// A tappable row that looks like an input: a picker's current value.
class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.text,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.error = false,
  });

  final String text;
  final bool placeholder;
  final String icon;
  final VoidCallback onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.neutralTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: error ? c.danger : Colors.transparent, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: placeholder ? FontWeight.w400 : FontWeight.w500,
                  ).c(placeholder ? c.placeholder : c.ink),
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(icon, size: 18, color: c.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.multi,
    required this.options,
    required this.picked,
    required this.onTap,
  });

  final bool multi;
  final List<(String, String)> options;
  final Set<Object?> picked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (id, label) in options)
          Semantics(
            checked: picked.contains(id),
            inMutuallyExclusiveGroup: !multi,
            label: label,
            excludeSemantics: true,
            child: Pressable(
              onTap: () => onTap(id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _Mark(on: picked.contains(id), round: !multi),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 15.5, height: 1.3)
                              .c(context.colors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A radio dot or a checkbox tick.
class _Mark extends StatelessWidget {
  const _Mark({required this.on, required this.round});

  final bool on;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? c.green : Colors.transparent,
        border: Border.all(color: on ? c.green : c.border, width: 1.6),
        borderRadius: BorderRadius.circular(round ? 12 : 7),
      ),
      child: !on
          ? null
          : round
              ? Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: c.onGreen, shape: BoxShape.circle),
                )
              : AppIcon(AppIcons.check, size: 15, color: c.onGreen),
    );
  }
}

/// Two buttons, neither chosen until tapped, so "unanswered" stays
/// visible (a switch couldn't show it).
class _YesNo extends StatelessWidget {
  const _YesNo({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    Widget button(String label, bool v) {
      final on = value == v;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          inMutuallyExclusiveGroup: true,
          child: Pressable(
            onTap: () => onChanged(v),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? c.green : c.neutralTint,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(label, style: AppText.buttonSmall.c(on ? c.onGreen : c.ink2)),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        button(l.regYes, true),
        const SizedBox(width: 10),
        button(l.regNo, false),
      ],
    );
  }
}

/// A single choice with many options, as a sheet like the app's others.
class OptionSheet extends StatelessWidget {
  const OptionSheet({super.key, required this.question, this.selected});

  final Question question;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final lang = formLanguage(context);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.ground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.grabber,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pickLabel(question.label, lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                  .c(context.colors.ink),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: GroupedRows(
                  rows: [
                    for (final (i, o) in question.options.indexed)
                      AppListRow(
                        divided: i > 0,
                        title: pickLabel(o.label, lang),
                        trailing: o.id == selected
                            ? AppIcon(AppIcons.check, size: 20, color: context.colors.selected)
                            : null,
                        onTap: () => Navigator.of(context).pop(o.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
