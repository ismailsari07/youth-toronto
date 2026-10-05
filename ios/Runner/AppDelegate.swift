import AVFoundation
import AudioToolbox
import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Shared with the PrayerWidget extension (both targets carry the App
  /// Group entitlement). Keys must match ios/PrayerWidget/PrayerWidget.swift.
  private static let appGroup = "group.ca.papemosque.app"
  private static let widgetDataKey = "prayer_widget_data"

  private var widgetChannel: FlutterMethodChannel?
  private var soundChannel: FlutterMethodChannel?
  private var previewPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show reminders while the app is open.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    registerPrayerWidgetBridge()
    registerNotificationSoundBridge()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// lib/core/prayer_widget_sync.dart sends the widget's JSON here; it is
  /// stored in the App Group and every widget timeline is rebuilt from it.
  private func registerPrayerWidgetBridge() {
    guard let registrar = self.registrar(forPlugin: "PrayerWidgetBridge") else { return }
    let channel = FlutterMethodChannel(
      name: "ca.papemosque.app/prayer_widget",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "update", let json = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      UserDefaults(suiteName: AppDelegate.appGroup)?.set(json, forKey: AppDelegate.widgetDataKey)
      WidgetCenter.shared.reloadAllTimelines()
      result(nil)
    }
    widgetChannel = channel
  }

  /// The athan recording, if this build carries it: ios/Runner/Sounds/athan.caf
  /// in the Runner target's Copy Bundle Resources. Notifications name the
  /// same file (lib/core/notification_sounds.dart).
  private static var athanURL: URL? {
    Bundle.main.url(forResource: "athan", withExtension: "caf")
  }

  /// lib/core/notification_sounds.dart asks here whether the athan is
  /// bundled, and plays the sound picker's previews.
  private func registerNotificationSoundBridge() {
    guard let registrar = self.registrar(forPlugin: "NotificationSoundBridge") else { return }
    let channel = FlutterMethodChannel(
      name: "ca.papemosque.app/notification_sound",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "athanBundled":
        result(AppDelegate.athanURL != nil)
      case "preview":
        result(self?.playPreview(call.arguments as? String ?? "standard"))
      case "stopPreview":
        self?.stopPreview()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    soundChannel = channel
  }

  /// Plays one sound choice and returns its length in seconds. Apps can't
  /// play the member's own alert tone, so "standard" plays the tri-tone.
  private func playPreview(_ sound: String) -> Double {
    stopPreview()
    if sound == "athan", let url = AppDelegate.athanURL,
       let player = try? AVAudioPlayer(contentsOf: url) {
      // .playback: heard even with the ring switch on silent, since the
      // member asked to hear it.
      try? AVAudioSession.sharedInstance().setCategory(.playback)
      try? AVAudioSession.sharedInstance().setActive(true)
      player.play()
      previewPlayer = player
      return player.duration
    }
    AudioServicesPlaySystemSound(1007)
    return 1.0
  }

  private func stopPreview() {
    guard let player = previewPlayer else { return }
    player.stop()
    previewPlayer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
