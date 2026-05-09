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
  });

  factory YouthEvent.fromJson(Map<String, dynamic> json) => YouthEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        dateTime: DateTime.parse(json['date_time'] as String),
        isFree: json['is_free'] as bool? ?? false,
        price: json['price'] as String?,
        attendingCount: (json['attending_count'] as num?)?.toInt() ?? 0,
        category: json['category'] as String,
        imageUrl: json['image_url'] as String?,
        registrationLink: json['registration_link'] as String?,
        recurrence: json['recurrence'] as String? ?? '',
        isPublished: json['is_published'] as bool? ?? false,
      );
}

class NewsItem {
  final String id;
  final String title;
  final String teaser;
  final String body;
  final String? imageUrl;
  final bool isNew;
  final bool isPublished;
  final DateTime createdAt;

  const NewsItem({
    required this.id,
    required this.title,
    required this.teaser,
    required this.body,
    this.imageUrl,
    required this.isNew,
    required this.isPublished,
    required this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] as String,
        title: json['title'] as String,
        teaser: json['teaser'] as String,
        body: json['body'] as String,
        imageUrl: json['image_url'] as String?,
        isNew: json['is_new'] as bool? ?? false,
        isPublished: json['is_published'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
