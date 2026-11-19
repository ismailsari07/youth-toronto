import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';
import 'package:myt_flutter/features/marriage/data/marriage_application.dart';
import 'package:myt_flutter/features/marriage/data/marriage_v2_service.dart';
import 'package:myt_flutter/features/marriage/marriage_routes.dart';

void main() {
  group('marriage_form_v2 switch', () {
    test('missing, false or not a boolean = off; only true turns it on', () {
      const fallbackOn = AppFeatures(marriageFormV2: true);
      expect(AppFeatures.parse({'marriage_service': true}, fallbackOn).marriageFormV2, isFalse,
          reason: 'missing never takes the fallback');
      expect(AppFeatures.parse({'marriage_form_v2': false}, fallbackOn).marriageFormV2, isFalse);
      expect(AppFeatures.parse({'marriage_form_v2': 'true'}, fallbackOn).marriageFormV2, isFalse);
      expect(AppFeatures.parse({'marriage_form_v2': true}, const AppFeatures()).marriageFormV2, isTrue);
      expect(const AppFeatures().marriageFormV2, isFalse);
    });

    test('the bundled defaults keep it off', () {
      final raw = File('assets/content_defaults.json').readAsStringSync();
      expect(raw.contains('"marriage_form_v2": true'), isFalse);
    });
  });

  group('entryFor', () {
    final doc = MarriageApplication.fromRow({
      'file_path': 'u/x.pdf', 'mime_type': 'application/pdf', 'size_bytes': 10, 'created_at': '2026-11-01T10:00:00Z',
    });
    final sub = MarriageSubmission.fromRow({
      'id': '11111111-2222-4333-8444-555555555555', 'status': 'under_review', 'photo_count': 1,
      'created_at': '2026-11-19T10:00:00Z',
    });

    test('signed out → gate, whatever the switch', () {
      expect(MarriageRoutes.entryFor(signedIn: false, application: null, formV2: true), MarriageRoutes.gate);
    });
    test('switch off: the document upload, as before', () {
      expect(MarriageRoutes.entryFor(signedIn: true, application: null), MarriageRoutes.upload);
      expect(MarriageRoutes.entryFor(signedIn: true, application: doc), MarriageRoutes.status);
    });
    test('switch on: the new form for members without an application', () {
      expect(MarriageRoutes.entryFor(signedIn: true, application: null, formV2: true), MarriageRoutes.form);
    });
    test('an existing application always wins over the switch', () {
      expect(MarriageRoutes.entryFor(signedIn: true, application: doc, formV2: true), MarriageRoutes.status,
          reason: 'an old document stays visible and can be withdrawn');
      expect(MarriageRoutes.entryFor(signedIn: true, application: null, submission: sub), MarriageRoutes.submitted,
          reason: 'an encrypted application stays visible after the switch goes off');
      expect(MarriageRoutes.entryFor(signedIn: true, application: null, submission: sub, formV2: true),
          MarriageRoutes.submitted);
    });
    test('after a withdrawal', () {
      expect(MarriageRoutes.startFor(formV2: false), MarriageRoutes.upload);
      expect(MarriageRoutes.startFor(formV2: true), MarriageRoutes.form);
    });
  });

  test('server errors map to reasons (pape-admin submit_marriage_application)', () {
    expect(MarriageV2Service.failureFor('P0001', 'unavailable'), SubmitFailure.closed);
    expect(MarriageV2Service.failureFor('P0001', 'key_changed'), SubmitFailure.closed);
    expect(MarriageV2Service.failureFor('P0001', 'not_adult'), SubmitFailure.notAdult);
    expect(MarriageV2Service.failureFor('P0001', 'already_applied'), SubmitFailure.alreadyApplied);
    expect(MarriageV2Service.failureFor('23505', 'duplicate key'), SubmitFailure.alreadyApplied);
    expect(MarriageV2Service.failureFor('P0001', 'form_changed'), SubmitFailure.formChanged);
    expect(MarriageV2Service.failureFor('P0001', 'photos_missing'), SubmitFailure.sendFailed);
    expect(MarriageV2Service.failureFor('22023', 'invalid_photos'), SubmitFailure.sendFailed);
    expect(MarriageV2Service.failureFor('42501', 'not signed in'), SubmitFailure.sendFailed);
  });

  test('the model never prints personal data', () {
    final sub = MarriageSubmission.fromRow({
      'id': '11111111-2222-4333-8444-555555555555', 'status': 'under_review', 'photo_count': 1,
      'created_at': '2026-11-19T10:00:00Z',
    });
    expect(sub.toString(), 'MarriageSubmission');
  });
}
