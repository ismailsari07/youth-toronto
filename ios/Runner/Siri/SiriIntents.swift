import AppIntents
import Foundation
import SwiftUI
import UIKit

// The ten App Shortcuts' intents. They live in the main app because Apple
// requires that for App Shortcuts, and only there can an intent open the app.
// So a question launches the app in the background: lib/core/launch_gate.dart
// keeps that launch from doing anything a member would notice.

/// What this session owes the Flutter side (see AppDelegate's Siri bridge).
enum SiriSession {
  /// A donate shortcut waiting for Flutter to open the sheet.
  static var pendingAction: String?
  /// A shortcut brought the app forward: no pre-prompt over it this session.
  static var hadAction = false
  static let actionNotification = Notification.Name("ca.papemosque.app.siriAction")

  static func donate() {
    hadAction = true
    pendingAction = "donate"
    NotificationCenter.default.post(name: actionNotification, object: nil)
  }
}

@available(iOS 16.0, *)
enum PrayerChoice: String, AppEnum {
  case fajr, dhuhr, asr, maghrib, isha

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Prayer")

  // Titles are per language in Localizable.strings (Isha is "Yatsı" in Turkish,
  // "Icha" in French). No synonyms: that initializer needs iOS 17, and this
  // table is read at build time, so it can't vary by iOS version.
  static var caseDisplayRepresentations: [PrayerChoice: DisplayRepresentation] = [
    .fajr: "Fajr",
    .dhuhr: "Dhuhr",
    .asr: "Asr",
    .maghrib: "Maghrib",
    .isha: "Isha",
  ]

  var key: PrayerKey {
    switch self {
    case .fajr: return .fajr
    case .dhuhr: return .dhuhr
    case .asr: return .asr
    case .maghrib: return .maghrib
    case .isha: return .isha
    }
  }
}

// MARK: - Spoken with a snippet; the app stays closed

@available(iOS 16.0, *)
struct NextPrayerIntent: AppIntent {
  static var title: LocalizedStringResource = "Next prayer"
  static var description = IntentDescription("The next prayer at the mosque, with the time left.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().nextPrayer()
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

@available(iOS 16.0, *)
struct PrayerTimeIntent: AppIntent {
  static var title: LocalizedStringResource = "Prayer time"
  static var description = IntentDescription("Today's athan and iqamah for one prayer.")
  static var openAppWhenRun = false

  @Parameter(title: "Prayer", requestValueDialog: IntentDialog("Which prayer?"))
  var prayer: PrayerChoice

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().prayerTime(prayer.key)
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

@available(iOS 16.0, *)
struct TodayTimesIntent: AppIntent {
  static var title: LocalizedStringResource = "Today's prayer times"
  static var description = IntentDescription("All of today's prayer times at the mosque.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().todayTimes()
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

@available(iOS 16.0, *)
struct TimeLeftIntent: AppIntent {
  static var title: LocalizedStringResource = "Time left for a prayer"
  static var description = IntentDescription("How long a prayer's time lasts. Without a prayer, the current one.")
  static var openAppWhenRun = false

  @Parameter(title: "Prayer")
  var prayer: PrayerChoice?

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().timeLeft(prayer?.key)
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

@available(iOS 16.0, *)
struct JumuahIntent: AppIntent {
  static var title: LocalizedStringResource = "Jumu'ah time"
  static var description = IntentDescription("This Friday's prayer at the mosque.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().jumuah()
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

@available(iOS 16.0, *)
struct EventsIntent: AppIntent {
  static var title: LocalizedStringResource = "Upcoming events"
  static var description = IntentDescription("The mosque's next events.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().upcomingEvents()
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

@available(iOS 16.0, *)
struct EidIntent: AppIntent {
  static var title: LocalizedStringResource = "Eid prayer"
  static var description = IntentDescription("The next Eid prayer at the mosque.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let answer = SiriEngine.current().eid()
    return .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card))
  }
}

// MARK: - Opens the app

/// Apple rule: donations happen outside the app. This only opens the sheet,
/// whose rows go to the website in Safari.
@available(iOS 16.0, *)
struct DonateIntent: AppIntent {
  static var title: LocalizedStringResource = "Donate"
  static var description = IntentDescription("Opens the donation options.")
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    SiriSession.donate()
    return .result()
  }
}

// MARK: - Confirmed by Siri, then handed to Maps or Phone

/// Nothing to open: Siri says why.
@available(iOS 16.0, *)
struct SiriRefusal: Error, CustomLocalizedStringResourceConvertible {
  let message: String

  var localizedStringResource: LocalizedStringResource {
    LocalizedStringResource(stringLiteral: message)
  }
}

/// A background intent can't open another app, so this brings ours forward
/// for a moment and opens the URL from there. Internal: not offered as an
/// action of its own in the Shortcuts app.
@available(iOS 16.0, *)
struct HandoffIntent: AppIntent {
  static var title: LocalizedStringResource = "Open"
  static var openAppWhenRun = true
  static var isDiscoverable: Bool { false }

  @Parameter(title: "Link")
  var url: URL

  init() {}

  init(url: URL) {
    self.url = url
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    SiriSession.hadAction = true
    await UIApplication.shared.open(url)
    return .result()
  }
}

@available(iOS 16.0, *)
struct DirectionsIntent: AppIntent {
  static var title: LocalizedStringResource = "Directions to the mosque"
  static var description = IntentDescription("Opens directions to the mosque in Maps.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & OpensIntent & ProvidesDialog {
    let engine = SiriEngine.current()
    let answer = engine.directions()
    guard let url = engine.directionsURL else {
      throw SiriRefusal(message: answer.spoken)
    }
    try await requestConfirmation(
      result: .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card)),
      confirmationActionName: .go
    )
    SiriSession.hadAction = true
    return .result(opensIntent: HandoffIntent(url: url), dialog: IntentDialog(stringLiteral: engine.opening))
  }
}

@available(iOS 16.0, *)
struct CallIntent: AppIntent {
  static var title: LocalizedStringResource = "Call the mosque"
  static var description = IntentDescription("Calls the mosque.")
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & OpensIntent & ProvidesDialog {
    let engine = SiriEngine.current()
    let answer = engine.call()
    guard let url = engine.callURL else {
      throw SiriRefusal(message: answer.spoken)
    }
    try await requestConfirmation(
      result: .result(dialog: IntentDialog(stringLiteral: answer.spoken), view: SiriCardView(card: answer.card)),
      confirmationActionName: .go
    )
    SiriSession.hadAction = true
    return .result(opensIntent: HandoffIntent(url: url), dialog: IntentDialog(stringLiteral: engine.opening))
  }
}
