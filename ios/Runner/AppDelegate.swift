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

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show reminders while the app is open.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    registerPrayerWidgetBridge()
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
}
