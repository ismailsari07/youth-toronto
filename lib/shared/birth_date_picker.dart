import 'package:flutter/material.dart';

/// The earliest date of birth the picker offers.
final firstBirthDate = DateTime(1920);

/// A date of birth: opens on the year list, so nobody pages back month by
/// month. Choosing a year goes on to that year's calendar. Its texts come from
/// Flutter's own translations (MaterialApp's localizationsDelegates).
Future<DateTime?> showBirthDatePicker(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = initial ?? DateTime(now.year - 25);
  return showDatePicker(
    context: context,
    initialDate: start.isBefore(firstBirthDate)
        ? firstBirthDate
        : (start.isAfter(today) ? today : start),
    firstDate: firstBirthDate,
    lastDate: today,
    initialDatePickerMode: DatePickerMode.year,
  );
}
