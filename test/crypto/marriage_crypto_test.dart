import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/crypto/marriage_crypto.dart';
import 'package:myt_flutter/core/crypto/service_keys.dart';
import 'package:myt_flutter/core/crypto/sodium_loader.dart';
import 'package:sodium/sodium.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

Uint8List _b(Object? v) => Uint8List.fromList(base64.decode(v as String));

void main() {
  late Sodium s;
  late KeyPair service;
  final vector = _fixture('marriage-crypto.json');

  setUpAll(() async {
    s = await loadSystemSodium();
    service = KeyPair(
      publicKey: _b(vector['service_public_key']),
      secretKey: s.secureCopy(_b(vector['service_private_key'])),
    );
  });

  Map<String, dynamic>? openAnswers(String id, String sealedKey, String ct) {
    final k = openDataKey(s, _b(sealedKey), service);
    if (k == null) return null;
    try {
      final bytes = decryptPart(s, k, _b(ct), Ad.answers(id), Pad.answers);
      return bytes == null ? null : jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } finally {
      k.dispose();
    }
  }

  test("the panel's shared vector opens with the app's code", () {
    final sub = vector['submission'] as Map<String, dynamic>;
    final expected = vector['expected'] as Map<String, dynamic>;
    expect(openAnswers(sub['id'], sub['sealed_key'], sub['answers_ct']), expected['payload']);
    final k = openDataKey(s, _b(sub['sealed_key']), service)!;
    expect(
      decryptPart(s, k, _b((sub['photos'] as List)[0]), Ad.photo(sub['id'], 1), Pad.photo),
      _b((expected['photos'] as List)[0]),
    );
    k.dispose();
  });

  test("the app's own vector (for the panel) still opens and matches", () {
    final app = _fixture('marriage-crypto-app.json');
    expect(app['service_public_key'], vector['service_public_key']);
    final sub = app['submission'] as Map<String, dynamic>;
    final expected = app['expected'] as Map<String, dynamic>;
    expect(openAnswers(sub['id'], sub['sealed_key'], sub['answers_ct']), expected['payload']);
    final k = openDataKey(s, _b(sub['sealed_key']), service)!;
    final photos = sub['photos'] as List;
    for (var i = 0; i < photos.length; i++) {
      expect(
        decryptPart(s, k, _b(photos[i]), Ad.photo(sub['id'], i + 1), Pad.photo),
        _b((expected['photos'] as List)[i]),
      );
    }
    k.dispose();
  });

  group('sealApplication', () {
    const id = '11111111-2222-4333-8444-555555555555';
    final photo1 = Uint8List.fromList(List.generate(1000, (i) => i % 256));
    final photo2 = Uint8List.fromList(List.generate(65536, (i) => (i * 7) % 256));
    late SealedApplication sealed;
    final payload = answersPayload(
      formVersion: 4,
      answers: {'q_AAAAAAA2': 'İsmail Öz', 'q_PPPPPPPF': [1, 2]},
      photos: [(n: 1, width: 1280, height: 1600), (n: 2, width: 1600, height: 1200)],
      submittedAt: DateTime.utc(2026, 11, 19, 8, 0, 0, 0, 999),
      locale: 'tr',
      appVersion: '1.5.0',
    );

    setUpAll(() {
      sealed = sealApplication(
        s,
        submissionId: id,
        payload: payload,
        photos: [photo1, photo2],
        servicePublicKey: service.publicKey,
      );
    });

    test('sizes match the server checks', () {
      expect(_b(sealed.sealedKey).length, kSealedKeyBytes);
      final ct = _b(sealed.answersCt).length;
      expect(ct, 40 + 4096, reason: 'nonce 24 + tag 16 + one 4 KB block');
      expect(sealed.photos[0].length, 40 + 65536);
      // Exactly one block of data pads to two blocks (ISO/IEC 7816-4 always adds a byte).
      expect(sealed.photos[1].length, 40 + 2 * 65536);
    });

    test('opens to the same payload and photos', () {
      expect(openAnswers(id, sealed.sealedKey, sealed.answersCt), jsonDecode(jsonEncode(payload)));
      final k = openDataKey(s, _b(sealed.sealedKey), service)!;
      expect(decryptPart(s, k, sealed.photos[0], Ad.photo(id, 1), Pad.photo), photo1);
      expect(decryptPart(s, k, sealed.photos[1], Ad.photo(id, 2), Pad.photo), photo2);
      k.dispose();
    });

    test('parts are bound to their row and role', () {
      final k = openDataKey(s, _b(sealed.sealedKey), service)!;
      expect(decryptPart(s, k, sealed.photos[0], Ad.photo(id, 2), Pad.photo), isNull);
      expect(decryptPart(s, k, sealed.photos[0], Ad.photo('00000000-0000-4000-8000-000000000000', 1), Pad.photo), isNull);
      expect(decryptPart(s, k, _b(sealed.answersCt), Ad.photo(id, 1), Pad.answers), isNull);
      final tampered = Uint8List.fromList(sealed.photos[0])..[100] ^= 1;
      expect(decryptPart(s, k, tampered, Ad.photo(id, 1), Pad.photo), isNull);
      k.dispose();
    });

    test('another key does not open it; every sealing is fresh', () {
      final other = s.crypto.box.keyPair();
      expect(openDataKey(s, _b(sealed.sealedKey), other), isNull);
      other.secretKey.dispose();
      final again = sealApplication(s, submissionId: id, payload: payload, photos: const [], servicePublicKey: service.publicKey);
      expect(again.sealedKey, isNot(sealed.sealedKey));
      expect(again.answersCt, isNot(sealed.answersCt));
    });

    test('payload shape is what the panel parses', () {
      expect(payload['v'], 1);
      expect(payload['submitted_at'], '2026-11-19T08:00:00.000Z');
      expect(payload['photos'], [
        {'n': 1, 'width': 1280, 'height': 1600, 'type': 'image/jpeg'},
        {'n': 2, 'width': 1600, 'height': 1200, 'type': 'image/jpeg'},
      ]);
      final noVersion = answersPayload(formVersion: 1, answers: {}, photos: const [], submittedAt: DateTime.utc(2026), locale: 'de');
      expect(noVersion.containsKey('app_version'), isFalse);
      expect(noVersion['locale'], 'tr');
    });
  });

  group('pickServiceKey', () {
    final pk = vector['service_public_key'] as String;
    test('only a key that is active AND pinned', () {
      final rows = [
        {'key_id': 1, 'public_key': pk, 'retired_at': null},
      ];
      expect(pickServiceKey(rows, const {}), isNull, reason: 'nothing pinned');
      expect(pickServiceKey(rows, {1: pk})?.keyId, 1);
      final hex = '\\x${base64.decode(pk).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      expect(pickServiceKey([{'key_id': 1, 'public_key': hex, 'retired_at': null}], {1: pk})?.publicKey,
          base64.decode(pk), reason: 'bytea as PostgREST sends it');
      expect(pickServiceKey(rows, {2: pk}), isNull, reason: 'pinned under another id');
      expect(pickServiceKey([{...rows[0], 'retired_at': '2026-11-19T00:00:00Z'}], {1: pk}), isNull);
      final swapped = base64.encode(s.crypto.box.keyPair().publicKey);
      expect(pickServiceKey([{'key_id': 1, 'public_key': swapped, 'retired_at': null}], {1: pk}), isNull,
          reason: 'a key swapped in the database is refused');
    });
    test('the newest of several', () {
      final pk2 = base64.encode(s.crypto.box.keyPair().publicKey);
      final rows = [
        {'key_id': 1, 'public_key': pk, 'retired_at': null},
        {'key_id': 2, 'public_key': pk2, 'retired_at': null},
      ];
      expect(pickServiceKey(rows, {1: pk, 2: pk2})?.keyId, 2);
      expect(pickServiceKey(rows, {1: pk})?.keyId, 1);
    });
  });

  test('the test key is never pinned', () {
    expect(kPinnedServiceKeys.values, isNot(contains(vector['service_public_key'])));
  });
}
