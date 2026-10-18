import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/push/device_identity.dart';
import 'package:myt_flutter/core/push/push_api.dart';
import 'package:myt_flutter/core/push/push_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

const payload = DevicePayload(
  token: null,
  locale: 'tr',
  appVersion: '1.0.8',
  pushAuthorized: false,
  events: true,
  announcements: true,
);

void main() {
  late FakePushApi api;
  late MemoryIdentityStore store;
  late DateTime now;
  late PushSync sync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakePushApi();
    store = MemoryIdentityStore();
    now = DateTime(2026, 10, 15, 12);
    sync = PushSync(api: api, identities: store, clock: () => now);
  });

  group('identity', () {
    test('a UUID v4 and a 43-character base64url secret', () {
      final id = DeviceIdentity.generate();
      expect(
        id.installId,
        matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        )),
      );
      expect(id.secret, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(DeviceIdentity.generate().secret, isNot(id.secret));
    });

    test('created once and kept', () async {
      final first = await sync.identity();
      expect(await sync.identity(), same(first));
      expect(store.writes, 1);
    });
  });

  group('fingerprint', () {
    test('the secret is not part of it', () {
      expect(payload.fingerprint('id-1'), payload.fingerprint('id-1'));
      expect(payload.fingerprint('id-1'), isNot(payload.fingerprint('id-2')));
    });

    test('every field changes it', () {
      final base = payload.fingerprint('id');
      for (final changed in [
        const DevicePayload(token: 'tok', locale: 'tr', appVersion: '1.0.8', pushAuthorized: false, events: true, announcements: true),
        const DevicePayload(token: null, locale: 'en', appVersion: '1.0.8', pushAuthorized: false, events: true, announcements: true),
        const DevicePayload(token: null, locale: 'tr', appVersion: '1.0.9', pushAuthorized: false, events: true, announcements: true),
        const DevicePayload(token: null, locale: 'tr', appVersion: '1.0.8', pushAuthorized: true, events: true, announcements: true),
        const DevicePayload(token: null, locale: 'tr', appVersion: '1.0.8', pushAuthorized: false, events: false, announcements: true),
        const DevicePayload(token: null, locale: 'tr', appVersion: '1.0.8', pushAuthorized: false, events: true, announcements: false),
      ]) {
        expect(changed.fingerprint('id'), isNot(base));
      }
    });
  });

  group('when to register', () {
    test('needsRegister: changed, never, or a day old', () {
      final t = DateTime(2026, 10, 15);
      expect(
        PushSync.needsRegister(fingerprint: 'a', lastFingerprint: 'a', lastOkAt: t, now: t.add(const Duration(hours: 23))),
        isFalse,
      );
      expect(
        PushSync.needsRegister(fingerprint: 'a', lastFingerprint: 'a', lastOkAt: t, now: t.add(const Duration(hours: 24))),
        isTrue,
      );
      expect(
        PushSync.needsRegister(fingerprint: 'b', lastFingerprint: 'a', lastOkAt: t, now: t),
        isTrue,
      );
      expect(
        PushSync.needsRegister(fingerprint: 'a', lastFingerprint: null, lastOkAt: null, now: t),
        isTrue,
      );
    });

    test('the same payload is sent once a day', () async {
      expect(await sync.register(payload), 'ABCD2345');
      await sync.register(payload);
      now = now.add(const Duration(hours: 23));
      await sync.register(payload);
      expect(api.calls, ['register']);
      now = now.add(const Duration(hours: 1));
      await sync.register(payload);
      expect(api.calls, ['register', 'register']);
    });

    test('a change is sent at once', () async {
      await sync.register(payload);
      await sync.register(const DevicePayload(
        token: null,
        locale: 'fr',
        appVersion: '1.0.8',
        pushAuthorized: false,
        events: true,
        announcements: true,
      ));
      expect(api.calls, ['register', 'register']);
    });

    test('throttled: nothing saved, an hour of quiet, then again', () async {
      api.throttle = true;
      expect(await sync.register(payload), 'ABCD2345');
      api.throttle = false;
      now = now.add(const Duration(minutes: 59));
      await sync.register(payload);
      expect(api.calls, ['register']);
      now = now.add(const Duration(minutes: 1));
      await sync.register(payload);
      expect(api.calls, ['register', 'register']);
    });
  });

  group('register errors', () {
    test('42501: a new identity registers again', () async {
      final old = await sync.identity();
      api.registerErrors.add(PushError.wrongSecret);
      expect(await sync.register(payload), 'ABCD2345');
      expect(api.calls, ['register', 'register']);
      expect(api.registered.single.installId, isNot(old.installId));
      expect(store.identity!.installId, api.registered.single.installId);
    });

    test('42501: muted events are sent again under the new identity',
        () async {
      SharedPreferences.setMockInitialValues({
        'push_muted_events': ['e1', 'e2'],
      });
      api.registerErrors.add(PushError.wrongSecret);
      await sync.register(payload);
      expect(api.mutes, [('e1', false), ('e2', false)]);
    });

    test('53400: an hour of quiet', () async {
      api.registerErrors.add(PushError.limited);
      expect(await sync.register(payload), isNull);
      now = now.add(const Duration(minutes: 30));
      await sync.register(payload, force: true);
      expect(api.calls, ['register']);
    });

    test('22023 and network errors: no retry', () async {
      api.registerErrors.add(PushError.invalid);
      await sync.register(payload);
      expect(api.calls, ['register']);
      api.registerErrors.add(PushError.network);
      await sync.register(payload);
      expect(api.calls, ['register', 'register']);
      // Neither was remembered as a success.
      await sync.register(payload);
      expect(api.calls.length, 3);
    });
  });

  group('per-event toggle', () {
    test('saved, and remembered locally', () async {
      expect(
        await sync.setEvent('e1', enabled: false, payload: payload),
        MuteOutcome.saved,
      );
      expect((await PushSync.loadLocal()).muted, {'e1'});
      await sync.setEvent('e1', enabled: true, payload: payload);
      expect((await PushSync.loadLocal()).muted, isEmpty);
    });

    test('P0002 once: register, retry, saved', () async {
      api.eventErrors.add(PushError.notFound);
      expect(
        await sync.setEvent('e1', enabled: false, payload: payload),
        MuteOutcome.saved,
      );
      expect(api.calls, ['event', 'register', 'event']);
    });

    test('P0002 twice while muting: the event is gone', () async {
      api.eventErrors.addAll([PushError.notFound, PushError.notFound]);
      expect(
        await sync.setEvent('e1', enabled: false, payload: payload),
        MuteOutcome.gone,
      );
      expect((await PushSync.loadLocal()).muted, isEmpty);
    });

    test('53400, 22023 or offline: failed, no retry', () async {
      for (final error in [
        PushError.limited,
        PushError.invalid,
        PushError.network,
      ]) {
        api.calls.clear();
        api.eventErrors.add(error);
        expect(
          await sync.setEvent('e1', enabled: false, payload: payload),
          MuteOutcome.failed,
        );
        expect(api.calls, ['event']);
      }
    });

    test('42501: new identity, register, retry', () async {
      api.eventErrors.add(PushError.wrongSecret);
      expect(
        await sync.setEvent('e1', enabled: false, payload: payload),
        MuteOutcome.saved,
      );
      expect(api.calls, ['event', 'register', 'event']);
    });
  });

  group('reinstall', () {
    test('Keychain identity and no local choices: restored from the server',
        () async {
      store.identity = DeviceIdentity.generate();
      api.settings = const DeviceSettings(
        events: false,
        announcements: true,
        deviceCode: 'K7QM2X9P',
        mutedEventIds: {'e9'},
      );
      final restored = await sync.restoreIfReinstalled();
      expect(restored!.events, isFalse);
      final local = await PushSync.loadLocal();
      expect(local.saved, isTrue);
      expect(local.events, isFalse);
      expect(local.muted, {'e9'});
      expect(local.deviceCode, 'K7QM2X9P');
    });

    test('first launch (no identity) or local choices present: nothing',
        () async {
      expect(await sync.restoreIfReinstalled(), isNull);
      store.identity = DeviceIdentity.generate();
      await PushSync.saveSwitches(events: true, announcements: true);
      expect(await sync.restoreIfReinstalled(), isNull);
      expect(api.calls, isEmpty);
    });

    test('unknown device: nothing to restore', () async {
      store.identity = DeviceIdentity.generate();
      api.settingsError = PushError.notFound;
      expect(await sync.restoreIfReinstalled(), isNull);
    });
  });

  group('error codes', () {
    test('PostgrestException codes map to PushError', () {
      PushError of(String code) => PushException.classify(
            PostgrestException(message: 'x', code: code),
          );
      expect(of('42501'), PushError.wrongSecret);
      expect(of('P0002'), PushError.notFound);
      expect(of('53400'), PushError.limited);
      expect(of('22023'), PushError.invalid);
      expect(of('08006'), PushError.network);
      expect(PushException.classify(Exception('offline')), PushError.network);
    });

    test("P0001 'registered' (§10.6), and only that message", () {
      expect(
        PushException.classify(const PostgrestException(message: 'registered', code: 'P0001')),
        PushError.registered,
      );
      expect(
        PushException.classify(const PostgrestException(message: 'other', code: 'P0001')),
        PushError.network,
      );
    });
  });

  group('registered members (§10.6)', () {
    test('muting a registered event: stays on, local mute forgotten', () async {
      SharedPreferences.setMockInitialValues({'push_muted_events': ['e1']});
      api.eventErrors.add(PushError.registered);
      expect(
        await sync.setEvent('e1', enabled: false, payload: payload),
        MuteOutcome.registered,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('push_muted_events'), isEmpty);
    });

    test('a new identity drops registered events instead of retrying them', () async {
      SharedPreferences.setMockInitialValues({'push_muted_events': ['e1', 'e2']});
      api.registerErrors.add(PushError.wrongSecret);
      api.eventErrors.add(PushError.registered);
      await sync.register(payload);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('push_muted_events'), ['e2']);
    });

    test('forgetMute after registering', () async {
      SharedPreferences.setMockInitialValues({'push_muted_events': ['e1', 'e2']});
      await sync.forgetMute('e1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('push_muted_events'), ['e2']);
    });

    test('force registers again with an unchanged payload (sign-in, sign-out)', () async {
      await sync.register(payload);
      await sync.register(payload);
      expect(api.calls, ['register']);
      await sync.register(payload, force: true);
      expect(api.calls, ['register', 'register']);
    });
  });
}
