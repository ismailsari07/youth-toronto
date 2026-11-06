import AppIntents
import Flutter
import UIKit
import XCTest

@testable import Runner

/// Runs the shortcuts' perform() inside the real app process, with the app's
/// entitlements and App Group, the way Siri does. Build 26 of 1.4.0 crashed on
/// every question in INPreferences.siriLanguageCode() because the app lacked
/// the Siri entitlement: these would have aborted the same way. They can't
/// reproduce a background launch with no scene (no tool drives Siri on a
/// simulator); perform() doesn't touch a scene or Flutter, so the process is
/// what matters.
@available(iOS 16.0, *)
final class RunnerTests: XCTestCase {

  func testSiriLanguageCanBeRead() {
    _ = SiriLanguage.current
  }

  func testReadOnlyIntentsAnswerWithoutAScene() async throws {
    _ = try await NextPrayerIntent().perform()
    _ = try await TodayTimesIntent().perform()
    _ = try await JumuahIntent().perform()
    _ = try await EventsIntent().perform()
    _ = try await EidIntent().perform()

    var time = PrayerTimeIntent()
    time.prayer = .fajr
    _ = try await time.perform()

    var left = TimeLeftIntent()
    _ = try await left.perform()
    left.prayer = .asr
    _ = try await left.perform()
  }

  /// Directions and Call ask Siri to confirm, which needs Siri itself; this
  /// runs everything they do before that.
  func testDirectionsAndCallPrepareTheirAnswers() {
    let engine = SiriEngine.current()
    _ = engine.directions()
    _ = engine.call()
    _ = engine.directionsURL
    _ = engine.callURL
  }
}
