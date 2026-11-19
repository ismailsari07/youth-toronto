import 'dart:convert';

/// Marriage application form, format v2 (pape-admin `marriage_forms.schema`).
///
/// One definition, three implementations kept in step by shared test cases
/// (pape-admin `supabase/tests/fixtures/marriage-forms.json`, copied as is to
/// `test/fixtures/`):
///   - pape-admin `src/lib/forms/marriage-form.ts` (panel builder, viewer),
///   - this file (the app),
///   - `marriage_form_valid()` in SQL (schema only).
///
/// Answers are end-to-end encrypted, so the server never sees them: the
/// answer checks here run before sending, and the key holder's browser runs
/// the same checks after decrypting. Works on decoded JSON (maps and lists)
/// so it can be tested against the shared cases without a model layer.

const fieldTypes = {
  'short_text',
  'long_text',
  'number',
  'single_choice',
  'multiple_choice',
  'yes_no',
  'date',
  'phone',
  'email',
  'photos',
  'consent',
};

abstract final class FormLimits {
  static const sections = 15;
  static const fields = 60;
  static const options = 20;
  static const sectionTitle = 120;
  static const label = 300;
  static const consentLabel = 500;
  static const help = 300;
  static const option = 100;
  static const unit = 12;
  static const shortMax = 500;
  static const longMax = 5000;
  static const shortDefault = 200;
  static const longDefault = 2000;
  static const bound = 1000000000;
  static const photos = 3;

  /// Compact JSON, as the panel measures it.
  static const bytes = 65536;
  static const minAge = 18;
}

final _sectionId = RegExp(r'^s_[A-HJ-NP-Z2-9]{8}$');
final _fieldId = RegExp(r'^q_[A-HJ-NP-Z2-9]{8}$');
final _optionId = RegExp(r'^o_[A-HJ-NP-Z2-9]{6}$');
final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Characters as the database counts them (code points).
int _chars(String s) => s.runes.length;

bool _onlyKeys(Map m, List<String> keys) => m.keys.every(keys.contains);
bool _isInt(Object? v) => v is int || (v is double && v.isFinite && v == v.truncateToDouble());
bool _isNum(Object? v) => v is num && v.isFinite;

