import 'package:flutter/foundation.dart';

/// An event's registration form (pape-admin CLAUDE.md §10.2): 0–10
/// questions of eight types, labels in `{tr, en?, fr?}`. Parsed
/// defensively: the server validates the form when the panel saves it, and
/// a type this app doesn't know is kept as [QuestionType.unknown].

/// `{tr, en?, fr?}` → the device language, else English, else Turkish.
/// An absent language is missing (the server never stores '').
String pickLabel(Object? raw, String lang) {
  if (raw is! Map) return '';
  for (final key in [lang, 'en', 'tr']) {
    final v = raw[key];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return '';
}

enum QuestionType {
  shortText('short_text'),
  longText('long_text'),
  number('number'),
  singleChoice('single_choice'),
  multipleChoice('multiple_choice'),
  yesNo('yes_no'),
  date('date'),
  phone('phone'),

  /// Added after this version (D6): skipped when optional; when required
  /// the form can't be sent and asks for an update.
  unknown('');

  const QuestionType(this.wire);

  final String wire;

  static QuestionType parse(Object? raw) => values.firstWhere(
        (t) => t != unknown && t.wire == raw,
        orElse: () => unknown,
      );
}

@immutable
class ChoiceOption {
  const ChoiceOption(this.id, this.label);

  final String id;
  final Map<String, dynamic> label;
}

@immutable
class Question {
  const Question({
    required this.id,
    required this.type,
    required this.required,
    required this.label,
    this.options = const [],
    this.min,
    this.max,
    this.integer = false,
  });

  final String id;
  final QuestionType type;
  final bool required;
  final Map<String, dynamic> label;

  /// single_choice / multiple_choice only, in display order.
  final List<ChoiceOption> options;
  final num? min;
  final num? max;

  /// number only. A missing key means decimals, as the server reads it
  /// (§10's "default true" is wrong; decided 2026-10-18, D1).
  final bool integer;

  /// Above this many options a single choice opens a sheet instead of radios.
  static const radioLimit = 6;

  static const shortMax = 200;
  static const longMax = 2000;

  static Question? parse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    Map<String, dynamic> label(Object? l) =>
        l is Map ? l.cast<String, dynamic>() : const {};
    return Question(
      id: raw['id'] as String,
      type: QuestionType.parse(raw['type']),
      required: raw['required'] == true,
      label: label(raw['label']),
      options: [
        for (final o in (raw['options'] is List ? raw['options'] as List : const []))
          if (o is Map && o['id'] is String)
            ChoiceOption(o['id'] as String, label(o['label'])),
      ],
      min: raw['min'] is num ? raw['min'] as num : null,
      max: raw['max'] is num ? raw['max'] as num : null,
      integer: raw['integer'] == true,
    );
  }

  /// `{"questions": [...]}` → the questions, skipping malformed ones.
  static List<Question> parseForm(Object? form) {
    final list = form is Map ? form['questions'] : null;
    if (list is! List) return const [];
    return [
      for (final q in list) ?parse(q),
    ];
  }

  /// Whether [value] is a valid answer shape for this question as it is
  /// now. Used to keep answers after the form changed (§10.4 form_changed).
  bool accepts(Object? value) => switch (type) {
        QuestionType.shortText ||
        QuestionType.longText ||
        QuestionType.phone =>
          value is String,
        QuestionType.number => value is num,
        QuestionType.yesNo => value is bool,
        QuestionType.date => value is String,
        QuestionType.singleChoice =>
          value is String && options.any((o) => o.id == value),
        QuestionType.multipleChoice => value is List &&
            value.isNotEmpty &&
            value.every((v) => options.any((o) => o.id == v)),
        QuestionType.unknown => false,
      };
}

/// True when [value] counts as unanswered (§10.2: the key is left out).
bool isUnanswered(Object? value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is List && value.isEmpty);

