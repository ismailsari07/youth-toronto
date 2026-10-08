import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/core/content/content_repository.dart';

/// The bundled defaults are the first offline launch's only content: every
/// required field must be there on its own, without a fallback.
void main() {
  final raw = jsonDecode(
    File(ContentRepository.defaultsAsset).readAsStringSync(),
  );
  final b = ContentBundle.parse(
    raw,
    fallback: ContentBundle.empty,
    source: ContentSource.defaults,
  );

  test('is a bundle without a banner', () {
    expect(raw, isA<Map<String, dynamic>>());
    expect((raw as Map)['content'], isNot(contains('app_banner')));
    expect(b.banner, isNull);
  });

  test('has the mosque and the cemetery', () {
    for (final field in [
      b.mosque.name,
      b.mosque.street,
      b.mosque.city,
      b.mosque.postalCode,
      b.mosque.phone,
      b.mosque.email,
      b.cemetery.name,
      b.cemetery.street,
      b.cemetery.city,
    ]) {
      expect(field, isNotEmpty);
    }
    expect(b.mosque.hours, isNotEmpty);
  });

  test('has the services, the burial contacts and every feature on', () {
    expect(b.serviceOf(ServiceKind.marriage), isNotNull);
    expect(b.serviceOf(ServiceKind.burial), isNotNull);
    expect(b.contactsIn('burial'), isNotEmpty);
    final f = b.features;
    expect([
      f.marriageService,
      f.burialService,
      f.events,
      f.announcements,
    ], everyElement(isTrue));
    expect(b.config.minSupportedVersion, isNotNull);
  });

  test('never blocks the app', () {
    expect(b.requiresUpdate('0.0.1'), isFalse);
  });
}
