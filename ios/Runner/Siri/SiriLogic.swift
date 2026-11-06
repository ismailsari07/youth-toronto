import Foundation

// The time rules behind the shortcuts. Everything takes `now`, so it can be
// tested, and everything is on the mosque's calendar, whatever the phone's
// time zone. Durations are differences between instants, so a 23- or 25-hour
// DST day needs no special handling.
//
// The owner's hard rule: never state a wrong or estimated time. Whenever the
// rows needed for an answer aren't there, the answer is `.notCurrent`.

enum MosqueCalendar {
  static let timeZone = TimeZone(identifier: "America/Toronto")!

  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
  }

  /// `yyyy-MM-dd` on the mosque's calendar.
  static func dayKey(_ date: Date) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
  }

  /// The day [offset] calendar days from [date] (not 24-hour steps).
  static func dayKey(_ date: Date, plusDays offset: Int) -> String {
    let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    return dayKey(calendar.date(byAdding: .day, value: offset, to: noon) ?? noon)
  }

  /// 1 = Sunday ... 6 = Friday.
  static func weekday(_ date: Date) -> Int {
    calendar.component(.weekday, from: date)
  }

  /// A `yyyy-MM-dd` key as a date at noon there, for formatting.
  static func date(fromKey key: String) -> Date? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return calendar.date(
      from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)
    )
  }
}

/// A prayer's window, as the time-left shortcut reports it.
enum WindowState: Equatable {
  /// Rows needed for the answer are missing.
  case notCurrent
  /// In the window. [end] is nil only for Isha without tomorrow's row: what
  /// is known is said, nothing is estimated.
  case active(PrayerKey, start: Date?, end: SiriPrayer?)
  case notStarted(PrayerKey, SiriPrayer)
  case over(PrayerKey)
  /// Between sunrise and Dhuhr, with no prayer named.
  case noPrayerNow(next: SiriPrayer)
}

struct NextPrayer: Equatable {
  let prayer: SiriPrayer
  let isTomorrow: Bool
}

struct SiriSchedule {
  let doc: SiriPrayersDoc?
  let now: Date

  private func completeDay(plusDays offset: Int) -> SiriDay? {
    let key = MosqueCalendar.dayKey(now, plusDays: offset)
    guard let day = doc?.days.first(where: { $0.date == key }), day.isComplete else {
      return nil
    }
    return day
  }

  /// Today's row, whole, or nothing. Every prayer answer starts here.
  var today: SiriDay? { completeDay(plusDays: 0) }
  var tomorrow: SiriDay? { completeDay(plusDays: 1) }
  var yesterday: SiriDay? { completeDay(plusDays: -1) }

  /// The first of the five prayers after now. Sunrise is listed but never
  /// counted down to, as in the app and the widget.
  func nextPrayer() -> NextPrayer? {
    guard let today = today else { return nil }
    if let prayer = today.prayers.first(where: { $0.key != .sunrise && $0.date > now }) {
      return NextPrayer(prayer: prayer, isTomorrow: false)
    }
    guard let fajr = tomorrow?.prayer(.fajr) else { return nil }
    return NextPrayer(prayer: fajr, isTomorrow: true)
  }

  /// The row to highlight in today's table: the last time that has come,
  /// Sunrise included, as the app does.
  func highlighted(in day: SiriDay) -> PrayerKey? {
    day.prayers.last(where: { $0.date <= now })?.key
  }

  /// The window [key] is about, or the current one when nil.
  func window(_ key: PrayerKey?) -> WindowState {
    guard let today = today,
          let fajr = today.prayer(.fajr),
          let sunrise = today.prayer(.sunrise),
          let dhuhr = today.prayer(.dhuhr),
          let asr = today.prayer(.asr),
          let maghrib = today.prayer(.maghrib),
          let isha = today.prayer(.isha)
    else { return .notCurrent }

    // Where now falls. Before today's Fajr it is still last night's Isha,
    // which ends at today's Fajr.
    let current: WindowState
    if now < fajr.date {
      current = .active(.isha, start: yesterday?.prayer(.isha)?.date, end: fajr)
    } else if now < sunrise.date {
      current = .active(.fajr, start: fajr.date, end: sunrise)
    } else if now < dhuhr.date {
      current = .noPrayerNow(next: dhuhr)
    } else if now < asr.date {
      current = .active(.dhuhr, start: dhuhr.date, end: asr)
    } else if now < maghrib.date {
      current = .active(.asr, start: asr.date, end: maghrib)
    } else if now < isha.date {
      current = .active(.maghrib, start: maghrib.date, end: isha)
    } else {
      current = .active(.isha, start: isha.date, end: tomorrow?.prayer(.fajr))
    }

    guard let key = key else { return current }
    if case .active(key, _, _) = current { return current }
    guard let asked = today.prayer(key) else { return .notCurrent }
    return asked.date > now ? .notStarted(key, asked) : .over(key)
  }

  /// This Friday's prayer: today's if it is Friday and hasn't passed, else
  /// the coming Friday's. Each Friday answers from its own row only.
  func jumuah() -> (day: SiriDay, jumuah: SiriJumuah, isToday: Bool)? {
    guard today != nil else { return nil }
    let friday = 6
    let weekday = MosqueCalendar.weekday(now)
    var offset = (friday - weekday + 7) % 7
    if offset == 0 {
      if let time = today?.jumuah, time.date > now, let day = today {
        return (day, time, true)
      }
      offset = 7
    }
    guard let day = completeDay(plusDays: offset), let time = day.jumuah else { return nil }
    return (day, time, false)
  }

  /// The soonest Eid whose last prayer hasn't passed.
  func upcomingEid() -> SiriEid? {
    let todayKey = MosqueCalendar.dayKey(now)
    return doc?.eid
      .filter { $0.date >= todayKey && $0.endsAt > now }
      .sorted { $0.date < $1.date }
      .first
  }
}

enum SiriEvents {
  static let maxAge: TimeInterval = 7 * 24 * 3600

  /// nil: never fetched, or the cache is too old to answer from.
  static func upcoming(_ doc: SiriEventsDoc?, now: Date) -> [SiriEvent]? {
    guard let doc = doc,
          now.timeIntervalSince1970 - doc.fetchedAt <= maxAge
    else { return nil }
    let today = MosqueCalendar.dayKey(now)
    // A session stays listed all day, as in the app, and each event once, at
    // its next session. The cache holds later sessions of a recurring event
    // so it stays right for days without the app opening.
    var seen = Set<String>()
    return doc.items
      .filter { $0.day >= today }
      .sorted { $0.startsAt < $1.startsAt }
      .filter { seen.insert($0.id).inserted }
  }
}

/// The hours and minutes left, rounded down, so it is never overstated.
struct TimeLeft: Equatable {
  let hours: Int
  let minutes: Int

  init(from now: Date, to end: Date) {
    let total = max(0, Int(end.timeIntervalSince(now))) / 60
    hours = total / 60
    minutes = total % 60
  }

  var isUnderAMinute: Bool { hours == 0 && minutes == 0 }
}
