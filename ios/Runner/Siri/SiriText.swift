import Foundation
#if canImport(Intents)
import Intents
#endif

// The sentences Siri speaks and the cards the snippets show, in English,
// Turkish and Canadian French, with the app's terms
// (test/siri/siri_terms_test.dart compares them with the ARB files).

enum SiriLanguage: String {
  case en, tr, fr

  /// The language Siri speaks, because the answer is said in Siri's voice. It
  /// can differ from the device's, which is all Bundle.main.preferredLocalizations
  /// knows: that gave English sentences in a Turkish voice.
  ///
  /// siriLanguageCode() needs `com.apple.developer.siri` in Runner.entitlements
  /// (and SiriKit on the App ID). Without it iOS throws an Objective-C exception
  /// that Swift can't catch, so every intent crashed (TestFlight 1.4.0 build 26).
  /// test/siri/siri_entitlement_test.dart keeps the two together.
  static var current: SiriLanguage {
    #if canImport(Intents)
    let siri: String? = INPreferences.siriLanguageCode()
    #else
    let siri: String? = nil
    #endif
    return resolve(siri: siri, device: Bundle.main.preferredLocalizations.first)
  }

  /// Siri's language if we have it, else the device's, else English. Codes come
  /// as "tr-TR", "fr_CA" or "en".
  static func resolve(siri: String?, device: String?) -> SiriLanguage {
    for code in [siri, device] {
      guard let code = code else { continue }
      if let language = SiriLanguage(rawValue: String(code.prefix(2)).lowercased()) {
        return language
      }
    }
    return .en
  }
}

/// What a snippet shows. Plain values, so it can be tested without SwiftUI.
enum SiriCard: Equatable {
  struct Row: Equatable {
    let name: String
    let time: String
    let iqamah: String?
    let highlighted: Bool
  }

  struct Item: Hashable {
    let title: String
    let line: String
    let next: String?
  }

  case message(String)
  case prayer(eyebrow: String, name: String, big: String?, lines: [String])
  case table(title: String, rows: [Row], footer: String?)
  case window(name: String, status: String, detail: String?, progress: Double?)
  case events(title: String, items: [Item])
  case contact(title: String, detail: String)
}

struct SiriAnswer: Equatable {
  let spoken: String
  let card: SiriCard

  init(_ spoken: String, card: SiriCard? = nil) {
    self.spoken = spoken
    self.card = card ?? .message(spoken)
  }
}

/// Prayer names and phrases. The first three tables mirror the `prayer` key
/// of app_{en,tr,fr}.arb.
enum SiriTerms {
  static let names: [SiriLanguage: [PrayerKey: String]] = [
    .en: [.fajr: "Fajr", .sunrise: "Sunrise", .dhuhr: "Dhuhr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"],
    .tr: [.fajr: "İmsak", .sunrise: "Güneş", .dhuhr: "Öğle", .asr: "İkindi", .maghrib: "Akşam", .isha: "Yatsı"],
    .fr: [.fajr: "Fajr", .sunrise: "Lever du soleil", .dhuhr: "Dhohr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Icha"],
  ]

  static let athan: [SiriLanguage: String] = [.en: "Athan", .tr: "Ezan", .fr: "Adhan"]
  static let iqamah: [SiriLanguage: String] = [.en: "Iqamah", .tr: "Cemaat", .fr: "Iqama"]
  static let jumuah: [SiriLanguage: String] = [
    .en: "Jumu'ah", .tr: "Cuma namazı", .fr: "Prière du vendredi (Joumou'a)",
  ]
  static let eidFitr: [SiriLanguage: String] = [
    .en: "Eid al-Fitr", .tr: "Ramazan Bayramı", .fr: "Aïd al-Fitr",
  ]
  static let eidAdha: [SiriLanguage: String] = [
    .en: "Eid al-Adha", .tr: "Kurban Bayramı", .fr: "Aïd al-Adha",
  ]

  /// Turkish, mid-sentence: İ and I don't survive `lowercased()`.
  static let trLower: [PrayerKey: String] = [
    .fajr: "imsak", .sunrise: "güneş", .dhuhr: "öğle", .asr: "ikindi", .maghrib: "akşam", .isha: "yatsı",
  ]

  /// French, with the article: "du Dhohr", "de l'Asr".
  static let frOf: [PrayerKey: String] = [
    .fajr: "du Fajr", .sunrise: "du lever du soleil", .dhuhr: "du Dhohr", .asr: "de l'Asr",
    .maghrib: "du Maghrib", .isha: "de l'Icha",
  ]

