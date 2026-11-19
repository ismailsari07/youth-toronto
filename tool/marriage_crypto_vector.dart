// Writes test/fixtures/marriage-crypto-app.json: an application sealed by
// the APP's code to the shared TEST key (from test/fixtures/marriage-crypto.json).
// pape-admin copies it to supabase/tests/fixtures/ and checks that the
// panel opens it (marriage-envelope.test.ts). Run:
//   dart run tool/marriage_crypto_vector.dart
// Needs a system libsodium (see lib/core/crypto/sodium_loader.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:myt_flutter/core/crypto/marriage_crypto.dart';
import 'package:myt_flutter/core/crypto/sodium_loader.dart';

Future<void> main() async {
  final shared = jsonDecode(File('test/fixtures/marriage-crypto.json').readAsStringSync()) as Map;
  final s = await loadSystemSodium();
  const id = '5d2c8e41-7a0b-4f3e-9c6d-1b8a2f4e7c90';
  final photos = [
    // A real (tiny) JPEG is not needed: the panel treats photo parts as bytes.
    Uint8List.fromList(base64.decode('/9j/4AAQSkZJRgABAQAAAQABAAD/2Q==')),
    Uint8List.fromList(List<int>.generate(70000, (i) => (i * 31 + 7) % 256)),
  ];
  final payload = answersPayload(
    formVersion: 1,
    answers: {
      'q_AAAAAAA2': 'Ayşe Çelik — “test”',
      'q_DDDDDDD5': 'o_AAAAA2',
      'q_NNNNNNN3': 172,
      'q_YYYYYYY4': true,
      'q_PPPPPPPF': [1, 2],
    },
    photos: [(n: 1, width: 2, height: 1), (n: 2, width: 1280, height: 1600)],
    submittedAt: DateTime.utc(2026, 11, 19, 15, 30, 0, 250),
    locale: 'fr',
    appVersion: '1.5.0',
  );
  final sealed = sealApplication(
    s,
    submissionId: id,
    payload: payload,
    photos: photos,
    servicePublicKey: Uint8List.fromList(base64.decode(shared['service_public_key'] as String)),
  );
  final out = {
    'note': 'TEST key only (the shared key of marriage-crypto.json). Made by the app\'s sealApplication() '
        '(youth-toronto tool/marriage_crypto_vector.dart); the panel must open it.',
    'service_public_key': shared['service_public_key'],
    'submission': {
      'id': id,
      'form_version': 1,
      'sealed_key': sealed.sealedKey,
      'answers_ct': sealed.answersCt,
      'photos': [for (final p in sealed.photos) base64.encode(p)],
    },
    'expected': {
      'payload': payload,
      'photos': [for (final p in photos) base64.encode(p)],
    },
  };
  File('test/fixtures/marriage-crypto-app.json')
      .writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(out)}\n');
  stdout.writeln('wrote test/fixtures/marriage-crypto-app.json');
}
