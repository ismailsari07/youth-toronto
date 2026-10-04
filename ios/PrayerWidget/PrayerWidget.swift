import SwiftUI
import WidgetKit

// Prayer time widgets: home screen (small, medium) and, from iOS 16, lock
// screen (rectangular, inline).
//
// The widget never goes to the network. The app writes one JSON document
// into the shared App Group (lib/core/prayer_widget_sync.dart): about a week
// of prayer instants with names and times already localised and formatted,
// in the language the app is set to. The timeline has one entry per prayer,
// and the countdown is SwiftUI's self-updating timer text, so the widget
// stays right for days without the app opening — and says so plainly once
// the stored week runs out.

private let appGroup = "group.ca.papemosque.app"
private let dataKey = "prayer_widget_data" // must match AppDelegate.swift

/// Opens the app on the Prayer tab (go_router path /prayer).
private let prayerTabURL = URL(string: "papemosque:///prayer")

// MARK: - Stored data

struct StoredPrayer: Decodable, Hashable {
  let key: String // English name: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
  let name: String // localised
  let at: Double // athan, Unix seconds
  let time: String // "4:55 PM"
  let athan: String // "Athan 4:55 PM"
  let iqamah: String? // "Iqamah 5:15 PM"; absent for Sunrise
  let day: String // mosque date, yyyy-MM-dd

  var date: Date { Date(timeIntervalSince1970: at) }

  /// Sunrise is listed but never counted down to, as in the app.
  var isPrayer: Bool { key != "Sunrise" }
}

struct StoredStrings: Decodable, Hashable {
  let nextPrayer: String
}

struct StoredData: Decodable {
  let version: Int
  let locale: String
  let strings: StoredStrings
  let prayers: [StoredPrayer] // in time order

  static func load() -> StoredData? {
    guard let defaults = UserDefaults(suiteName: appGroup),
          let json = defaults.string(forKey: dataKey),
          let bytes = json.data(using: .utf8),
          let data = try? JSONDecoder().decode(StoredData.self, from: bytes),
          data.version == 1
    else { return nil }
    return data
  }
}

/// The few strings only the widget needs, including the ones shown before
/// the app has written anything. Follows the app's language once it has.
struct WidgetText {
  let title: String
  let summary: String
  let openApp: String

  static func forLanguage(_ code: String?) -> WidgetText {
    let lang = String((code ?? "en").prefix(2)).lowercased()
    switch lang {
    case "fr":
      return WidgetText(
        title: "Heures de prière",
        summary: "La prochaine prière à la mosquée, avec un compte à rebours.",
        openApp: "Ouvrez Pape Mosque pour mettre à jour les heures de prière."
      )
    case "tr":
      return WidgetText(
        title: "Namaz Vakitleri",
        summary: "Camide sıradaki namaz ve geri sayım.",
        openApp: "Namaz vakitlerini güncellemek için Pape Mosque'u açın."
      )
    default:
      return WidgetText(
        title: "Prayer Times",
        summary: "The next prayer at the mosque, with a live countdown.",
        openApp: "Open Pape Mosque to update prayer times."
      )
    }
  }

  static var current: WidgetText {
    forLanguage(StoredData.load()?.locale ?? Locale.preferredLanguages.first)
  }
}

// MARK: - Timeline

struct Snapshot {
  let label: String // "NEXT PRAYER"
  let next: StoredPrayer
  let current: StoredPrayer? // the prayer whose window we are in
  let day: [StoredPrayer] // the next prayer's day, Sunrise included
}

enum EntryState {
  case ready(Snapshot)
  case missing(WidgetText)
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let state: EntryState

  /// What the widget shows at [date]: the first prayer after it, or the
  /// "open the app" message when there is no data or it has run out.
  static func make(at date: Date, data: StoredData?) -> PrayerEntry {
    guard let data = data,
          let next = data.prayers.first(where: { $0.isPrayer && $0.date > date })
    else {
      let code = data?.locale ?? Locale.preferredLanguages.first
      return PrayerEntry(date: date, state: .missing(WidgetText.forLanguage(code)))
    }
    let current = data.prayers.last(where: { $0.isPrayer && $0.date <= date })
    let day = data.prayers.filter { $0.day == next.day }
    let snapshot = Snapshot(
      label: data.strings.nextPrayer,
      next: next,
      current: current,
      day: day
    )
    return PrayerEntry(date: date, state: .ready(snapshot))
  }

