import XCTest

#if canImport(Runner)
@testable import Runner
#else
@testable import SiriCore
#endif

/// The Siri shortcuts' time rules and sentences. Runs in RunnerTests on
/// Codemagic and with `tool/siri_swift_test.sh` in Docker.
final class SiriLogicTests: XCTestCase {
  private let cal = MosqueCalendar.calendar

  private func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
    cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
  }

  /// What Flutter writes (clockText in lib/shared/formatters.dart).
  private func clock(_ date: Date) -> SiriClock {
    let c = cal.dateComponents([.hour, .minute], from: date)
    let (hour, minute) = (c.hour!, c.minute!)
    let h = hour % 12 == 0 ? 12 : hour % 12
    let mm = String(format: "%02d", minute)
    return SiriClock(
      en: "\(h):\(mm) \(hour >= 12 ? "PM" : "AM")",
      tr: String(format: "%02d", hour) + ":" + mm,
      fr: minute == 0 ? "\(hour)\u{00A0}h" : "\(hour)\u{00A0}h\u{00A0}\(mm)"
    )
  }

  private func prayer(_ key: PrayerKey, _ date: Date, iqamahAfter: Int? = 20) -> SiriPrayer {
    let iqamah = key == .sunrise ? nil : iqamahAfter.map { date.addingTimeInterval(Double($0 * 60)) }
    return SiriPrayer(
      key: key,
      at: date.timeIntervalSince1970,
      time: clock(date),
      iqamahAt: iqamah?.timeIntervalSince1970,
      iqamah: iqamah.map(clock)
    )
  }

  /// A plain day: 5:43, 7:11, 13:07, 16:23, 19:02, 20:19.
  private func day(_ y: Int, _ mo: Int, _ d: Int, jumuah: Bool = false) -> SiriDay {
    let date = String(format: "%04d-%02d-%02d", y, mo, d)
    let time = at(y, mo, d, 13, 30)
    return SiriDay(
      date: date,
      prayers: [
        prayer(.fajr, at(y, mo, d, 5, 43)),
        prayer(.sunrise, at(y, mo, d, 7, 11)),
        prayer(.dhuhr, at(y, mo, d, 13, 7)),
        prayer(.asr, at(y, mo, d, 16, 23)),
        prayer(.maghrib, at(y, mo, d, 19, 2)),
        prayer(.isha, at(y, mo, d, 20, 19)),
      ],
      jumuah: jumuah ? SiriJumuah(at: time.timeIntervalSince1970, time: clock(time)) : nil
    )
  }

  private func doc(_ days: [SiriDay], eid: [SiriEid] = []) -> SiriPrayersDoc {
    SiriPrayersDoc(version: SiriStoreKey.version, writtenAt: 0, days: days, eid: eid)
  }

  // Sunday 8 Nov 2026 is an ordinary day; Friday is 13 Nov.
  private lazy var week: [SiriDay] = [
    day(2026, 11, 7), day(2026, 11, 8), day(2026, 11, 9), day(2026, 11, 10),
    day(2026, 11, 11), day(2026, 11, 12), day(2026, 11, 13, jumuah: true),
    day(2026, 11, 14),
  ]

  private func engine(
    _ now: Date,
    days: [SiriDay]? = nil,
    eid: [SiriEid] = [],
    events: SiriEventsDoc? = nil,
    mosque: SiriMosqueDoc? = nil,
    _ language: SiriLanguage = .tr
  ) -> SiriEngine {
    SiriEngine(
      prayers: doc(days ?? week, eid: eid),
      events: events,
      mosque: mosque,
      now: now,
      language: language
    )
  }

  private let notCurrent = "Vakitler güncel değil, lütfen uygulamayı açın."

  // MARK: Next prayer

  func testNextPrayerNameTimesAndTimeLeft() {
    let answer = engine(at(2026, 11, 8, 12, 0)).nextPrayer()
    XCTAssertEqual(answer.spoken, "Sıradaki namaz öğle. Ezan 13:07, Cemaat 13:27. 1 saat 7 dakika kaldı.")
  }

  func testNextPrayerSkipsSunrise() {
    let next = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 6, 0)).nextPrayer()
    XCTAssertEqual(next?.prayer.key, .dhuhr)
  }

  func testAfterIshaItIsTomorrowsFajr() {
    let next = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 22, 0)).nextPrayer()
    XCTAssertEqual(next?.prayer.key, .fajr)
    XCTAssertEqual(next?.isTomorrow, true)
    XCTAssertEqual(next?.prayer.date, at(2026, 11, 9, 5, 43))
  }

  func testAfterIshaWithoutTomorrowIsNotCurrent() {
    let answer = engine(at(2026, 11, 8, 22, 0), days: [day(2026, 11, 8)]).nextPrayer()
    XCTAssertEqual(answer.spoken, notCurrent)
  }

  func testMissingTodayIsNotCurrentEverywhere() {
    // Yesterday and tomorrow are there; today isn't. Nothing is filled in.
    let e = engine(at(2026, 11, 8, 12, 0), days: [day(2026, 11, 7), day(2026, 11, 9)])
    XCTAssertEqual(e.nextPrayer().spoken, notCurrent)
    XCTAssertEqual(e.prayerTime(.dhuhr).spoken, notCurrent)
    XCTAssertEqual(e.todayTimes().spoken, notCurrent)
    XCTAssertEqual(e.timeLeft(nil).spoken, notCurrent)
    XCTAssertEqual(e.timeLeft(.asr).spoken, notCurrent)
    XCTAssertEqual(e.jumuah().spoken, notCurrent)
    XCTAssertEqual(e.eid().spoken, notCurrent)
  }

  func testNoDocumentIsNotCurrent() {
    let e = SiriEngine(prayers: nil, events: nil, mosque: nil, now: at(2026, 11, 8, 12), language: .tr)
    XCTAssertEqual(e.nextPrayer().spoken, notCurrent)
    XCTAssertEqual(e.upcomingEvents().spoken, "Etkinlikler güncel değil, lütfen uygulamayı açın.")
  }

  func testAPartialDayIsNoData() {
    let whole = day(2026, 11, 8)
    let partial = SiriDay(date: whole.date, prayers: Array(whole.prayers.dropLast()), jumuah: nil)
    XCTAssertEqual(engine(at(2026, 11, 8, 12), days: [partial]).nextPrayer().spoken, notCurrent)
  }

  func testTimesOutOfOrderAreNoData() {
    let whole = day(2026, 11, 8)
    var prayers = whole.prayers
    prayers.swapAt(2, 3)
    let swapped = SiriDay(date: whole.date, prayers: prayers, jumuah: nil)
    XCTAssertFalse(swapped.isComplete)
    let sameKeysBadTimes = SiriDay(
      date: whole.date,
      prayers: whole.prayers.map { prayer($0.key, at(2026, 11, 8, 12)) },
      jumuah: nil
    )
    XCTAssertFalse(sameKeysBadTimes.isComplete)
  }

  func testUnknownVersionIsMissing() {
    let json = #"{"version":1,"writtenAt":0,"days":[],"eid":[]}"#
    XCTAssertNil(SiriStore.decode(SiriPrayersDoc.self, json: json) { $0.version })
    let good = #"{"version":2,"writtenAt":0,"days":[],"eid":[]}"#
    XCTAssertNotNil(SiriStore.decode(SiriPrayersDoc.self, json: good) { $0.version })
    XCTAssertNil(SiriStore.decode(SiriPrayersDoc.self, json: "not json") { $0.version })
  }

  // MARK: A specific prayer, today's table

  func testSpecificPrayerAthanAndIqamah() {
    let spoken = engine(at(2026, 11, 8, 12)).prayerTime(.isha).spoken
    XCTAssertEqual(spoken, "Bugün yatsı: Ezan 20:19, Cemaat 20:39.")
  }

  func testFridayDhuhrAddsJumuah() {
    let spoken = engine(at(2026, 11, 13, 10)).prayerTime(.dhuhr).spoken
    XCTAssertEqual(spoken, "Bugün öğle: Ezan 13:07, Cemaat 13:27, Cuma namazı 13:30.")
    let other = engine(at(2026, 11, 8, 10)).prayerTime(.dhuhr).spoken
    XCTAssertFalse(other.contains("Cuma"))
  }

  func testTableHasSixRowsAndHighlightsTheLastTimeThatCame() {
    guard case let .table(_, rows, _) = engine(at(2026, 11, 8, 8)).todayTimes().card else {
      return XCTFail("no table")
    }
    XCTAssertEqual(rows.count, 6)
    XCTAssertEqual(rows.filter(\.highlighted).map(\.name), ["Güneş"])
    XCTAssertNil(rows[1].iqamah)
  }

  func testBeforeFajrNothingIsHighlightedToday() {
    guard case let .table(_, rows, _) = engine(at(2026, 11, 8, 3)).todayTimes().card else {
      return XCTFail("no table")
    }
    XCTAssertTrue(rows.allSatisfy { !$0.highlighted })
  }

  // MARK: Time left

  func testActiveWindow() {
    let e = engine(at(2026, 11, 8, 14, 0))
    XCTAssertEqual(e.timeLeft(.dhuhr).spoken, "Öğle vaktinin çıkmasına 2 saat 23 dakika var. 16:23'te çıkacak.")
    XCTAssertEqual(e.timeLeft(nil).spoken, e.timeLeft(.dhuhr).spoken)
  }

  func testOwnersSentences() {
    XCTAssertEqual(
      engine(at(2026, 11, 8, 10)).timeLeft(.dhuhr).spoken,
      "Öğle vakti henüz girmedi (13:07'de girecek)."
    )
    XCTAssertEqual(engine(at(2026, 11, 8, 17)).timeLeft(.dhuhr).spoken, "Öğle vakti çıktı.")
    XCTAssertEqual(
      engine(at(2026, 11, 8, 10)).timeLeft(nil).spoken,
      "Şu an namaz vakti değil, öğle 13:07'de girecek."
    )
  }

  func testFajrEndsAtSunrise() {
    let s = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 6))
    guard case let .active(key, _, end) = s.window(nil) else { return XCTFail() }
    XCTAssertEqual(key, .fajr)
    XCTAssertEqual(end?.key, .sunrise)
    let after = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 7, 11))
    XCTAssertEqual(after.window(.fajr), .over(.fajr))
  }

  func testIshaEndsAtTomorrowsFajr() {
    let s = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 23))
    guard case let .active(key, _, end) = s.window(.isha) else { return XCTFail() }
    XCTAssertEqual(key, .isha)
    XCTAssertEqual(end?.date, at(2026, 11, 9, 5, 43))
  }

  func testIshaWithoutTomorrowSaysOnlyWhatIsKnown() {
    let e = engine(at(2026, 11, 8, 23), days: [day(2026, 11, 8)])
    XCTAssertEqual(e.timeLeft(.isha).spoken, "Yatsı vakti girdi.")
    guard case let .window(_, _, detail, progress) = e.timeLeft(.isha).card else { return XCTFail() }
    XCTAssertNil(detail)
    XCTAssertNil(progress)
  }

  func testAfterMidnightIsStillLastNightsIsha() {
    let s = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 1))
    guard case let .active(key, start, end) = s.window(nil) else { return XCTFail() }
    XCTAssertEqual(key, .isha)
    XCTAssertEqual(start, at(2026, 11, 7, 20, 19))
    XCTAssertEqual(end?.date, at(2026, 11, 8, 5, 43))
    // Named prayers that come later today haven't started.
    if case .notStarted(.fajr, _) = s.window(.fajr) {} else { XCTFail() }
    if case .notStarted(.dhuhr, _) = s.window(.dhuhr) {} else { XCTFail() }
    if case .active(.isha, _, _) = s.window(.isha) {} else { XCTFail() }
  }

  func testAfterMidnightWithoutYesterdayStillKnowsTheEnd() {
    let s = SiriSchedule(doc: doc([day(2026, 11, 8)]), now: at(2026, 11, 8, 1))
    guard case let .active(_, start, end) = s.window(nil) else { return XCTFail() }
    XCTAssertNil(start)
    XCTAssertEqual(end?.key, .fajr)
  }

  func testBoundaryBelongsToTheNewWindow() {
    let s = SiriSchedule(doc: doc(week), now: at(2026, 11, 8, 16, 23))
    if case .active(.asr, _, _) = s.window(nil) {} else { XCTFail() }
    XCTAssertEqual(s.window(.dhuhr), .over(.dhuhr))
  }

  func testTimeLeftRoundsDownAndNeverOverstates() {
    let now = at(2026, 11, 8, 12)
    XCTAssertEqual(TimeLeft(from: now, to: now.addingTimeInterval(119)).minutes, 1)
    XCTAssertTrue(TimeLeft(from: now, to: now.addingTimeInterval(59)).isUnderAMinute)
    XCTAssertTrue(TimeLeft(from: now, to: now.addingTimeInterval(-5)).isUnderAMinute)
    let e = engine(at(2026, 11, 8, 16, 22, 30))
    XCTAssertEqual(e.timeLeft(.dhuhr).spoken, "Öğle vaktinin çıkmasına 1 dakikadan az var. 16:23'te çıkacak.")
  }

  private func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, _ s: Int) -> Date {
    cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi, second: s))!
  }

  // MARK: Jumu'ah

  func testJumuahBeforeOnFridayIsToday() {
    XCTAssertEqual(engine(at(2026, 11, 13, 10)).jumuah().spoken, "Cuma namazı bugün 13:30'da.")
  }

  func testJumuahAfterOnFridayIsNextFriday() {
    var days = week
    days.append(day(2026, 11, 20, jumuah: true))
    let found = SiriSchedule(doc: doc(days), now: at(2026, 11, 13, 14)).jumuah()
    XCTAssertEqual(found?.day.date, "2026-11-20")
    XCTAssertEqual(found?.isToday, false)
  }

  func testJumuahAfterOnFridayWithoutNextFridayIsNotCurrent() {
    XCTAssertEqual(engine(at(2026, 11, 13, 14)).jumuah().spoken, notCurrent)
  }

  func testJumuahMidWeekIsThisFriday() {
    let found = SiriSchedule(doc: doc(week), now: at(2026, 11, 9, 9)).jumuah()
    XCTAssertEqual(found?.day.date, "2026-11-13")
  }

  func testJumuahNeverComesFromAnotherDaysRow() {
    // Friday's row has no readable time; other rows must not stand in.
    let days = [day(2026, 11, 9, jumuah: true), day(2026, 11, 13)]
    XCTAssertNil(SiriSchedule(doc: doc(days), now: at(2026, 11, 9, 9)).jumuah())
  }

  func testJumuahDateIsInTheLanguage() {
    let spoken = engine(at(2026, 11, 9, 9), .en).jumuah().spoken
    XCTAssertTrue(spoken.contains("November 13"), spoken)
    XCTAssertTrue(spoken.contains("1:30 PM"), spoken)
  }

  // MARK: Events

  private func event(_ id: String, _ dayKey: String, _ start: Date, next: Bool = false) -> SiriEvent {
    SiriEvent(
      id: id,
      title: "Etkinlik \(id)",
      day: dayKey,
      startsAt: start.timeIntervalSince1970,
      when: ["tr": "Her Çarşamba · akşam namazından sonra", "en": "Every Wednesday · after Maghrib"],
      next: next ? ["tr": "sıradaki: Çar 11 Kas", "en": "next: Wed 11 Nov"] : nil
    )
  }

  func testEventsOlderThanSevenDaysAreNotCurrent() {
    let now = at(2026, 11, 8, 12)
    let old = SiriEventsDoc(version: SiriStoreKey.version, fetchedAt: now.addingTimeInterval(-8 * 86400).timeIntervalSince1970, items: [])
    XCTAssertEqual(
      engine(now, events: old).upcomingEvents().spoken,
      "Etkinlikler güncel değil, lütfen uygulamayı açın."
    )
    let edge = SiriEventsDoc(version: SiriStoreKey.version, fetchedAt: now.addingTimeInterval(-7 * 86400).timeIntervalSince1970, items: [])
    XCTAssertEqual(engine(now, events: edge).upcomingEvents().spoken, "Yaklaşan etkinlik yok.")
  }

  func testEventsSpeakTheNextAndListEachEventOnce() {
    let now = at(2026, 11, 8, 12)
    let items = [
      event("b", "2026-11-11", at(2026, 11, 11, 19), next: true),
      event("b", "2026-11-18", at(2026, 11, 18, 19), next: true),
      event("a", "2026-11-09", at(2026, 11, 9, 18)),
      event("old", "2026-11-07", at(2026, 11, 7, 18)),
    ]
    let answer = engine(now, events: SiriEventsDoc(version: SiriStoreKey.version, fetchedAt: now.timeIntervalSince1970, items: items)).upcomingEvents()
    XCTAssertEqual(answer.spoken, "Sıradaki etkinlik: Etkinlik a, Her Çarşamba, akşam namazından sonra.")
    guard case let .events(_, list) = answer.card else { return XCTFail() }
    XCTAssertEqual(list.map(\.title), ["Etkinlik a", "Etkinlik b"])
    XCTAssertEqual(list[0].line, "Her Çarşamba · akşam namazından sonra")
  }

  func testEventStaysListedAllDay() {
    let now = at(2026, 11, 8, 22)
    let items = [event("a", "2026-11-08", at(2026, 11, 8, 10))]
    let list = SiriEvents.upcoming(SiriEventsDoc(version: SiriStoreKey.version, fetchedAt: now.timeIntervalSince1970, items: items), now: now)
    XCTAssertEqual(list?.count, 1)
  }

  func testEventsOffInThePanelReadAsNone() {
    let now = at(2026, 11, 8, 12)
    let m = SiriMosqueDoc(version: SiriStoreKey.version, name: "M", phone: nil, tel: nil, address: nil, lat: nil, lng: nil, eventsEnabled: false)
    let docs = SiriEventsDoc(version: SiriStoreKey.version, fetchedAt: now.timeIntervalSince1970, items: [event("a", "2026-11-09", at(2026, 11, 9, 18))])
    XCTAssertEqual(engine(now, events: docs, mosque: m).upcomingEvents().spoken, "Yaklaşan etkinlik yok.")
  }

  // MARK: Eid

  private func eid(_ which: String, _ y: Int, _ mo: Int, _ d: Int) -> SiriEid {
    SiriEid(
      which: which,
      date: String(format: "%04d-%02d-%02d", y, mo, d),
      firstAt: at(y, mo, d, 8).timeIntervalSince1970,
      first: clock(at(y, mo, d, 8)),
      secondAt: at(y, mo, d, 8, 30).timeIntervalSince1970,
      second: clock(at(y, mo, d, 8, 30))
    )
  }

  func testNoEidSaysSo() {
    let none = "Yaklaşan bayram namazı bilgisi yok."
    XCTAssertEqual(engine(at(2026, 11, 8, 12)).eid().spoken, none)
    XCTAssertEqual(engine(at(2026, 11, 8, 12), eid: [eid("fitr", 2026, 3, 20)]).eid().spoken, none)
  }

  func testUpcomingEidIsTheSoonest() {
    let e = engine(at(2026, 11, 8, 12), eid: [eid("adha", 2027, 5, 16), eid("fitr", 2027, 3, 9)])
    XCTAssertTrue(e.eid().spoken.hasPrefix("Ramazan Bayramı namazı"), e.eid().spoken)
    XCTAssertTrue(e.eid().spoken.contains("Namaz 08:00, İkinci cemaat 08:30"), e.eid().spoken)
  }

  func testEidDayCountsUntilTheSecondPrayerPasses() {
    let days = [day(2027, 3, 9)]
    let list = [eid("fitr", 2027, 3, 9)]
    XCTAssertNotNil(SiriSchedule(doc: doc(days, eid: list), now: at(2027, 3, 9, 8, 15)).upcomingEid())
    XCTAssertNil(SiriSchedule(doc: doc(days, eid: list), now: at(2027, 3, 9, 8, 30)).upcomingEid())
  }

  // MARK: DST and time zones

  func testFallBackDayHasTwentyFiveHours() {
    // 1 Nov 2026: clocks go back at 2:00. From 00:30 to 05:43 is 6 h 13 m.
    let today = day(2026, 11, 1)
    let now = at(2026, 11, 1, 0, 30)
    let left = TimeLeft(from: now, to: today.prayer(.fajr)!.date)
    XCTAssertEqual(left.hours, 6)
    XCTAssertEqual(left.minutes, 13)
    XCTAssertEqual(MosqueCalendar.dayKey(now, plusDays: 1), "2026-11-02")
    XCTAssertEqual(MosqueCalendar.dayKey(at(2026, 11, 1, 23, 30), plusDays: 1), "2026-11-02")
  }

  func testSpringForwardDayHasTwentyThreeHours() {
    // 14 Mar 2027: clocks go forward at 2:00. From 00:30 to 05:43 is 4 h 13 m.
    let today = day(2027, 3, 14)
    let left = TimeLeft(from: at(2027, 3, 14, 0, 30), to: today.prayer(.fajr)!.date)
    XCTAssertEqual(left.hours, 4)
    XCTAssertEqual(left.minutes, 13)
    XCTAssertEqual(MosqueCalendar.dayKey(at(2027, 3, 14, 23, 30), plusDays: 1), "2027-03-15")
  }

  func testPhoneTimeZoneDoesNotMatter() {
    let saved = NSTimeZone.default
    defer { NSTimeZone.default = saved }
    // 23:30 Sunday in Toronto is already Monday in Istanbul.
    let now = at(2026, 11, 8, 23, 30)
    let toronto = engine(now).timeLeft(nil).spoken
    NSTimeZone.default = TimeZone(identifier: "Europe/Istanbul")!
    XCTAssertEqual(MosqueCalendar.dayKey(now), "2026-11-08")
    XCTAssertEqual(engine(now).timeLeft(nil).spoken, toronto)
  }

  // MARK: Words

  func testTurkishSuffixFollowsTheLastNumberSaid() {
    let cases: [(String, String)] = [
      ("13:07", "13:07'de"), ("16:23", "16:23'te"), ("05:43", "05:43'te"),
      ("20:19", "20:19'da"), ("16:30", "16:30'da"), ("19:40", "19:40'ta"),
      ("13:50", "13:50'de"), ("14:20", "14:20'de"), ("06:10", "06:10'da"),
      ("13:05", "13:05'te"), ("07:06", "07:06'da"),
      // On the hour, only the hour is said.
      ("13:00", "13:00'te"), ("16:00", "16:00'da"), ("15:00", "15:00'te"),
      ("06:00", "06:00'da"), ("10:00", "10:00'da"), ("12:00", "12:00'de"),
      ("09:00", "09:00'da"), ("20:00", "20:00'de"), ("21:00", "21:00'de"),
      ("00:00", "00:00'da"), ("00:30", "00:30'da"),
    ]
    for (time, expected) in cases {
      XCTAssertEqual(TurkishTime.at(time), expected, time)
    }
  }

  func testSentencesUseTheTurkishSuffixOn24HourTimes() {
    XCTAssertEqual(
      engine(at(2026, 11, 8, 17)).timeLeft(.asr).spoken,
      "İkindi vaktinin çıkmasına 2 saat 2 dakika var. 19:02'de çıkacak."
    )
    XCTAssertEqual(engine(at(2026, 11, 13, 9)).jumuah().spoken, "Cuma namazı bugün 13:30'da.")
  }

  func testSnippetsAndSpeechFollowTheLanguage() {
    let now = at(2026, 11, 8, 12)
    guard case let .table(_, en, _) = engine(now, .en).todayTimes().card,
          case let .table(_, tr, _) = engine(now, .tr).todayTimes().card,
          case let .table(_, fr, _) = engine(now, .fr).todayTimes().card else {
      return XCTFail("today's times should be a table")
    }
    XCTAssertEqual(en[3].time, "4:23 PM")
    XCTAssertEqual(tr[3].time, "16:23")
    XCTAssertEqual(fr[3].time, "16\u{00A0}h\u{00A0}23")
    XCTAssertEqual(tr[0].time, "05:43")
    XCTAssertEqual(fr[0].time, "5\u{00A0}h\u{00A0}43")
    XCTAssertFalse(engine(now, .tr).todayTimes().spoken.contains("PM"))
    XCTAssertFalse(engine(now, .fr).todayTimes().spoken.contains("PM"))
  }

  /// The texts come from Flutter; the instants decide. Across both clock
  /// changes a time reads the same and its instant moves by the hour.
  func testDSTDaysKeepTheWallClockInEveryLanguage() {
    for (y, mo, d, utcHour) in [(2026, 3, 7, 18), (2026, 3, 8, 17), (2026, 10, 31, 17), (2026, 11, 1, 18)] {
      let dhuhr = day(y, mo, d).prayer(.dhuhr)!
      XCTAssertEqual(dhuhr.time.en, "1:07 PM")
      XCTAssertEqual(dhuhr.time.tr, "13:07")
      XCTAssertEqual(dhuhr.time.fr, "13\u{00A0}h\u{00A0}07")
      var utc = Calendar(identifier: .gregorian)
      utc.timeZone = TimeZone(identifier: "UTC")!
      XCTAssertEqual(utc.component(.hour, from: dhuhr.date), utcHour, "\(y)-\(mo)-\(d)")
    }
  }

  func testATimeWithoutEveryLanguageIsRefused() {
    let missingFr = #"{"version":2,"writtenAt":0,"days":[{"date":"2026-11-08","prayers":[{"key":"Fajr","at":1,"time":{"en":"5:43 AM","tr":"05:43"}}]}],"eid":[]}"#
    XCTAssertNil(SiriStore.decode(SiriPrayersDoc.self, json: missingFr) { $0.version })
    let oldText = #"{"version":2,"writtenAt":0,"days":[{"date":"2026-11-08","prayers":[{"key":"Fajr","at":1,"time":"5:43 AM"}]}],"eid":[]}"#
    XCTAssertNil(SiriStore.decode(SiriPrayersDoc.self, json: oldText) { $0.version })
  }

  func testTheThreeLanguages() {
    let now = at(2026, 11, 8, 12)
    XCTAssertEqual(
      engine(now, .en).nextPrayer().spoken,
      "The next prayer is Dhuhr. Athan 1:07 PM, Iqamah 1:27 PM. 1 hour 7 minutes left."
    )
    XCTAssertEqual(
      engine(now, .fr).nextPrayer().spoken,
      "La prochaine prière est le Dhohr. Adhan 13\u{00A0}h\u{00A0}07, Iqama 13\u{00A0}h\u{00A0}27. Il reste 1 heure 7 minutes."
    )
    XCTAssertEqual(engine(at(2026, 11, 8, 17), .en).timeLeft(.asr).spoken, "2 hours 2 minutes left for Asr, until 7:02 PM.")
    XCTAssertEqual(
      engine(at(2026, 11, 8, 17), .fr).timeLeft(.asr).spoken,
      "Il reste 2 heures 2 minutes pour la prière de l'Asr, jusqu'à 19\u{00A0}h\u{00A0}02."
    )
    XCTAssertEqual(engine(at(2026, 11, 8, 18), .fr).timeLeft(.dhuhr).spoken, "Le temps de la prière du Dhohr est terminé.")
  }

  // MARK: Directions, call

  private func mosque(lat: Double? = nil, lng: Double? = nil, phone: String? = "647 834 2000") -> SiriMosqueDoc {
    SiriMosqueDoc(
      version: SiriStoreKey.version, name: "Pape", phone: phone, tel: phone == nil ? nil : "tel:+16478342000",
      address: "336 Pape Avenue, Toronto, ON M4M 2W7", lat: lat, lng: lng, eventsEnabled: true
    )
  }

  func testDirectionsUseCoordinatesElseAddress() {
    let now = at(2026, 11, 8, 12)
    let address = engine(now, mosque: mosque()).directionsURL?.absoluteString ?? ""
    XCTAssertTrue(address.hasPrefix("https://maps.apple.com/?daddr=336%20Pape"), address)
    let coords = engine(now, mosque: mosque(lat: 43.6, lng: -79.3)).directionsURL?.absoluteString ?? ""
    XCTAssertTrue(coords.contains("daddr=43.6,-79.3"), coords)
  }

  func testNoMosqueDataRefuses() {
    let now = at(2026, 11, 8, 12)
    XCTAssertNil(engine(now).directionsURL)
    XCTAssertNil(engine(now, mosque: mosque(phone: nil)).callURL)
    XCTAssertTrue(engine(now).call().spoken.contains("güncel değil"))
  }
}
