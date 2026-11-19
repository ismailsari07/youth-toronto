// Marriage service, end-to-end encryption: every cryptographic operation the
// app performs, in one file, for the external review (pape-admin
// docs/crypto-review.md). The app only ENCRYPTS: it never holds a key that
// can open an application, its own included.
//
// Same format as pape-admin src/lib/crypto/marriage-crypto.ts and
// marriage-envelope.ts; the shared vector test/fixtures/marriage-crypto.json
// (copied from pape-admin) keeps both sides in step.
//
//   data key K   32 random bytes per application (XChaCha20-Poly1305 key).
//   sealed_key   crypto_box_seal(K, service public key), 80 bytes.
//   part         nonce(24) || XChaCha20-Poly1305(pad(plaintext), AD).
//   answers_ct   part(K, JSON payload, AD answers, 4096-byte blocks)
//   photo n      part(K, JPEG bytes, AD photo n, 65536-byte blocks)
//
// No custom primitives: libsodium through package:sodium (pure functions;
// the caller passes a ready instance, so tests load the system libsodium
// and the app the one sodium_libs bundles). Nothing here logs, talks to the
// network or stores anything.

import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium.dart';

const kContext = 'pape-marriage/v1';

/// Padding blocks: hide exact lengths of answers and photos.
abstract final class Pad {
  static const answers = 4096;
  static const photo = 65536;
}

const kSealedKeyBytes = 32 + 48;

/// Associated data: binds a part to its application and role, so parts
/// can't be swapped between rows or fields.
abstract final class Ad {
  static String answers(String submissionId) =>
      '$kContext|submission|$submissionId|answers';
  static String photo(String submissionId, int n) =>
      '$kContext|submission|$submissionId|photo|$n';
}

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

/// One encrypted part: nonce || ciphertext of the padded plaintext.
Uint8List encryptPart(
  Sodium s,
  SecureKey dataKey,
  Uint8List plaintext,
  String associated,
  int padBlock,
) {
  final aead = s.crypto.aeadXChaCha20Poly1305IETF;
  final nonce = s.randombytes.buf(aead.nonceBytes);
  final padded = s.pad(plaintext, padBlock);
  final ct = aead.encrypt(
    message: padded,
    nonce: nonce,
    key: dataKey,
    additionalData: _utf8(associated),
  );
  padded.fillRange(0, padded.length, 0);
  return Uint8List(nonce.length + ct.length)
    ..setAll(0, nonce)
    ..setAll(nonce.length, ct);
}

/// null = wrong key, wrong row/role (AD) or tampered. Used by the tests
/// (the shared vector); the app itself never decrypts.
Uint8List? decryptPart(
  Sodium s,
  SecureKey dataKey,
  Uint8List part,
  String associated,
  int padBlock,
) {
  final aead = s.crypto.aeadXChaCha20Poly1305IETF;
  final n = aead.nonceBytes;
  if (part.length < n + aead.aBytes + padBlock) return null;
  try {
    final padded = aead.decrypt(
      cipherText: part.sublist(n),
      nonce: part.sublist(0, n),
      key: dataKey,
      additionalData: _utf8(associated),
    );
    return s.unpad(padded, padBlock);
  } on SodiumException {
    return null;
  }
}

/// What goes to the server: base64 fields for the RPC and the photo parts
/// for Storage (`{user}/{id}/{n}.bin`, in order 1…n).
class SealedApplication {
  const SealedApplication({
    required this.sealedKey,
    required this.answersCt,
    required this.photos,
  });

  final String sealedKey;
  final String answersCt;
  final List<Uint8List> photos;

  // Ciphertext only, but keep it out of logs anyway.
  @override
  String toString() => 'SealedApplication(${photos.length} photos)';
}

/// Seals one application: a fresh data key, sealed to [servicePublicKey];
/// the answers JSON and each photo encrypted with it. The data key is
/// wiped before returning.
SealedApplication sealApplication(
  Sodium s, {
  required String submissionId,
  required Map<String, Object?> payload,
  required List<Uint8List> photos,
  required Uint8List servicePublicKey,
}) {
  final k = s.crypto.aeadXChaCha20Poly1305IETF.keygen();
  try {
    final raw = k.extractBytes();
    final sealed = s.crypto.box.seal(message: raw, publicKey: servicePublicKey);
    raw.fillRange(0, raw.length, 0);
    final json = _utf8(jsonEncode(payload));
    final answers = encryptPart(s, k, json, Ad.answers(submissionId), Pad.answers);
    json.fillRange(0, json.length, 0);
    return SealedApplication(
      sealedKey: base64.encode(sealed),
      answersCt: base64.encode(answers),
      photos: [
        for (var i = 0; i < photos.length; i++)
          encryptPart(s, k, photos[i], Ad.photo(submissionId, i + 1), Pad.photo),
      ],
    );
  } finally {
    k.dispose();
  }
}

/// Test-side opening (the key holder's browser does this in the panel):
/// returns the data key, or null when [sealedKey] isn't sealed to [service].
SecureKey? openDataKey(Sodium s, Uint8List sealedKey, KeyPair service) {
  try {
    final k = s.crypto.box.sealOpen(
      cipherText: sealedKey,
      publicKey: service.publicKey,
      secretKey: service.secretKey,
    );
    if (k.length != 32) return null;
    final key = s.secureCopy(k);
    k.fillRange(0, k.length, 0);
    return key;
  } on SodiumException {
    return null;
  }
}

/// The service key to encrypt to: the newest active key in the database
/// that is also pinned in this build, or null (the service isn't open yet,
/// or the database offers a key this build doesn't trust).
({int keyId, Uint8List publicKey})? pickServiceKey(
  List<Map<String, dynamic>> rows,
  Map<int, String> pinned,
) {
  ({int keyId, Uint8List publicKey})? best;
  for (final r in rows) {
    final id = r['key_id'];
    if (id is! int || r['retired_at'] != null) continue;
    final pin = pinned[id];
    final db = r['public_key'];
    if (pin == null || db is! String || db.replaceAll(RegExp(r'\s'), '') != pin) continue;
    if (best == null || id > best.keyId) {
      best = (keyId: id, publicKey: Uint8List.fromList(base64.decode(pin)));
    }
  }
  return best;
}

/// The decrypted answers payload (pape-admin marriage-envelope.ts
/// `AnswersPayload`).
Map<String, Object?> answersPayload({
  required int formVersion,
  required Map<String, Object> answers,
  required List<({int n, int width, int height})> photos,
  required DateTime submittedAt,
  required String locale,
  String? appVersion,
}) {
  final t = submittedAt.toUtc();
  final ms = DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second, t.millisecond);
  return {
    'v': 1,
    'form_version': formVersion,
    'answers': answers,
    'photos': [
      for (final p in photos)
        {'n': p.n, 'width': p.width, 'height': p.height, 'type': 'image/jpeg'},
    ],
    'submitted_at': ms.toIso8601String(),
    'locale': const ['tr', 'en', 'fr'].contains(locale) ? locale : 'tr',
    'app_version': ?appVersion,
  };
}