/// `{tr, en?, fr?}` → the chosen language, else English, else Turkish.
String pickText(Object? raw, String lang) {
  if (raw is! Map) return '';
  for (final key in [lang, 'en', 'tr']) {
    final v = raw[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

/// Same rule as SQL `i18n_ok()`.
bool i18nOk(Object? v, {required bool required, required int max}) {
  if (v == null) return !required;
  if (v is! Map) return false;
  final tr = v['tr'];
  if (tr is! String || tr.trim().isEmpty) return false;
  return v.entries.every((e) =>
      const ['tr', 'en', 'fr'].contains(e.key) &&
      e.value is String &&
      (e.value as String).trim().isNotEmpty &&
      _chars(e.value as String) <= max);
}

const _common = ['id', 'type', 'required', 'label', 'help', 'show_if'];
const _keys = <String, List<String>>{
  'short_text': [..._common, 'max_length'],
  'long_text': [..._common, 'max_length'],
  'number': [..._common, 'min', 'max', 'integer', 'unit'],
  'single_choice': [..._common, 'options'],
  'multiple_choice': [..._common, 'options'],
  'yes_no': _common,
  'date': [..._common, 'role'],
  'phone': [..._common, 'prefill'],
  'email': [..._common, 'prefill'],
  'photos': ['id', 'type', 'required', 'label', 'help', 'min', 'max'],
  'consent': ['id', 'type', 'required', 'label', 'help'],
};

/// The rules `marriage_form_valid()` applies. The app refuses to show a form
/// that fails them (the server never stores one, so this is a safety net).
bool marriageFormValid(Object? form) {
  if (form is! Map || !_onlyKeys(form, const ['sections'])) return false;
  final sections = form['sections'];
  if (sections is! List || sections.isEmpty || sections.length > FormLimits.sections) return false;
  if (utf8.encode(jsonEncode(form)).length > FormLimits.bytes) return false;

  final sectionIds = <String>{};
  final seen = <String, Map>{};
  var total = 0;
  var photos = 0;
  var births = 0;

  for (final s in sections) {
    if (s is! Map || !_onlyKeys(s, const ['id', 'title', 'help', 'fields'])) return false;
    final sid = s['id'];
    if (sid is! String || !_sectionId.hasMatch(sid) || !sectionIds.add(sid)) return false;
    if (!i18nOk(s['title'], required: true, max: FormLimits.sectionTitle)) return false;
    if (!i18nOk(s['help'], required: false, max: FormLimits.help)) return false;
    final fields = s['fields'];
    if (fields is! List || fields.isEmpty) return false;

    for (final f in fields) {
      total++;
      if (total > FormLimits.fields || f is! Map) return false;
      final id = f['id'];
      if (id is! String || !_fieldId.hasMatch(id) || seen.containsKey(id)) return false;
      final type = f['type'];
      final keys = _keys[type];
      if (type is! String || keys == null || !_onlyKeys(f, keys)) return false;
      if (f['required'] is! bool) return false;
      if (!i18nOk(f['label'],
          required: true, max: type == 'consent' ? FormLimits.consentLabel : FormLimits.label)) {
        return false;
      }
      if (!i18nOk(f['help'], required: false, max: FormLimits.help)) return false;

      switch (type) {
        case 'short_text':
        case 'long_text':
          final max = type == 'short_text' ? FormLimits.shortMax : FormLimits.longMax;
          final m = f['max_length'];
          if (f.containsKey('max_length') && (!_isInt(m) || (m as num) < 1 || m > max)) return false;
        case 'number':
          for (final k in const ['min', 'max']) {
            if (f.containsKey(k) && (!_isNum(f[k]) || (f[k] as num).abs() > FormLimits.bound)) return false;
          }
          if (_isNum(f['min']) && _isNum(f['max']) && (f['min'] as num) > (f['max'] as num)) return false;
          if (f.containsKey('integer') && f['integer'] is! bool) return false;
          if (f.containsKey('unit')) {
            final u = f['unit'];
            if (u is! String || u.trim().isEmpty || _chars(u) > FormLimits.unit) return false;
          }
        case 'single_choice':
        case 'multiple_choice':
          final options = f['options'];
          if (options is! List || options.length < 2 || options.length > FormLimits.options) return false;
          final ids = <String>{};
          for (final o in options) {
            if (o is! Map || !_onlyKeys(o, const ['id', 'label'])) return false;
            final oid = o['id'];
            if (oid is! String || !_optionId.hasMatch(oid) || !ids.add(oid)) return false;
            if (!i18nOk(o['label'], required: true, max: FormLimits.option)) return false;
          }
        case 'date':
          if (f.containsKey('role') && f['role'] != 'birth_date') return false;
          if (f['role'] == 'birth_date' && ++births > 1) return false;
        case 'phone':
          if (f.containsKey('prefill') && f['prefill'] != 'profile') return false;
        case 'email':
          if (f.containsKey('prefill') && f['prefill'] != 'account') return false;
        case 'photos':
          if (++photos > 1) return false;
          final min = f['min'];
          final max = f['max'];
          if (!_isInt(min) || !_isInt(max) || (min as num) < 1 || (max as num) > FormLimits.photos || min > max) {
            return false;
          }
        case 'consent':
          if (f['required'] != true) return false;
      }

      if (f.containsKey('show_if')) {
        final c = f['show_if'];
        if (c is! Map || c['field'] is! String) return false;
        final target = seen[c['field']];
        if (target == null) return false;
        if (target['type'] == 'single_choice') {
          final ids = {for (final o in target['options'] as List) (o as Map)['id']};
          final any = c['any_of'];
          if (!_onlyKeys(c, const ['field', 'any_of']) ||
              any is! List ||
              any.isEmpty ||
              any.toSet().length != any.length ||
              !any.every((v) => v is String && ids.contains(v))) {
            return false;
          }
        } else if (target['type'] == 'yes_no') {
          if (!_onlyKeys(c, const ['field', 'equals']) || c['equals'] is! bool) return false;
        } else {
          return false;
        }
      }
      seen[id] = f;
    }
  }
  return true;
}

List<Map> allFields(Map form) => [
      for (final s in form['sections'] as List)
        for (final f in (s as Map)['fields'] as List) f as Map,
    ];

/// Same as SQL `phone_normalize()`.
String? phoneNormalize(String? raw) {
  if (raw == null || _chars(raw) > 40) return null;
  final d = raw.replaceAll(RegExp(r'[\s().-]'), '');
  if (RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(d)) return d;
  if (RegExp(r'^[2-9][0-9]{9}$').hasMatch(d)) return '+1$d';
  if (RegExp(r'^1[2-9][0-9]{9}$').hasMatch(d)) return '+$d';
  return null;
}

/// "YYYY-MM-DD", a real day, 1900–2100.
bool isIsoDate(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return false;
  final y = int.parse(v.substring(0, 4));
  final m = int.parse(v.substring(5, 7));
  final d = int.parse(v.substring(8, 10));
  final dt = DateTime.utc(y, m, d);
  return dt.year == y && dt.month == m && dt.day == d && y >= 1900 && y <= 2100;
}

/// Whole years from [dob] to [today] (both "YYYY-MM-DD").
int ageOn(String dob, String today) {
  final y1 = int.parse(dob.substring(0, 4)), m1 = int.parse(dob.substring(5, 7)), d1 = int.parse(dob.substring(8, 10));
  final y2 = int.parse(today.substring(0, 4)), m2 = int.parse(today.substring(5, 7)), d2 = int.parse(today.substring(8, 10));
  return y2 - y1 - ((m2 < m1 || (m2 == m1 && d2 < d1)) ? 1 : 0);
}

bool _isEmpty(Object? v) => v == null || (v is String && v.trim().isEmpty) || (v is List && v.isEmpty);

/// Is the field shown for these answers? A field with `show_if` is shown
/// only when its target is shown and answered as the condition says.
bool isVisible(Map form, Map answers, String fieldId) {
  final byId = {for (final f in allFields(form)) f['id']: f};
  bool check(String id, int depth) {
    final f = byId[id];
    if (f == null || depth > FormLimits.fields) return false;
    final c = f['show_if'];
    if (c is! Map) return true;
    if (!check(c['field'] as String, depth + 1)) return false;
    final v = answers[c['field']];
    return c.containsKey('any_of') ? v is String && (c['any_of'] as List).contains(v) : v == c['equals'];
  }

  return check(fieldId, 0);
}

class AnswerCheck {
  const AnswerCheck(this.errors, this.clean);

  /// `{field id | "_answers": code}`; empty = can be sent.
  final Map<String, String> errors;

  /// What is encrypted and sent: hidden fields dropped, texts trimmed, empty
  /// values removed, multiple choices in form order, phones E.164.
  final Map<String, Object> clean;
}

/// Checks and normalises answers for [form]. [today] is the applicant's
/// Toronto day ("YYYY-MM-DD"). Every error comes back at once.
AnswerCheck validateAnswers(Map form, Map answers, String today) {
  final errors = <String, String>{};
  final clean = <String, Object>{};
  final fields = allFields(form);
  final known = {for (final f in fields) f['id']};
  if (answers.keys.any((k) => !known.contains(k))) errors['_answers'] = 'unknown_question';

  for (final f in fields) {
    final id = f['id'] as String;
    if (!isVisible(form, answers, id)) continue;
    final v = answers[id];
    final type = f['type'];

    if (type == 'consent') {
      if (v != null && v is! bool) {
        errors[id] = 'wrong_type';
      } else if (v != true) {
        errors[id] = 'required';
      } else {
        clean[id] = true;
      }
      continue;
    }
    if (_isEmpty(v)) {
      if (f['required'] == true) errors[id] = 'required';
      continue;
    }

    void set(String? code, [Object? value]) {
      if (code != null) {
        errors[id] = code;
      } else {
        clean[id] = value!;
      }
    }

    switch (type) {
      case 'short_text':
      case 'long_text':
        if (v is! String) {
          set('wrong_type');
        } else {
          final t = v.trim();
          final max = (f['max_length'] as num?)?.toInt() ??
              (type == 'short_text' ? FormLimits.shortDefault : FormLimits.longDefault);
          set(_chars(t) > max ? 'too_long' : null, t);
        }
      case 'number':
        if (!_isNum(v)) {
          set('not_a_number');
        } else if (f['integer'] == true && !_isInt(v)) {
          set('not_an_integer');
        } else if ((f['min'] != null && (v as num) < (f['min'] as num)) ||
            (f['max'] != null && (v as num) > (f['max'] as num))) {
          set('out_of_range');
        } else {
          set(null, v);
        }
      case 'single_choice':
        final ids = [for (final o in f['options'] as List) (o as Map)['id']];
        if (v is! String) {
          set('wrong_type');
        } else {
          set(ids.contains(v) ? null : 'unknown_option', v);
        }
      case 'multiple_choice':
        final ids = [for (final o in f['options'] as List) (o as Map)['id'] as String];
        if (v is! List || !v.every((x) => x is String)) {
          set('wrong_type');
        } else if (!v.every(ids.contains)) {
          set('unknown_option');
        } else {
          set(null, ids.where(v.contains).toList());
        }
      case 'yes_no':
        set(v is bool ? null : 'wrong_type', v);
      case 'date':
        if (!isIsoDate(v)) {
          set('invalid_date');
        } else if (f['role'] == 'birth_date' && (v as String).compareTo(today) > 0) {
          set('invalid_date');
        } else if (f['role'] == 'birth_date' && ageOn(v as String, today) < FormLimits.minAge) {
          set('too_young');
        } else {
          set(null, v);
        }
      case 'phone':
        if (v is! String) {
          set('wrong_type');
        } else {
          final p = phoneNormalize(v);
          set(p == null ? 'invalid_phone' : null, p);
        }
      case 'email':
        if (v is! String) {
          set('wrong_type');
        } else {
          final e = v.trim();
          set(e.length > 254 || !_email.hasMatch(e) ? 'invalid_email' : null, e);
        }
      case 'photos':
        final max = (f['max'] as num).toInt();
        final min = (f['min'] as num).toInt();
        if (v is! List || !v.every(_isInt)) {
          set('wrong_type');
        } else {
          final ns = [for (final n in v) (n as num).toInt()];
          if (ns.toSet().length != ns.length || ns.any((n) => n < 1 || n > max) || ns.length < min || ns.length > max) {
            set('wrong_count');
          } else {
            set(null, ns..sort());
          }
        }
    }
  }
  return AnswerCheck(errors, clean);
}
