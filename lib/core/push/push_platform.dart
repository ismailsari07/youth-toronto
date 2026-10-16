import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'push_prompt.dart';

/// The device side of push: iOS permission, the FCM token and taps. Behind
/// an interface so Android, Linux (screenshots) and tests run without
/// Firebase.
abstract class PushPlatform {
  Future<PushPermission> status();

  /// Shows the iOS prompt if iOS hasn't asked yet; returns the answer.
  Future<PushPermission> request();

  /// The FCM token, once iOS has given the app its APNs token; null if
  /// that doesn't happen within a few seconds.
  Future<String?> token();

  Stream<String> get tokenRefresh;

  /// Data of notifications tapped while the app was running or in the
  /// background (the foreground banner included).
  Stream<Map<String, dynamic>> get opened;

  /// Data of the notification that launched the app, if one did.
  Future<Map<String, dynamic>?> initialOpen();

  /// This app's page in the iOS Settings app.
  Future<void> openSystemSettings();

  /// Starts Firebase on iOS; anywhere else (or if it fails) push is off.
  /// Android has no Firebase configuration yet, on purpose.
  static Future<PushPlatform> start() async {
    if (kIsWeb || !Platform.isIOS) return const UnsupportedPushPlatform();
    try {
      await Firebase.initializeApp();
      // The system banner while the app is open; tapping it arrives on
      // [opened] like any other tap. No badge anywhere.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        sound: true,
        badge: false,
      );
      return FirebasePushPlatform();
    } catch (e) {
      debugPrint('Push: Firebase did not start');
      return const UnsupportedPushPlatform();
    }
  }
}

class FirebasePushPlatform implements PushPlatform {
  final _messaging = FirebaseMessaging.instance;

  static PushPermission _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          PushPermission.authorized,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently =>
          PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  @override
  Future<PushPermission> status() async =>
      _map((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> request() async => _map((await _messaging
          .requestPermission(alert: true, badge: false, sound: true))
      .authorizationStatus);

  @override
  Future<String?> token() async {
    // getToken() fails on iOS until the APNs token has arrived.
    for (final seconds in const [0, 1, 2, 4, 8]) {
      if (seconds > 0) await Future<void>.delayed(Duration(seconds: seconds));
      try {
        if (await _messaging.getAPNSToken() != null) {
          return await _messaging.getToken();
        }
      } catch (_) {
        /* not yet */
      }
    }
    debugPrint('Push: no APNs token yet');
    return null;
  }

  @override
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);

  @override
  Future<Map<String, dynamic>?> initialOpen() async =>
      (await _messaging.getInitialMessage())?.data;

  @override
  Future<void> openSystemSettings() async {
    try {
      await launchUrl(Uri.parse('app-settings:'));
    } catch (_) {
      /* Settings didn't open; nothing else to do */
    }
  }
}

class UnsupportedPushPlatform implements PushPlatform {
  const UnsupportedPushPlatform();

  @override
  Future<PushPermission> status() async => PushPermission.unsupported;

  @override
  Future<PushPermission> request() async => PushPermission.unsupported;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get opened => const Stream.empty();

  @override
  Future<Map<String, dynamic>?> initialOpen() async => null;

  @override
  Future<void> openSystemSettings() async {}
}