  /// French, after a verb: "est le Dhohr", "est l'Asr".
  static let frIs: [PrayerKey: String] = [
    .fajr: "le Fajr", .sunrise: "le lever du soleil", .dhuhr: "le Dhohr", .asr: "l'Asr",
    .maghrib: "le Maghrib", .isha: "l'Icha",
  ]

  /// French subject: "Le Dhohr", "L'Asr".
  static let frThe: [PrayerKey: String] = [
    .fajr: "Le Fajr", .sunrise: "Le lever du soleil", .dhuhr: "Le Dhohr", .asr: "L'Asr",
    .maghrib: "Le Maghrib", .isha: "L'Icha",
  ]
}

enum TurkishTime {
  /// "13:07" -> "13:07'de", "16:30" -> "16:30'da": the locative follows the last
  /// number said. Only used inside sentences; cards keep the plain time.
  static func at(_ time: String) -> String {
    let parts = time.split(separator: ":").compactMap { Int($0) }
    guard parts.count == 2 else { return time }
    return "\(time)'\(suffix(hour: parts[0], minute: parts[1]))"
  }

  /// On the hour only the hour is said: "on altı", "yirmi", "sıfır".
  static func suffix(hour: Int, minute: Int) -> String {
    suffix(saying: minute == 0 ? hour : minute)
  }

  private static func suffix(saying number: Int) -> String {
    let lastDigit: [Int: String] = [
      1: "de", 2: "de", 3: "te", 4: "te", 5: "te", 6: "da", 7: "de", 8: "de", 9: "da",
    ]
    if let suffix = lastDigit[number % 10] { return suffix }
    return [0: "da", 10: "da", 20: "de", 30: "da", 40: "ta", 50: "de"][number] ?? "de"
  }
}

struct SiriEngine {
  let prayers: SiriPrayersDoc?
  let events: SiriEventsDoc?
  let mosque: SiriMosqueDoc?
  let now: Date
  let language: SiriLanguage

  private var schedule: SiriSchedule { SiriSchedule(doc: prayers, now: now) }

  private func name(_ key: PrayerKey) -> String { SiriTerms.names[language]?[key] ?? key.rawValue }
  private var athan: String { SiriTerms.athan[language] ?? "Athan" }
  private var iqamah: String { SiriTerms.iqamah[language] ?? "Iqamah" }
  private func clock(_ time: SiriClock) -> String { time.text(language) }
  private var jumuahName: String { SiriTerms.jumuah[language] ?? "Jumu'ah" }

  private func pick(_ en: String, _ tr: String, _ fr: String) -> String {
    switch language {
    case .en: return en
    case .tr: return tr
    case .fr: return fr
    }
  }

  // MARK: Refusals

  private var prayersNotCurrent: SiriAnswer {
    SiriAnswer(pick(
      "Prayer times aren't up to date. Please open the app.",
      "Vakitler güncel değil, lütfen uygulamayı açın.",
      "Les horaires de prière ne sont pas à jour. Veuillez ouvrir l'application."
    ))
  }

  private var eventsNotCurrent: SiriAnswer {
    SiriAnswer(pick(
      "Events aren't up to date. Please open the app.",
      "Etkinlikler güncel değil, lütfen uygulamayı açın.",
      "Les événements ne sont pas à jour. Veuillez ouvrir l'application."
    ))
  }

  private var mosqueNotCurrent: SiriAnswer {
    SiriAnswer(pick(
      "The mosque's details aren't available. Please open the app.",
      "Cami bilgileri güncel değil, lütfen uygulamayı açın.",
      "Les coordonnées de la mosquée ne sont pas disponibles. Veuillez ouvrir l'application."
    ))
  }

  // MARK: Pieces

  private func left(_ value: TimeLeft) -> String {
    if value.isUnderAMinute {
      return pick("less than a minute", "1 dakikadan az", "moins d'une minute")
    }
    var parts: [String] = []
    if value.hours > 0 {
      parts.append(pick(
        "\(value.hours) \(value.hours == 1 ? "hour" : "hours")",
        "\(value.hours) saat",
        "\(value.hours) \(value.hours == 1 ? "heure" : "heures")"
      ))
    }
    if value.minutes > 0 {
      parts.append(pick(
        "\(value.minutes) \(value.minutes == 1 ? "minute" : "minutes")",
        "\(value.minutes) dakika",
        "\(value.minutes) \(value.minutes == 1 ? "minute" : "minutes")"
      ))
    }
    return parts.joined(separator: " ")
  }

  private func timesLine(_ prayer: SiriPrayer) -> [String] {
    var lines = ["\(athan) \(clock(prayer.time))"]
    if let time = prayer.iqamah { lines.append("\(iqamah) \(clock(time))") }
    return lines
  }

