import AppIntents

// Exactly Apple's limit of ten. Phrases are translated in
// {en,tr,fr}.lproj/AppShortcuts.strings, keyed by the English text below;
// test/siri/siri_terms_test.dart keeps the three files in step with this one.
@available(iOS 16.0, *)
struct PapeShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: NextPrayerIntent(),
      phrases: [
        "Next prayer at \(.applicationName)",
        "What's the next prayer at \(.applicationName)",
        "When is the next prayer at \(.applicationName)",
      ],
      shortTitle: "Next prayer",
      systemImageName: "moon.stars.fill"
    )
    AppShortcut(
      intent: PrayerTimeIntent(),
      phrases: [
        "\(\.$prayer) time at \(.applicationName)",
        "When is \(\.$prayer) at \(.applicationName)",
        "\(.applicationName) \(\.$prayer) time",
      ],
      shortTitle: "Prayer time",
      systemImageName: "clock"
    )
    AppShortcut(
      intent: TodayTimesIntent(),
      phrases: [
        "Prayer times at \(.applicationName)",
        "Today's prayer times at \(.applicationName)",
        "\(.applicationName) prayer times today",
      ],
      shortTitle: "Today's times",
      systemImageName: "list.bullet"
    )
    AppShortcut(
      intent: TimeLeftIntent(),
      phrases: [
        "Time left for \(\.$prayer) at \(.applicationName)",
        "How much time is left for \(\.$prayer) at \(.applicationName)",
        "Time left in the current prayer at \(.applicationName)",
      ],
      shortTitle: "Time left",
      systemImageName: "hourglass"
    )
    AppShortcut(
      intent: JumuahIntent(),
      phrases: [
        "Jumu'ah time at \(.applicationName)",
        "When is Friday prayer at \(.applicationName)",
        "\(.applicationName) Jumu'ah",
      ],
      shortTitle: "Jumu'ah",
      systemImageName: "building.columns"
    )
    AppShortcut(
      intent: EventsIntent(),
      phrases: [
        "Upcoming events at \(.applicationName)",
        "What's the next event at \(.applicationName)",
        "\(.applicationName) events",
      ],
      shortTitle: "Events",
      systemImageName: "calendar"
    )
    AppShortcut(
      intent: EidIntent(),
      phrases: [
        "Eid prayer at \(.applicationName)",
        "When is Eid prayer at \(.applicationName)",
        "\(.applicationName) Eid prayer time",
      ],
      shortTitle: "Eid prayer",
      systemImageName: "sparkles"
    )
    AppShortcut(
      intent: DonateIntent(),
      phrases: [
        "Donate to \(.applicationName)",
        "Make a donation to \(.applicationName)",
        "Give to \(.applicationName)",
      ],
      shortTitle: "Donate",
      systemImageName: "heart"
    )
    AppShortcut(
      intent: DirectionsIntent(),
      phrases: [
        "Directions to \(.applicationName)",
        "Take me to \(.applicationName)",
        "Navigate to \(.applicationName)",
      ],
      shortTitle: "Directions",
      systemImageName: "map"
    )
    AppShortcut(
      intent: CallIntent(),
      phrases: [
        "Call \(.applicationName)",
        "Phone \(.applicationName)",
        "Call the office at \(.applicationName)",
      ],
      shortTitle: "Call",
      systemImageName: "phone"
    )
  }
}
