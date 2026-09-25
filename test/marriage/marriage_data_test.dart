import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/features/marriage/data/document_check.dart';
import 'package:myt_flutter/features/marriage/data/document_upload.dart';
import 'package:myt_flutter/features/marriage/data/marriage_application.dart';
import 'package:myt_flutter/features/marriage/data/marriage_service.dart';
import 'package:myt_flutter/features/marriage/marriage_provider.dart';

void main() {
  group('object path', () {
    const uid = '60c8985e-b770-47b5-81b1-173fe612e9f5';
    final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

    test('is {uid}/{uuid v4}.{ext from the bytes}', () {
      final path = MarriageService.newObjectPath(uid, DocumentKind.png);
      final parts = path.split('/');
      expect(parts, hasLength(2));
      expect(parts[0], uid);
      expect(parts[1], endsWith('.png'));
      expect(uuid.hasMatch(parts[1].replaceAll('.png', '')), isTrue);
    });

    test('is different every time', () {
      final paths = {
        for (var i = 0; i < 200; i++)
          MarriageService.newObjectPath(uid, DocumentKind.pdf),
      };
      expect(paths, hasLength(200));
    });

    test('uuidV4 sets the version and variant bits', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(uuid.hasMatch(uuidV4(Random(seed))), isTrue);
      }
    });
  });

  group('eligibility', () {
    final today = DateTime(2026, 9, 25);
    MarriageEligibility at(String? dob) => eligibilityFor(dob, today: today);

    test('no date of birth asks for one', () {
      expect(at(null), MarriageEligibility.needsDateOfBirth);
      expect(at(''), MarriageEligibility.needsDateOfBirth);
      expect(at('not a date'), MarriageEligibility.needsDateOfBirth);
    });

    test('18 on the birthday itself, not the day before', () {
      expect(at('2008-09-25'), MarriageEligibility.eligible);
      expect(at('2008-09-26'), MarriageEligibility.underAge);
      expect(at('1995-03-10'), MarriageEligibility.eligible);
      expect(at('2012-01-15'), MarriageEligibility.underAge);
    });

    test('29 February birthdays turn 18 on 28 February, like Postgres', () {
      expect(eligibilityFor('2008-02-29', today: DateTime(2026, 2, 28)),
          MarriageEligibility.eligible);
      expect(eligibilityFor('2008-02-29', today: DateTime(2026, 2, 27)),
          MarriageEligibility.underAge);
    });
  });

  group('application row', () {
    test('reads the row and never prints its contents', () {
      final app = MarriageApplication.fromRow({
        'file_path': 'uid/abc.jpg',
        'mime_type': 'image/jpeg',
        'size_bytes': 1843,
        'created_at': '2026-09-12T14:00:00+00:00',
      });
      expect(app.kind, DocumentKind.jpg);
      expect(app.sizeBytes, 1843);
      expect(app.toString(), isNot(contains('uid/abc.jpg')));
    });
  });

  group('upload', () {
    late HttpServer server;
    late List<int> received;
    late HttpHeaders receivedHeaders;
    int status = 200;
    Completer<void>? holdResponse;

    setUp(() async {
      status = 200;
      holdResponse = null;
      received = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        receivedHeaders = request.headers;
        try {
          await for (final chunk in request) {
            received.addAll(chunk);
          }
        } catch (_) {
          return; // client aborted
        }
        await holdResponse?.future;
        request.response.statusCode = status;
        await request.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    Uri endpoint() => Uri.parse(
        'http://127.0.0.1:${server.port}/storage/v1/object/marriage-documents/u/x.pdf');

    Uint8List body(int size) =>
        Uint8List.fromList(List.generate(size, (i) => i % 251));

    test('sends every byte with the JWT, type and no upsert', () async {
      final bytes = body(300 * 1024);
      final seen = <double>[];
      final upload = DocumentUpload.start(
        endpoint: endpoint(),
        headers: {'Authorization': 'Bearer jwt', 'apikey': 'anon'},
        bytes: bytes,
        contentType: 'application/pdf',
      );
      upload.progress.addListener(() => seen.add(upload.progress.value));
      await upload.done;

      expect(received, bytes);
      expect(receivedHeaders.value('authorization'), 'Bearer jwt');
      expect(receivedHeaders.value('apikey'), 'anon');
      expect(receivedHeaders.value('content-type'), 'application/pdf');
      expect(receivedHeaders.value('x-upsert'), 'false');
      // Real, rising progress in chunk steps, 100% only at the end.
      expect(seen.length, greaterThan(3));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
      expect(seen.where((p) => p == 1), hasLength(1));
      expect(seen.last, 1);
      upload.dispose();
    });

    test('holds at 99% until the server has stored the object', () async {
      holdResponse = Completer<void>();
      final upload = DocumentUpload.start(
        endpoint: endpoint(),
        headers: const {},
        bytes: body(128 * 1024),
        contentType: 'image/png',
      );
      while (received.length < 128 * 1024) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(upload.progress.value, closeTo(0.99, 0.001));
      holdResponse!.complete();
      await upload.done;
      expect(upload.progress.value, 1);
      upload.dispose();
    });

    test('a refused upload fails without server text', () async {
      status = 400;
      final upload = DocumentUpload.start(
        endpoint: endpoint(),
        headers: const {},
        bytes: body(1024),
        contentType: 'application/pdf',
      );
      await expectLater(
        upload.done,
        throwsA(isA<UploadFailed>()
            .having((e) => e.cancelled, 'cancelled', isFalse)
            .having((e) => e.toString(), 'text', 'UploadFailed')),
      );
      upload.dispose();
    });

    test('cancel aborts mid-upload and reports cancelled', () async {
      holdResponse = Completer<void>();
      final upload = DocumentUpload.start(
        endpoint: endpoint(),
        headers: const {},
        bytes: body(4 * 1024 * 1024),
        contentType: 'application/pdf',
      );
      while (upload.progress.value == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      upload.cancel();
      await expectLater(
        upload.done,
        throwsA(isA<UploadFailed>()
            .having((e) => e.cancelled, 'cancelled', isTrue)),
      );
      expect(upload.progress.value, lessThan(1));
      holdResponse!.complete();
      upload.dispose();
    });
  });
}