  /// Gallery placeholder: plausible English times around now.
  static var sample: PrayerEntry {
    let now = Date()
    func prayer(_ key: String, _ offset: Double, _ time: String) -> StoredPrayer {
      StoredPrayer(
        key: key,
        name: key,
        at: now.addingTimeInterval(offset).timeIntervalSince1970,
        time: time,
        athan: "Athan \(time)",
        iqamah: nil,
        day: "sample"
      )
    }
    let day = [
      prayer("Fajr", -36_000, "5:43 AM"),
      prayer("Sunrise", -32_000, "7:11 AM"),
      prayer("Dhuhr", -12_000, "1:11 PM"),
      prayer("Asr", 4_500, "4:23 PM"),
      prayer("Maghrib", 14_000, "7:02 PM"),
      prayer("Isha", 18_000, "8:19 PM"),
    ]
    let snapshot = Snapshot(label: "NEXT PRAYER", next: day[3], current: day[2], day: day)
    return PrayerEntry(date: now, state: .ready(snapshot))
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry.sample
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    let data = StoredData.load()
    if data == nil && context.isPreview {
      completion(PrayerEntry.sample)
    } else {
      completion(PrayerEntry.make(at: Date(), data: data))
    }
  }

  /// One entry now and one at each coming prayer; the countdown text ticks
  /// on its own between them. After the last stored prayer the final entry
  /// shows the "open the app" message, and the app reloads the timelines
  /// whenever it writes new data.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date()
    let data = StoredData.load()
    var entries = [PrayerEntry.make(at: now, data: data)]
    for prayer in data?.prayers ?? [] where prayer.isPrayer && prayer.date > now {
      entries.append(PrayerEntry.make(at: prayer.date, data: data))
    }
    let policy: TimelineReloadPolicy = entries.count > 1 ? .atEnd : .never
    completion(Timeline(entries: entries, policy: policy))
  }
}

// MARK: - Look

/// The moon card's palette: night navy, white text, the app's green. Navy in
/// both light and dark mode, like the card it echoes.
private enum Palette {
  static let night = Color(red: 14 / 255, green: 26 / 255, blue: 43 / 255)
  static let green = Color(red: 14 / 255, green: 117 / 255, blue: 80 / 255)
  static let mint = Color(red: 92 / 255, green: 203 / 255, blue: 148 / 255)
  static let label = Color.white.opacity(0.8)
  static let secondary = Color.white.opacity(0.78)
}

extension View {
  /// Home-screen background. iOS 17+ uses the container background (no
  /// default margins to fight, and the system can drop it in tinted and
  /// clear modes); earlier versions paint it and pad by hand.
  @ViewBuilder
  func homeBackground() -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(Palette.night, for: .widget)
    } else {
      self
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }
  }

  /// Lock-screen widgets draw on the system's own background, but iOS 17
  /// still requires the container background to be declared.
  @ViewBuilder
  func accessoryBackground() -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(Color.clear, for: .widget)
    } else {
      self
    }
  }

  /// The parts tinted with the accent colour in iOS's tinted modes.
  @ViewBuilder
  func accentable() -> some View {
    if #available(iOS 16.0, *) {
      self.widgetAccentable()
    } else {
      self
    }
  }
}

struct CountdownText: View {
  let target: Date
  let size: CGFloat

  var body: some View {
    Text(target, style: .timer)
      .font(.system(size: size, weight: .semibold, design: .rounded).monospacedDigit())
      .foregroundColor(.white)
      .multilineTextAlignment(.leading)
      .lineLimit(1)
      .minimumScaleFactor(0.6)
  }
}

/// How far through the current prayer window we are, filling live like the
/// moon in the app (iOS 16+; earlier versions simply omit it).
struct WindowProgress: View {
  let from: Date?
  let to: Date

  var body: some View {
    if #available(iOS 16.0, *) {
      if let from = from, from < to {
        ProgressView(
          timerInterval: from...to,
          countsDown: false,
          label: { EmptyView() },
          currentValueLabel: { EmptyView() }
        )
        .progressViewStyle(.linear)
        .tint(Palette.mint)
      }
    }
  }
}

