import AVFoundation
import AudioToolbox
import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Shared with the PrayerWidget extension (both targets carry the App
  /// Group entitlement). Keys must match ios/PrayerWidget/PrayerWidget.swift.
  private static let appGroup = "group.ca.papemosque.app"
  private static let widgetDataKey = "prayer_widget_data"

  private var widgetChannel: FlutterMethodChannel?
  private var soundChannel: FlutterMethodChannel?
  private var siriChannel: FlutterMethodChannel?
  private var siriObserver: NSObjectProtocol?
  private var previewPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show reminders while the app is open.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// UIScene: the engine starts when the scene loads the storyboard, after the
  /// launch callbacks above. A background launch that gets no scene (a Siri
  /// question or a silent push may not) has no engine and doesn't get here. iOS can drop the scene of a
  /// suspended app and connect a new one later, so this can run again.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    registerPrayerWidgetBridge(messenger)
    registerNotificationSoundBridge(messenger)
    registerSiriBridge(messenger)
    #if DEBUG
    // tool/check_simulator_launch.sh looks for this line.
    NSLog("PapeScene: Flutter engine ready")
    #endif
  }

  /// lib/core/prayer_widget_sync.dart sends the widget's JSON here; it is
  /// stored in the App Group and every widget timeline is rebuilt from it.
  private func registerPrayerWidgetBridge(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "ca.papemosque.app/prayer_widget",
      binaryMessenger: messenger
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

  /// lib/core/siri_bridge.dart: the data the Siri shortcuts read (see
  /// ios/Runner/Siri/SiriData.swift), whether this launch is in the background
  /// (lib/core/launch_gate.dart), and a donate shortcut waiting to be opened.
  private func registerSiriBridge(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "ca.papemosque.app/siri",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "update":
        guard let args = call.arguments as? [String: String],
              let key = args["key"], let json = args["json"],
              [SiriStoreKey.prayers, SiriStoreKey.events, SiriStoreKey.mosque].contains(key)
        else {
          result(FlutterError(code: "bad_args", message: nil, details: nil))
          return
        }
        UserDefaults(suiteName: SiriStoreKey.appGroup)?.set(json, forKey: key)
        result(nil)
      case "isInBackground":
        result(UIApplication.shared.applicationState == .background)
      case "takeAction":
        result(SiriSession.pendingAction)
        SiriSession.pendingAction = nil
      case "hadAction":
        result(SiriSession.hadAction)
      case "languageNote":
        result(UserDefaults(suiteName: SiriStoreKey.appGroup)?.string(forKey: SiriStoreKey.lastLanguage))
      case "isTestBuild":
        result(AppDelegate.isTestBuild)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    siriChannel = channel
    if let old = siriObserver { NotificationCenter.default.removeObserver(old) }
    siriObserver = NotificationCenter.default.addObserver(
      forName: SiriSession.actionNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.siriChannel?.invokeMethod("action", arguments: nil)
    }
  }

  /// A TestFlight install (or one run from Xcode): only there does About this
  /// app show test lines. The App Store ships the very binary TestFlight had,
  /// so no build flag can tell them apart; the receipt can. An App Store
  /// install's receipt is "receipt", TestFlight's is "sandboxReceipt".
  static var isTestBuild: Bool {
    #if DEBUG
    return true
    #else
    return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    #endif
  }

  /// The athan recording, if this build carries it: ios/Runner/Sounds/athan.caf
  /// in the Runner target's Copy Bundle Resources. Notifications name the
  /// same file (lib/core/notification_sounds.dart).
  private static var athanURL: URL? {
    Bundle.main.url(forResource: "athan", withExtension: "caf")
  }

  /// lib/core/notification_sounds.dart asks here whether the athan is
  /// bundled, and plays the sound picker's previews.
  private func registerNotificationSoundBridge(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "ca.papemosque.app/notification_sound",
      binaryMessenger: messenger
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
