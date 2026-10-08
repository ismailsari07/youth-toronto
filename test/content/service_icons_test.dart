import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/theme/app_icon.dart';

void main() {
  // The panel's choices (pape-admin src/lib/content.ts, SERVICE_ICONS).
  const panelIcons = [
    'heart',
    'leaf',
    'book',
    'moon',
    'users',
    'calendar',
    'mosque',
    'info',
  ];

  test('every panel icon has an icon file', () {
    for (final name in panelIcons) {
      final icon = AppIcons.forService(name);
      expect(File('assets/icons/$icon.svg').existsSync(), isTrue, reason: name);
    }
  });

  test('the crescent is Isha, anything unknown is info', () {
    expect(AppIcons.forService('moon'), AppIcons.isha);
    expect(AppIcons.forService('rocket'), AppIcons.info);
  });
}
