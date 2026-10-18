import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/mosque_time.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';

/// The message under a field for a server (or local) `invalid_answers`
/// code. [field] is the key: a question id, `full_name` or `phone`.
String registrationErrorText(AppLocalizations l, String field, String code) =>
    switch ((field, code)) {
      ('full_name', 'required') => l.regErrNameRequired,
      ('full_name', _) => l.regErrNameInvalid,
      ('phone', 'required') => l.regErrPhoneRequired,
      ('phone', _) => l.regErrPhoneInvalid,
      (_, 'required') => l.regErrRequired,
      (_, 'too_long') => l.regErrTooLong,
      (_, 'not_a_number') => l.regErrNotANumber,
      (_, 'not_an_integer') => l.regErrNotAnInteger,
      (_, 'out_of_range') => l.regErrOutOfRange,
      (_, 'unknown_option') => l.regErrUnknownOption,
      (_, 'invalid_date') => l.regErrInvalidDate,
      (_, 'invalid_phone') => l.regErrPhoneInvalid,
      // wrong_type, unknown_question, anything newer: our side, not theirs.
      _ => l.regErrRejected,
    };

/// A deadline on the mosque's clock: "6 Kasım, 6:59 PM".
String registrationWhen(AppLocalizations l, DateTime instant) {
  final t = tz.TZDateTime.from(instant, mosqueTz);
  return '${dayMonthLong(l, t)}, ${eventTime(t)}';
}

/// The app's language code for picking form labels.
String formLanguage(BuildContext context) =>
    Localizations.localeOf(context).languageCode;