  private func timesSpoken(_ prayer: SiriPrayer) -> String {
    timesLine(prayer).joined(separator: ", ")
  }

  /// Friday's Dhuhr: the row keeps its own times, with Jumu'ah said too.
  private func fridayLine(_ prayer: SiriPrayer, in day: SiriDay?) -> String? {
    guard prayer.key == .dhuhr, let time = day?.jumuah else { return nil }
    return "\(jumuahName) \(clock(time.time))"
  }

  /// A date in the language: "6 Kasım Cuma", "Friday, November 6",
  /// "vendredi 6 novembre". On the mosque's calendar.
  func longDate(_ key: String) -> String {
    guard let date = MosqueCalendar.date(fromKey: key) else { return key }
    let formatter = DateFormatter()
    formatter.timeZone = MosqueCalendar.timeZone
    formatter.locale = Locale(identifier: pick("en_CA", "tr_TR", "fr_CA"))
    formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
    return formatter.string(from: date)
  }

  // MARK: 1. Next prayer

  func nextPrayer() -> SiriAnswer {
    guard let next = schedule.nextPrayer() else { return prayersNotCurrent }
    let prayer = next.prayer
    let remaining = left(TimeLeft(from: now, to: prayer.date))
    let friday = fridayLine(prayer, in: next.isTomorrow ? schedule.tomorrow : schedule.today)
    var lines = timesLine(prayer)
    if let friday = friday { lines.append(friday) }
    let times = lines.joined(separator: ", ")
    let spoken = pick(
      "The next prayer is \(name(prayer.key)). \(times). \(remaining) left.",
      "Sıradaki namaz \(SiriTerms.trLower[prayer.key] ?? ""). \(times). \(remaining) kaldı.",
      "La prochaine prière est \(SiriTerms.frIs[prayer.key] ?? name(prayer.key)). \(times). Il reste \(remaining)."
    )
    return SiriAnswer(spoken, card: .prayer(
      eyebrow: pick("NEXT PRAYER", "SIRADAKİ NAMAZ", "PROCHAINE PRIÈRE"),
      name: name(prayer.key),
      big: remaining,
      lines: lines
    ))
  }

  // MARK: 2. A specific prayer

  func prayerTime(_ key: PrayerKey) -> SiriAnswer {
    guard let today = schedule.today, let prayer = today.prayer(key) else {
      return prayersNotCurrent
    }
    var lines = timesLine(prayer)
    if let friday = fridayLine(prayer, in: today) { lines.append(friday) }
    let times = lines.joined(separator: ", ")
    let spoken = pick(
      "\(name(key)) today: \(times).",
      "Bugün \(SiriTerms.trLower[key] ?? ""): \(times).",
      "\(name(key)) aujourd'hui\u{00A0}: \(times)."
    )
    return SiriAnswer(spoken, card: .prayer(
      eyebrow: pick("TODAY", "BUGÜN", "AUJOURD'HUI"),
      name: name(key),
      big: clock(prayer.time),
      lines: lines
    ))
  }

  // MARK: 3. Today's times

  func todayTimes() -> SiriAnswer {
    guard let today = schedule.today else { return prayersNotCurrent }
    let highlighted = schedule.highlighted(in: today)
    let rows = today.prayers.map {
      SiriCard.Row(
        name: name($0.key),
        time: clock($0.time),
        iqamah: $0.iqamah.map(clock),
        highlighted: $0.key == highlighted
      )
    }
    let said = today.prayers.map { "\(name($0.key)) \(clock($0.time))" }.joined(separator: ", ")
    let footer = today.jumuah.map { "\(jumuahName) \(clock($0.time))" }
    let spoken = pick("Today's times: \(said).", "Bugünkü vakitler: \(said).", "Horaires d'aujourd'hui\u{00A0}: \(said).")
    return SiriAnswer(
      footer.map { "\(spoken) \($0)." } ?? spoken,
      card: .table(title: longDate(today.date), rows: rows, footer: footer)
    )
  }

  // MARK: 4. Time left