/// Small widget, and the left half of the medium one.
struct NextPrayerView: View {
  let snapshot: Snapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(snapshot.label)
        .font(.system(size: 10, weight: .semibold))
        .kerning(0.6)
        .foregroundColor(Palette.label)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Spacer(minLength: 4)
      Text(snapshot.next.name)
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .accentable()
      CountdownText(target: snapshot.next.date, size: 24)
      Spacer(minLength: 4)
      Text(snapshot.next.athan)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(Palette.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      if let iqamah = snapshot.next.iqamah {
        Text(iqamah)
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(Palette.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      WindowProgress(from: snapshot.current?.date, to: snapshot.next.date)
        .padding(.top, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct PrayerRow: View {
  let prayer: StoredPrayer
  let highlighted: Bool

  var body: some View {
    if highlighted {
      row.accentable()
    } else {
      row
    }
  }

  private var row: some View {
    HStack(spacing: 4) {
      Text(prayer.name)
        .font(.system(size: 12, weight: highlighted ? .bold : .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Spacer(minLength: 4)
      Text(prayer.time)
        .font(.system(size: 12, weight: highlighted ? .bold : .regular).monospacedDigit())
        .lineLimit(1)
    }
    .foregroundColor(highlighted ? .white : Palette.secondary)
    .padding(.horizontal, 7)
    .padding(.vertical, 2)
    .background(
      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .fill(highlighted ? Palette.green : Color.clear)
    )
  }
}

struct MediumView: View {
  let snapshot: Snapshot

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      NextPrayerView(snapshot: snapshot)
      VStack(spacing: 1) {
        ForEach(snapshot.day, id: \.self) { prayer in
          PrayerRow(prayer: prayer, highlighted: prayer == snapshot.next)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

@available(iOS 16.0, *)
struct RectangularView: View {
  let snapshot: Snapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(verbatim: "\(snapshot.next.name) · \(snapshot.next.time)")
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .widgetAccentable()
      Text(snapshot.next.date, style: .timer)
        .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
        .multilineTextAlignment(.leading)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ReadyView: View {
  let snapshot: Snapshot
  let family: WidgetFamily

  var body: some View {
    switch family {
    case .systemMedium:
      MediumView(snapshot: snapshot).homeBackground()
    case .systemSmall:
      NextPrayerView(snapshot: snapshot).homeBackground()
    default:
      accessory
    }
  }

  @ViewBuilder
  private var accessory: some View {
    if #available(iOS 16.0, *) {
      switch family {
      case .accessoryInline:
        Text(verbatim: "\(snapshot.next.name) \(snapshot.next.time)")
          .accessoryBackground()
      case .accessoryRectangular:
        RectangularView(snapshot: snapshot).accessoryBackground()
      default:
        NextPrayerView(snapshot: snapshot).homeBackground()
      }
    } else {
      NextPrayerView(snapshot: snapshot).homeBackground()
    }
  }
}

struct MissingView: View {
  let text: WidgetText
  let family: WidgetFamily

  var body: some View {
    switch family {
    case .systemSmall, .systemMedium:
      VStack(alignment: .leading, spacing: 8) {
        Image(systemName: "moon.stars.fill")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(Palette.mint)
          .accentable()
        Text(text.openApp)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(.white)
          .lineLimit(4)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .homeBackground()
    default:
      accessory
    }
  }

  @ViewBuilder
  private var accessory: some View {
    if #available(iOS 16.0, *) {
      switch family {
      case .accessoryInline:
        Text(verbatim: "Pape Mosque").accessoryBackground()
      default:
        Text(text.openApp)
          .font(.caption)
          .lineLimit(3)
          .minimumScaleFactor(0.8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessoryBackground()
      }
    } else {
      Text(text.openApp).homeBackground()
    }
  }
}

struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry

  var body: some View {
    content.widgetURL(prayerTabURL)
  }

  @ViewBuilder
  private var content: some View {
    switch entry.state {
    case .ready(let snapshot):
      ReadyView(snapshot: snapshot, family: family)
    case .missing(let text):
      MissingView(text: text, family: family)
    }
  }
}

// MARK: - Widget

@main
struct PrayerTimesWidget: Widget {
  private let kind = "PrayerTimesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      PrayerWidgetView(entry: entry)
    }
    .configurationDisplayName(WidgetText.current.title)
    .description(WidgetText.current.summary)
    .supportedFamilies(PrayerTimesWidget.families)
  }

  /// Lock-screen families exist from iOS 16; older systems get the
  /// home-screen sizes only.
  private static var families: [WidgetFamily] {
    if #available(iOS 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]
    }
    return [.systemSmall, .systemMedium]
  }
}
