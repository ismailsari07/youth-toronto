import Foundation

// What the Siri shortcuts read: three JSON documents the Flutter app writes
// into the App Group (lib/core/siri_data_sync.dart). No network here, ever.
//
// Flutter writes each time as an instant AND as display text, using the same
// code as the reminders. This side compares instants and repeats the text; it
// never parses or calculates a clock time.

enum SiriStoreKey {
  static let appGroup = "group.ca.papemosque.app"
  static let prayers = "siri_prayers"
  static let events = "siri_events"
  static let mosque = "siri_mosque"
  static let version = 1
}

/// The order of a complete day, as prayer_cache names them.
enum PrayerKey: String, Codable, CaseIterable {
  case fajr = "Fajr"
  case sunrise = "Sunrise"
  case dhuhr = "Dhuhr"
  case asr = "Asr"
  case maghrib = "Maghrib"
  case isha = "Isha"
}

struct SiriPrayer: Codable, Equatable {
  let key: PrayerKey
  let at: Double
  let time: String
  let iqamahAt: Double?
  let iqamah: String?

  var date: Date { Date(timeIntervalSince1970: at) }
}

struct SiriJumuah: Codable, Equatable {
  let at: Double
  let time: String

  var date: Date { Date(timeIntervalSince1970: at) }
}

struct SiriDay: Codable, Equatable {
  let date: String // yyyy-MM-dd, Toronto
  let prayers: [SiriPrayer]
  let jumuah: SiriJumuah? // only on a Friday, from that Friday's own row

  /// All six times, in order and strictly increasing. Anything less counts
  /// as no data: a partial day is never answered from.
  var isComplete: Bool {
    guard prayers.map(\.key) == PrayerKey.allCases else { return false }
    return zip(prayers, prayers.dropFirst()).allSatisfy { $0.at < $1.at }
  }

  func prayer(_ key: PrayerKey) -> SiriPrayer? {
    prayers.first { $0.key == key }
  }
}

struct SiriEid: Codable, Equatable {
  let which: String // fitr or adha
  let date: String // yyyy-MM-dd, Toronto
  let firstAt: Double
  let first: String
  let secondAt: Double?
  let second: String?

  /// When it stops being "upcoming": after the last prayer of the day.
  var endsAt: Date { Date(timeIntervalSince1970: secondAt ?? firstAt) }
}

struct SiriPrayersDoc: Codable, Equatable {
  let version: Int
  let writtenAt: Double
  let days: [SiriDay]
  let eid: [SiriEid]
}

struct SiriEvent: Codable, Equatable {
  let id: String
  let title: String
  let day: String // yyyy-MM-dd, Toronto
  let startsAt: Double
  let when: [String: String] // language -> the app's schedule line
  let next: [String: String]? // language -> "next: ...", recurring events only
}

struct SiriEventsDoc: Codable, Equatable {
  let version: Int
  let fetchedAt: Double // the last successful fetch
  let items: [SiriEvent]
}

struct SiriMosqueDoc: Codable, Equatable {
  let version: Int
  let name: String
  let phone: String?
  let tel: String?
  let address: String?
  let lat: Double?
  let lng: Double?
  let eventsEnabled: Bool
}

enum SiriStore {
  private static func decode<T: Decodable>(_ type: T.Type, key: String, version: (T) -> Int) -> T? {
    guard let json = UserDefaults(suiteName: SiriStoreKey.appGroup)?.string(forKey: key) else {
      return nil
    }
    return decode(type, json: json, version: version)
  }

  /// A document of an unknown version, or one that can't be read, is missing.
  static func decode<T: Decodable>(_ type: T.Type, json: String, version: (T) -> Int) -> T? {
    guard let bytes = json.data(using: .utf8),
          let doc = try? JSONDecoder().decode(type, from: bytes),
          version(doc) == SiriStoreKey.version
    else { return nil }
    return doc
  }

  static var prayers: SiriPrayersDoc? {
    decode(SiriPrayersDoc.self, key: SiriStoreKey.prayers) { $0.version }
  }

  static var events: SiriEventsDoc? {
    decode(SiriEventsDoc.self, key: SiriStoreKey.events) { $0.version }
  }

  static var mosque: SiriMosqueDoc? {
    decode(SiriMosqueDoc.self, key: SiriStoreKey.mosque) { $0.version }
  }
}