  func timeLeft(_ key: PrayerKey?) -> SiriAnswer {
    switch schedule.window(key) {
    case .notCurrent:
      return prayersNotCurrent

    case let .active(key, start, end):
      guard let end = end else {
        let status = pick(
          "\(name(key)) time has begun.",
          "\(name(key)) vakti girdi.",
          "\(SiriTerms.frThe[key] ?? name(key)) a commencé."
        )
        return SiriAnswer(status, card: .window(name: name(key), status: status, detail: nil, progress: nil))
      }
      let remaining = left(TimeLeft(from: now, to: end.date))
      let spoken = pick(
        "\(remaining) left for \(name(key)), until \(clock(end.time)).",
        "\(name(key)) vaktinin çıkmasına \(remaining) var. \(TurkishTime.at(end.time.tr)) çıkacak.",
        "Il reste \(remaining) pour la prière \(SiriTerms.frOf[key] ?? ""), jusqu'à \(clock(end.time))."
      )
      var progress: Double?
      if let start = start, start < end.date {
        progress = min(1, max(0, now.timeIntervalSince(start) / end.date.timeIntervalSince(start)))
      }
      return SiriAnswer(spoken, card: .window(
        name: name(key),
        status: pick("\(remaining) left", "\(remaining) kaldı", "Il reste \(remaining)"),
        detail: pick("Until \(clock(end.time))", "Bitiş \(clock(end.time))", "Jusqu'à \(clock(end.time))"),
        progress: progress
      ))

    case let .notStarted(key, prayer):
      let spoken = pick(
        "\(name(key)) hasn't started yet. It starts at \(clock(prayer.time)).",
        "\(name(key)) vakti henüz girmedi (\(TurkishTime.at(prayer.time.tr)) girecek).",
        "\(SiriTerms.frThe[key] ?? name(key)) n'a pas encore commencé. Début à \(clock(prayer.time))."
      )
      return SiriAnswer(spoken, card: .window(
        name: name(key),
        status: pick("Not started yet", "Henüz girmedi", "Pas encore commencé"),
        detail: pick("Starts at \(clock(prayer.time))", "Giriş \(clock(prayer.time))", "Début à \(clock(prayer.time))"),
        progress: nil
      ))

    case let .over(key):
      let spoken = pick(
        "\(name(key)) time is over.",
        "\(name(key)) vakti çıktı.",
        "Le temps de la prière \(SiriTerms.frOf[key] ?? "") est terminé."
      )
      return SiriAnswer(spoken, card: .window(
        name: name(key),
        status: pick("Over", "Vakti çıktı", "Terminé"),
        detail: nil,
        progress: nil
      ))

    case let .noPrayerNow(next):
      let spoken = pick(
        "It isn't prayer time now. \(name(next.key)) starts at \(clock(next.time)).",
        "Şu an namaz vakti değil, \(SiriTerms.trLower[next.key] ?? "") \(TurkishTime.at(next.time.tr)) girecek.",
        "Ce n'est pas l'heure d'une prière. \(SiriTerms.frThe[next.key] ?? name(next.key)) commence à \(clock(next.time))."
      )
      return SiriAnswer(spoken, card: .window(
        name: name(next.key),
        status: pick("Not prayer time", "Namaz vakti değil", "Pas l'heure d'une prière"),
        detail: pick("Starts at \(clock(next.time))", "Giriş \(clock(next.time))", "Début à \(clock(next.time))"),
        progress: nil
      ))
    }
  }

  // MARK: 5. Jumu'ah

  func jumuah() -> SiriAnswer {
    guard let found = schedule.jumuah() else { return prayersNotCurrent }
    let date = longDate(found.day.date)
    let time = clock(found.jumuah.time)
    let spoken: String
    if found.isToday {
      spoken = pick(
        "Jumu'ah is today at \(time).",
        "Cuma namazı bugün \(TurkishTime.at(found.jumuah.time.tr)).",
        "La prière du vendredi (Joumou'a) est aujourd'hui à \(time)."
      )
    } else {
      spoken = pick(
        "Jumu'ah is on \(date) at \(time).",
        "Cuma namazı \(date), saat \(time).",
        "La prière du vendredi (Joumou'a) est le \(date) à \(time)."
      )
    }
    return SiriAnswer(spoken, card: .prayer(
      eyebrow: found.isToday ? pick("TODAY", "BUGÜN", "AUJOURD'HUI") : date.uppercased(with: Locale(identifier: pick("en_CA", "tr_TR", "fr_CA"))),
      name: jumuahName,
      big: time,
      lines: []
    ))
  }

  // MARK: 6. Events

  /// The shown line with the separator read as a pause.
  private func said(_ line: String) -> String {
    line.replacingOccurrences(of: " · ", with: ", ")
  }