/// What `register_for_event` gets as `p_answers`: answered questions only,
/// text trimmed, choices in the form's order.
Map<String, Object> answersPayload(
  List<Question> questions,
  Map<String, Object?> answers,
) {
  final out = <String, Object>{};
  for (final q in questions) {
    final v = answers[q.id];
    if (q.type == QuestionType.unknown || isUnanswered(v)) continue;
    out[q.id] = switch (v) {
      final String s => s.trim(),
      final List picked => [
          for (final o in q.options)
            if (picked.contains(o.id)) o.id,
        ],
      _ => v!,
    };
  }
  return out;
}

/// After `form_changed`: the answers whose question still exists and still
/// accepts them (same id and type; for choices, options still there).
Map<String, Object?> keepAnswers(
  Map<String, Object?> answers,
  List<Question> questions,
) {
  final byId = {for (final q in questions) q.id: q};
  return {
    for (final MapEntry(:key, :value) in answers.entries)
      if (byId[key]?.accepts(value) ?? false) key: value,
  };
}

/// A required question this version can't show: the form can't be sent.
bool needsUpdate(List<Question> questions) =>
    questions.any((q) => q.required && q.type == QuestionType.unknown);

/// Mirror of the server's phone_normalize(): Canadian/US numbers and
/// "+" with 8–15 digits. Null when the server would refuse it.
String? normalizePhone(String? raw) {
  if (raw == null || raw.length > 40) return null;
  final d = raw.replaceAll(RegExp(r'[\s().-]'), '');
  if (RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(d)) return d;
  if (RegExp(r'^[2-9][0-9]{9}$').hasMatch(d)) return '+1$d';
  if (RegExp(r'^1[2-9][0-9]{9}$').hasMatch(d)) return '+$d';
  return null;
}

/// The checks the server runs (event_form_check and the name/phone rules
/// of register_for_event), so most mistakes show before sending. Same
/// codes as the server's `invalid_answers` details. The server stays the
/// judge.
Map<String, String> localErrors(
  List<Question> questions,
  Map<String, Object?> answers, {
  String? fullName,
  String? phone,
}) {
  final errors = <String, String>{};
  if (fullName != null) {
    final name = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) {
      errors['full_name'] = 'required';
    } else if (name.length > 120) {
      errors['full_name'] = 'invalid';
    }
  }
  if (phone != null) {
    if (phone.trim().isEmpty) {
      errors['phone'] = 'required';
    } else if (normalizePhone(phone) == null) {
      errors['phone'] = 'invalid';
    }
  }
  for (final q in questions) {
    final v = answers[q.id];
    if (isUnanswered(v)) {
      if (q.required) errors[q.id] = 'required';
      continue;
    }
    final code = switch (q.type) {
      QuestionType.shortText when (v as String).trim().length > Question.shortMax =>
        'too_long',
      QuestionType.longText when (v as String).trim().length > Question.longMax =>
        'too_long',
      QuestionType.number => _numberError(q, v),
      QuestionType.date => _validDate(v) ? null : 'invalid_date',
      QuestionType.phone => normalizePhone(v as String) == null ? 'invalid_phone' : null,
      QuestionType.singleChoice || QuestionType.multipleChoice =>
        q.accepts(v) ? null : 'unknown_option',
      _ => null,
    };
    if (code != null) errors[q.id] = code;
  }
  return errors;
}

String? _numberError(Question q, Object? v) {
  if (v is! num) return 'not_a_number';
  if (q.integer && v != v.truncate()) return 'not_an_integer';
  final decimals = v.toString().contains('.') && v is double
      ? v.toString().split('.').last.replaceAll(RegExp(r'0+$'), '').length
      : 0;
  if ((q.min != null && v < q.min!) ||
      (q.max != null && v > q.max!) ||
      v.abs() > 1e12 ||
      decimals > 6) {
    return 'out_of_range';
  }
  return null;
}

bool _validDate(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return false;
  final d = DateTime.tryParse(v);
  if (d == null) return false;
  // DateTime rolls 02-30 over to March; the server refuses it.
  return isoDate(d) == v && d.year >= 1900 && d.year <= 2100;
}

/// A date as the server wants it.
String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
