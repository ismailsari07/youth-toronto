class DailyPrayerItem {
  final String name;
  final String time;
  final String? iqamah;

  const DailyPrayerItem({
    required this.name,
    required this.time,
    this.iqamah,
  });

  factory DailyPrayerItem.fromJson(Map<String, dynamic> json) =>
      DailyPrayerItem(
        name: json['name'] as String,
        time: json['time'] as String,
        iqamah: json['iqamah'] as String?,
      );
}

class EidPrayerEntry {
  final String date;
  final String time;
  final String hijriDate;
  final String firstIqamah;
  final String secondIqamah;

  const EidPrayerEntry({
    required this.date,
    required this.time,
    required this.hijriDate,
    required this.firstIqamah,
    required this.secondIqamah,
  });

  factory EidPrayerEntry.fromJson(Map<String, dynamic> json) => EidPrayerEntry(
        date: json['date'] as String,
        time: json['time'] as String,
        hijriDate: json['hijriDate'] as String,
        firstIqamah: json['firstIqamah'] as String,
        secondIqamah: json['secondIqamah'] as String,
      );
}

class EidPrayerTimes {
  final EidPrayerEntry eidAdha;
  final EidPrayerEntry eidFitr;

  const EidPrayerTimes({required this.eidAdha, required this.eidFitr});

  factory EidPrayerTimes.fromJson(Map<String, dynamic> json) => EidPrayerTimes(
        eidAdha:
            EidPrayerEntry.fromJson(json['eidAdha'] as Map<String, dynamic>),
        eidFitr:
            EidPrayerEntry.fromJson(json['eidFitr'] as Map<String, dynamic>),
      );
}

class PrayerCachePayload {
  final List<DailyPrayerItem> dailyPrayerTimes;
  final String hijriDate;
  final String gregorianDate;
  final String? jumaaPrayerTime;
  final EidPrayerTimes? eidPrayerTimes;

  const PrayerCachePayload({
    required this.dailyPrayerTimes,
    required this.hijriDate,
    required this.gregorianDate,
    this.jumaaPrayerTime,
    this.eidPrayerTimes,
  });

  factory PrayerCachePayload.fromJson(Map<String, dynamic> json) =>
      PrayerCachePayload(
        dailyPrayerTimes: (json['dailyPrayerTimes'] as List<dynamic>)
            .map((e) => DailyPrayerItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        hijriDate: json['hijriDate'] as String,
        gregorianDate: json['gregorianDate'] as String,
        jumaaPrayerTime: json['jumaaPrayerTime'] as String?,
        eidPrayerTimes: json['eidPrayerTimes'] != null
            ? EidPrayerTimes.fromJson(
                json['eidPrayerTimes'] as Map<String, dynamic>)
            : null,
      );
}

class NextPrayer {
  final String name;
  final String time;
  final String? iqamah;
  final int minutesUntil;

  const NextPrayer({
    required this.name,
    required this.time,
    this.iqamah,
    required this.minutesUntil,
  });
}

/// `youth_events.recurrence`. Anything else (including '' and 'none') is a
/// one-off event.
enum EventRecurrence {
  none,
  weekly,
  biweekly,
  monthly;

  static EventRecurrence parse(String? raw) => switch (raw?.trim()) {
        'weekly' => weekly,
        'biweekly' => biweekly,
        'monthly' => monthly,
        _ => none,
      };

  bool get isRecurring => this != none;
}

class YouthEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime dateTime;
  final bool isFree;
  final String? price;
  final int attendingCount;
  final String category;
  final String? imageUrl;
  final String? registrationLink;
  final String recurrence;
  final bool isPublished;

  /// `fajr | dhuhr | asr | maghrib | isha`, or null for a normal clock time.
  /// When set, the event begins after that prayer's jama'ah (spec §7.3).
  final String? startsAfterPrayer;

  const YouthEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.dateTime,
    required this.isFree,
    this.price,
    required this.attendingCount,
    required this.category,
    this.imageUrl,
    this.registrationLink,
    required this.recurrence,
    required this.isPublished,
    this.startsAfterPrayer,
  });

  EventRecurrence get repeats => EventRecurrence.parse(recurrence);

  /// registration_link as a launchable web URL, or null if blank or unsafe.
  /// Admins may omit the scheme ("forms.gle/abc"), so https:// is assumed.
  Uri? get registrationUri {
    final raw = registrationLink?.trim() ?? '';
    if (raw.isEmpty || raw.contains(RegExp(r'\s'))) return null;
    final withScheme = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    // Reject user:pass@ tricks (e.g. "mailto:a@b.com") and dotless hosts.
    if (uri.userInfo.isNotEmpty || !uri.host.contains('.')) return null;
    return uri;
  }

  factory YouthEvent.fromJson(Map<String, dynamic> json) => YouthEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        // A UTC instant. Everything shown to users goes through the mosque's
        // clock (see event_schedule.dart), never the device's time zone.
        dateTime: DateTime.parse(json['date_time'] as String).toUtc(),
        isFree: json['is_free'] as bool? ?? false,
        price: json['price'] as String?,
        attendingCount: (json['attending_count'] as num?)?.toInt() ?? 0,
        category: json['category'] as String,
        imageUrl: json['image_url'] as String?,
        registrationLink: json['registration_link'] as String?,
        recurrence: json['recurrence'] as String? ?? '',
        isPublished: json['is_published'] as bool? ?? false,
        startsAfterPrayer: _prayerKey(json['starts_after_prayer'] as String?),
      );

  static const prayerKeys = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};

  static String? _prayerKey(String? raw) {
    final key = raw?.trim().toLowerCase();
    return prayerKeys.contains(key) ? key : null;
  }
}

class Announcement {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? imageAltText;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imageAltText,
    this.publishedAt,
    required this.createdAt,
  });

  /// Date shown to users: when it was published, else when it was created.
  DateTime get date => publishedAt ?? createdAt;

  bool get isNew => DateTime.now().difference(date).inDays < 7;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrl: json['image_url'] as String?,
        imageAltText: json['image_alt_text'] as String?,
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