  func upcomingEvents() -> SiriAnswer {
    // The panel's switch; the shortcut can't be hidden at runtime.
    if mosque?.eventsEnabled == false { return noEvents }
    guard let items = SiriEvents.upcoming(events, now: now) else { return eventsNotCurrent }
    guard let first = items.first else { return noEvents }
    let code = language.rawValue
    func line(_ event: SiriEvent) -> String { event.when[code] ?? event.when["en"] ?? "" }
    func next(_ event: SiriEvent) -> String? { event.next?[code] ?? event.next?["en"] }
    let details = [line(first), next(first)].compactMap { $0 }.map(said).joined(separator: ", ")
    let spoken = pick(
      "The next event is \(first.title), \(details).",
      "Sıradaki etkinlik: \(first.title), \(details).",
      "Le prochain événement est \(first.title), \(details)."
    )
    return SiriAnswer(spoken, card: .events(
      title: pick("Upcoming events", "Yaklaşan etkinlikler", "Événements à venir"),
      items: items.prefix(5).map { SiriCard.Item(title: $0.title, line: line($0), next: next($0)) }
    ))
  }

  private var noEvents: SiriAnswer {
    SiriAnswer(pick(
      "There are no upcoming events.",
      "Yaklaşan etkinlik yok.",
      "Il n'y a aucun événement à venir."
    ))
  }

  // MARK: 7. Eid

  func eid() -> SiriAnswer {
    guard schedule.today != nil else { return prayersNotCurrent }
    guard let eid = schedule.upcomingEid() else {
      return SiriAnswer(pick(
        "There's no upcoming Eid prayer information.",
        "Yaklaşan bayram namazı bilgisi yok.",
        "Aucune information sur une prochaine prière de l'Aïd."
      ))
    }
    let table = eid.which == "fitr" ? SiriTerms.eidFitr : SiriTerms.eidAdha
    let title = table[language] ?? "Eid"
    let date = longDate(eid.date)
    let first = clock(eid.first)
    var lines = [pick("Prayer \(first)", "Namaz \(first)", "Prière à \(first)")]
    if let second = eid.second.map(clock) {
      lines.append(pick("Second jamaah \(second)", "İkinci cemaat \(second)", "2e prière à \(second)"))
    }
    let spoken = pick(
      "\(title) prayer is on \(date). \(lines.joined(separator: ", ")).",
      "\(title) namazı \(date). \(lines.joined(separator: ", ")).",
      "La prière de l'\(title) est le \(date). \(lines.joined(separator: ", "))."
    )
    return SiriAnswer(spoken, card: .prayer(
      eyebrow: date.uppercased(with: Locale(identifier: pick("en_CA", "tr_TR", "fr_CA"))),
      name: title,
      big: first,
      lines: lines
    ))
  }

  // MARK: 9, 10. Directions and call

  /// Apple Maps directions: the coordinates when set, else the address.
  var directionsURL: URL? {
    var query: String?
    if let lat = mosque?.lat, let lng = mosque?.lng {
      query = "\(lat),\(lng)"
    } else if let address = mosque?.address, !address.isEmpty {
      query = address
    }
    guard let destination = query else { return nil }
    var components = URLComponents(string: "https://maps.apple.com/")
    components?.queryItems = [
      URLQueryItem(name: "daddr", value: destination),
      URLQueryItem(name: "dirflg", value: "d"),
    ]
    return components?.url
  }

  var callURL: URL? {
    guard let tel = mosque?.tel, !tel.isEmpty else { return nil }
    return URL(string: tel)
  }

  func directions() -> SiriAnswer {
    guard directionsURL != nil, let mosque = mosque else { return mosqueNotCurrent }
    let detail = mosque.address ?? mosque.name
    return SiriAnswer(
      pick(
        "Get directions to the mosque in Maps?",
        "Camiye yol tarifi Harita'da açılsın mı?",
        "Ouvrir l'itinéraire vers la mosquée dans Plans?"
      ),
      card: .contact(title: pick("Directions", "Yol tarifi", "Itinéraire"), detail: detail)
    )
  }

  func call() -> SiriAnswer {
    guard callURL != nil, let phone = mosque?.phone else { return mosqueNotCurrent }
    return SiriAnswer(
      pick(
        "Call the mosque at \(phone)?",
        "Cami aransın mı? \(phone)",
        "Appeler la mosquée au \(phone)?"
      ),
      card: .contact(title: pick("Call", "Ara", "Appeler"), detail: phone)
    )
  }

  var opening: String {
    pick("Opening.", "Açılıyor.", "Ouverture.")
  }

  var donateOpening: String {
    pick("Opening donation options.", "Bağış seçenekleri açılıyor.", "Ouverture des options de don.")
  }
}

extension SiriEngine {
  /// The stored documents, as of now, in Siri's language.
  static func current() -> SiriEngine {
    SiriEngine(
      prayers: SiriStore.prayers,
      events: SiriStore.events,
      mosque: SiriStore.mosque,
      now: Date(),
      language: .current
    )
  }
}
