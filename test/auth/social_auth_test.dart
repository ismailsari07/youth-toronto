import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/auth_service.dart';
import 'package:myt_flutter/core/social_auth.dart';
import 'package:myt_flutter/l10n/app_localizations_en.dart';
import 'package:myt_flutter/l10n/app_localizations_tr.dart';
import 'package:myt_flutter/l10n/l10n.dart';

void main() {
  group('nonce', () {
    test('hash is the SHA-256 hex Apple and Google expect', () {
      expect(
        hashNonce('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('raw nonce: 32 random bytes, URL-safe, no padding, fresh each time',
        () {
      final a = generateRawNonce();
      final b = generateRawNonce();
      expect(a, isNot(b));
      expect(a, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(base64Url.decode('$a='), hasLength(32));
      expect(generateRawNonce(Random(1)), generateRawNonce(Random(1)));
    });
  });

  group('appleFullName', () {
    test('given and family, trimmed and joined', () {
      expect(appleFullName('Ayşe', 'Yılmaz'), 'Ayşe Yılmaz');
      expect(appleFullName('  Ali ', ' Veli  '), 'Ali Veli');
      expect(appleFullName('Ali  Can', 'Er'), 'Ali Can Er');
    });

    test('one part only', () {
      expect(appleFullName('Ali', null), 'Ali');
      expect(appleFullName(null, 'Veli'), 'Veli');
      expect(appleFullName('', 'Veli'), 'Veli');
    });

    test('nothing shared (every later sign-in) → null', () {
      expect(appleFullName(null, null), isNull);
      expect(appleFullName('', '  '), isNull);
    });
  });

  group('isAutomaticName (same rule as set_my_initial_name)', () {
    test("'' (Apple without a name) is automatic", () {
      expect(isAutomaticName('', 'x7k2q9@privaterelay.appleid.com'), isTrue);
      expect(isAutomaticName('', ''), isTrue);
      expect(isAutomaticName('', null), isTrue);
    });

    test('the part of the email before the @ is automatic', () {
      expect(isAutomaticName('zeynep.ak', 'zeynep.ak@gmail.com'), isTrue);
    });

    test('a real name is not; nor is an unloaded profile', () {
      expect(isAutomaticName('Zeynep Ak', 'zeynep.ak@gmail.com'), isFalse);
      expect(isAutomaticName('zeynep', 'zeynep.ak@gmail.com'), isFalse);
      expect(isAutomaticName(null, 'zeynep.ak@gmail.com'), isFalse);
    });
  });

  group('PendingAppleName', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    Future<List<String>> flush(String? uid, {bool done = true}) async {
      final sent = <String>[];
      await PendingAppleName.flush(uid, (name) async {
        sent.add(name);
        return done;
      });
      return sent;
    }

    test('saved name is sent for its account, then cleared', () async {
      await PendingAppleName.save('u1', 'Ali Veli');
      expect(await flush('u1'), ['Ali Veli']);
      expect(await flush('u1'), isEmpty);
    });

    test('a failed send keeps it for the next launch', () async {
      await PendingAppleName.save('u1', 'Ali Veli');
      expect(await flush('u1', done: false), ['Ali Veli']);
      expect(await flush('u1'), ['Ali Veli']);
    });

    test("another account's name waits for that account", () async {
      await PendingAppleName.save('u1', 'Ali Veli');
      expect(await flush('u2'), isEmpty);
      expect(await flush(null), isEmpty);
      expect(await flush('u1'), ['Ali Veli']);
    });

    test('clear (account deleted) drops it', () async {
      await PendingAppleName.save('u1', 'Ali Veli');
      await PendingAppleName.clear();
      expect(await flush('u1'), isEmpty);
    });

    test('unreadable data is ignored', () async {
      FlutterSecureStorage.setMockInitialValues({'pending_apple_name': '{'});
      expect(await flush('u1'), isEmpty);
    });
  });

  group('delete-account answers', () {
    test('map to failures', () {
      expect(deleteFailureFor(401, null), AuthFailure.sessionExpired);
      expect(deleteFailureFor(409, {'error': 'admin_account'}),
          AuthFailure.adminAccount);
      expect(deleteFailureFor(409, {'error': 'apple_mismatch'}),
          AuthFailure.appleMismatch);
      expect(deleteFailureFor(428, {'error': 'apple_reauth_required'}),
          AuthFailure.appleReauthRequired);
      expect(deleteFailureFor(502, {'error': 'apple_revoke_failed'}),
          AuthFailure.appleRevokeFailed);
      expect(deleteFailureFor(502, null), AuthFailure.deleteFailed);
      expect(deleteFailureFor(500, {'error': 'delete_failed'}),
          AuthFailure.deleteFailed);
      expect(deleteFailureFor(409, 'not json'), AuthFailure.deleteFailed);
      expect(deleteFailureFor(428, null), AuthFailure.deleteFailed);
    });
  });

  group('error texts', () {
    AuthError e(AuthFailure kind) => (kind: kind, serverMessage: null);

    test('a closed sheet says nothing', () {
      expect(authErrorText(AppLocalizationsEn(), e(AuthFailure.cancelled)), '');
    });

    test('provider and Apple ID mismatch have their own sentences', () {
      final en = AppLocalizationsEn();
      final tr = AppLocalizationsTr();
      expect(authErrorText(en, e(AuthFailure.providerFailed)),
          en.errorProviderFailed);
      expect(authErrorText(tr, e(AuthFailure.appleMismatch)),
          tr.errorAppleMismatch);
      expect(authErrorText(en, e(AuthFailure.appleReauthRequired)),
          en.errorDeleteFailed);
      expect(authErrorText(tr, e(AuthFailure.appleRevokeFailed)),
          tr.errorAppleRevokeFailed);
      expect(authErrorText(en, e(AuthFailure.appleRevokeFailed)),
          isNot(en.errorDeleteFailed));
    });
  });
}
