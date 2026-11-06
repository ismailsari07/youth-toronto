import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner, 1.4.0: screens call them "Namaz bildirimleri" / "Prayer
/// notifications" / "Notifications de prière" everywhere (Prayer, the sheet,
/// Profile, Settings). "prayerReminders" stays only in the notifications'
/// own wording, which didn't change.
void main() {
  test('only the reminder sync uses prayerReminders', () {
    final users = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            !f.path.startsWith('lib/l10n/') &&
            f.readAsStringSync().contains('.prayerReminders'))
          f.path,
    ];
    expect(users, ['lib/core/reminder_sync.dart']);
  });
}
