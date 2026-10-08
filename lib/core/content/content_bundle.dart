/// The content the admin panel edits, as `app_content_bundle()` returns it:
/// mosque info, cemetery, links, the emergency banner, the app config, the
/// visible services in order and the visible contacts.
///
/// Parsing never throws. A required field that is missing or of the wrong
/// type takes the fallback bundle's value (the bundled defaults); an optional
/// one (links, a secondary name, coordinates, an email) is simply absent,
/// because the database omits empty keys rather than sending nulls.
library;

/// Where a bundle came from. Only fetched or cached content may block the app
/// behind the update screen; the bundled defaults never do.
enum ContentSource { live, cache, defaults }

/// A text in the app's three languages, `{tr, en, fr}`.
class I18n {
  const I18n(this._values);

  static const empty = I18n({});

  final Map<String, String> _values;

  /// Keeps only non-empty strings under `tr`, `en` and `fr`.
  factory I18n.parse(Object? raw) {
    if (raw is! Map) return empty;
    final values = <String, String>{};
    for (final lang in const ['tr', 'en', 'fr']) {
      final text = _str(raw[lang]);
      if (text != null) values[lang] = text;
    }
    return I18n(values);
  }

  bool get isEmpty => _values.isEmpty;

  /// The chosen language, then English, then Turkish; '' when all are empty.
  /// [lang] may be a locale name such as `en_CA`.
  String resolve(String lang) {
    final code = lang.split(RegExp('[_-]')).first.toLowerCase();
    return _values[code] ?? _values['en'] ?? _values['tr'] ?? '';
  }
}

class OpeningHours {
  const OpeningHours({required this.label, required this.value});

  final I18n label;
  final I18n value;
}

class MosqueInfo {
  const MosqueInfo({
    required this.name,
    this.nameSecondary,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.phone,
    required this.email,
    this.website,
    this.lat,
    this.lng,
    required this.hours,
  });

  final String name;
  final String? nameSecondary;
  final String street;
  final String city;
  final String postalCode;
  final String phone;
  final String email;
  final String? website;
  final double? lat;
  final double? lng;
  final List<OpeningHours> hours;

  static const empty = MosqueInfo(
    name: '',
    street: '',
    city: '',
    postalCode: '',
    phone: '',
    email: '',
    hours: [],
  );

  factory MosqueInfo.parse(Object? raw, MosqueInfo fallback) {
    if (raw is! Map) return fallback;
    final hours = raw['hours'];
    return MosqueInfo(
      name: _str(raw['name']) ?? fallback.name,
      nameSecondary: _str(raw['name_secondary']),
      street: _str(raw['street']) ?? fallback.street,
      city: _str(raw['city']) ?? fallback.city,
      postalCode: _str(raw['postal_code']) ?? fallback.postalCode,
      phone: _str(raw['phone']) ?? fallback.phone,
      email: _str(raw['email']) ?? fallback.email,
      website: _url(raw['website']),
      lat: _num(raw['lat']),
      lng: _num(raw['lng']),
      hours: hours is List
          ? [
              for (final h in hours)
                if (h is Map)
                  OpeningHours(
                    label: I18n.parse(h['label']),
                    value: I18n.parse(h['value']),
                  ),
            ].where((h) => !h.label.isEmpty && !h.value.isEmpty).toList()
          : fallback.hours,
    );
  }

  String get addressLine => '$street, $city $postalCode';
  String get phoneUri => telUri(phone);
  String get mapsUri => mapsSearchUri(lat, lng, '$street, $city $postalCode');
}

class Cemetery {
  const Cemetery({
    required this.name,
    required this.street,
    required this.city,
    this.lat,
    this.lng,
    this.history = I18n.empty,
  });

  final String name;
  final String street;
  final String city;
  final double? lat;
  final double? lng;
  final I18n history;

  static const empty = Cemetery(name: '', street: '', city: '');

  factory Cemetery.parse(Object? raw, Cemetery fallback) {
    if (raw is! Map) return fallback;
    return Cemetery(
      name: _str(raw['name']) ?? fallback.name,
      street: _str(raw['street']) ?? fallback.street,
      city: _str(raw['city']) ?? fallback.city,
      lat: _num(raw['lat']),
      lng: _num(raw['lng']),
      history: I18n.parse(raw['history']),
    );
  }

  String get mapsUri => mapsSearchUri(lat, lng, '$name, $street, $city');
}

/// Every link is optional; an empty one is hidden.
class Links {
  const Links({
    this.website,
    this.donation,
    this.appStore,
    this.instagram,
    this.facebook,
    this.youtube,
    this.whatsapp,
  });

  final String? website;
  final String? donation;
  final String? appStore;
  final String? instagram;
  final String? facebook;
  final String? youtube;
  final String? whatsapp;

  static const empty = Links();

  factory Links.parse(Object? raw, Links fallback) {
    if (raw is! Map) return fallback;
    return Links(
      website: _url(raw['website']),
      donation: _url(raw['donation']),
      appStore: _url(raw['app_store']),
      instagram: _url(raw['instagram']),
      facebook: _url(raw['facebook']),
      youtube: _url(raw['youtube']),
      whatsapp: _url(raw['whatsapp']),
    );
  }
}

enum BannerTone { info, warning, urgent }

class AppBanner {
  const AppBanner({
    required this.enabled,
    required this.tone,
    required this.text,
    this.endsAt,
    this.endsAtInvalid = false,
  });

  final bool enabled;
  final BannerTone tone;
  final I18n text;
  final DateTime? endsAt;

  /// `ends_at` was there but unreadable: the banner is treated as ended.
  final bool endsAtInvalid;

  /// Null when the section is missing or not an object: no banner. Never
  /// falls back to the defaults, which don't carry one.
  static AppBanner? parse(Object? raw) {
    if (raw is! Map) return null;
    final endsRaw = raw['ends_at'];
    final endsAt = endsRaw is String ? DateTime.tryParse(endsRaw) : null;
    return AppBanner(
      enabled: raw['enabled'] == true,
      tone: BannerTone.values.asNameMap()[raw['tone']] ?? BannerTone.info,
      text: I18n.parse(raw['text']),
      endsAt: endsAt,
      endsAtInvalid: endsRaw != null && endsAt == null,
    );
  }

  /// The app decides for itself: an admin signed into the app receives the
  /// banner even while it's off, and a cached copy must expire offline.
  bool isActive(DateTime now) =>
      enabled &&
      !text.isEmpty &&
      !endsAtInvalid &&
      (endsAt == null || now.isBefore(endsAt!));
}

class AppFeatures {
  const AppFeatures({
    this.marriageService = true,
    this.burialService = true,
    this.events = true,
    this.announcements = true,
  });

  final bool marriageService;
  final bool burialService;
  final bool events;
  final bool announcements;

  factory AppFeatures.parse(Object? raw, AppFeatures fallback) {
    if (raw is! Map) return fallback;
    bool flag(String key, bool otherwise) {
      final v = raw[key];
      return v is bool ? v : otherwise;
    }

    return AppFeatures(
      marriageService: flag('marriage_service', fallback.marriageService),
      burialService: flag('burial_service', fallback.burialService),
      events: flag('events', fallback.events),
      announcements: flag('announcements', fallback.announcements),
    );
  }
}

class AppConfig {
  const AppConfig({
    this.minSupportedVersion,
    this.latestBuild,
    this.features = const AppFeatures(),
  });

  /// Null when missing or not `x.y.z`: then nothing is ever blocked.
  final SemVer? minSupportedVersion;
  final SemVer? latestBuild;
  final AppFeatures features;

  static const empty = AppConfig();

  factory AppConfig.parse(Object? raw, AppConfig fallback) {
    if (raw is! Map) return fallback;
    return AppConfig(
      minSupportedVersion: SemVer.tryParse(raw['min_supported_version']),
      latestBuild: SemVer.tryParse(raw['latest_build']),
      features: AppFeatures.parse(raw['features'], fallback.features),
    );
  }
}

enum ServiceKind { marriage, burial, info }

class Service {
  const Service({
    required this.id,
    required this.kind,
    required this.title,
    this.summary = I18n.empty,
    this.body = I18n.empty,
    required this.icon,
  });

  final String id;
  final ServiceKind kind;
  final I18n title;
  final I18n summary;
  final I18n body;

  /// One of the panel's icon names: heart, leaf, book, moon, users,
  /// calendar, mosque, info.
  final String icon;

  /// Null when the item can't be shown: no id, an unknown kind, or no title.
  static Service? parse(Object? raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    final kind = ServiceKind.values.asNameMap()[raw['kind']];
    final title = I18n.parse(raw['title']);
    if (id == null || kind == null || title.isEmpty) return null;
    return Service(
      id: id,
      kind: kind,
      title: title,
      summary: I18n.parse(raw['summary']),
      body: I18n.parse(raw['body']),
      icon: _str(raw['icon']) ?? 'info',
    );
  }
}

class Contact {
  const Contact({
    required this.id,
    required this.group,
    required this.name,
    required this.phone,
    this.email,
    this.position = I18n.empty,
  });

  final String id;
  final String group;
  final String name;
  final String phone;
  final String? email;
  final I18n position;

  /// Null without an id, a group, a name or a phone.
  static Contact? parse(Object? raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    final group = _str(raw['group']);
    final name = _str(raw['name']);
    final phone = _str(raw['phone']);
    if (id == null || group == null || name == null || phone == null) {
      return null;
    }
    return Contact(
      id: id,
      group: group,
      name: name,
      phone: phone,
      email: _str(raw['email']),
      position: I18n.parse(raw['position']),
    );
  }

  String get phoneUri => telUri(phone);
}

class ContentBundle {
  const ContentBundle({
    this.version,
    required this.source,
    required this.mosque,
    required this.cemetery,
    required this.links,
    this.banner,
    required this.config,
    required this.services,
    required this.contacts,
  });

  final String? version;
  final ContentSource source;
  final MosqueInfo mosque;
  final Cemetery cemetery;
  final Links links;
  final AppBanner? banner;
  final AppConfig config;
  final List<Service> services;
  final List<Contact> contacts;

  /// Only used if even the bundled defaults can't be read; a test keeps the
  /// asset complete so this never shows.
  static const empty = ContentBundle(
    source: ContentSource.defaults,
    mosque: MosqueInfo.empty,
    cemetery: Cemetery.empty,
    links: Links.empty,
    config: AppConfig.empty,
    services: [],
    contacts: [],
  );

  /// Never throws. [fallback] fills required fields that are missing or
  /// malformed, and whole sections that aren't objects or lists.
  factory ContentBundle.parse(
    Object? raw, {
    required ContentBundle fallback,
    required ContentSource source,
  }) {
    if (raw is! Map) return fallback;
    final content = raw['content'] is Map ? raw['content'] as Map : const {};
    final services = raw['services'];
    final contacts = raw['contacts'];
    return ContentBundle(
      version: _str(raw['version']),
      source: source,
      mosque: MosqueInfo.parse(content['mosque_info'], fallback.mosque),
      cemetery: Cemetery.parse(content['cemetery'], fallback.cemetery),
      links: Links.parse(content['links'], fallback.links),
      banner: AppBanner.parse(content['app_banner']),
      config: AppConfig.parse(content['app_config'], fallback.config),
      services: services is List
          ? services.map(Service.parse).whereType<Service>().toList()
          : fallback.services,
      contacts: contacts is List
          ? contacts.map(Contact.parse).whereType<Contact>().toList()
          : fallback.contacts,
    );
  }

  AppFeatures get features => config.features;

  Service? serviceOf(ServiceKind kind) =>
      services.where((s) => s.kind == kind).firstOrNull;

  /// The Mosque services rows: built-in services only while their toggle is
  /// on, in the panel's order.
  List<Service> get visibleServices => [
    for (final s in services)
      if (switch (s.kind) {
        ServiceKind.marriage => features.marriageService,
        ServiceKind.burial => features.burialService,
        ServiceKind.info => true,
      })
        s,
  ];

  List<Contact> contactsIn(String group) =>
      contacts.where((c) => c.group == group).toList();

  bool get showEvents => features.events;
  bool get showAnnouncements => features.announcements;
  bool get showCommunity => features.events || features.announcements;

  /// The banner to show at [now], or null.
  AppBanner? activeBanner(DateTime now) =>
      banner != null && banner!.isActive(now) ? banner : null;

  /// True when this app [appVersion] must update before it can be used.
  /// Never blocks on the bundled defaults, without an App Store link, or when
  /// either version can't be read.
  bool requiresUpdate(String appVersion) {
    if (source == ContentSource.defaults || links.appStore == null) {
      return false;
    }
    final min = config.minSupportedVersion;
    final current = SemVer.tryParse(appVersion);
    if (min == null || current == null) return false;
    return current.compareTo(min) < 0;
  }
}

/// `major.minor.patch`, compared numerically (1.0.10 > 1.0.9). A `+build`
/// or `-pre` suffix is ignored.
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^(\d{1,9})\.(\d{1,9})\.(\d{1,9})$');

  static SemVer? tryParse(Object? raw) {
    if (raw is! String) return null;
    final core = raw.trim().split(RegExp('[+-]')).first;
    final m = _pattern.firstMatch(core);
    if (m == null) return null;
    return SemVer(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

/// `647 834 2000` → `tel:+16478342000`; North American numbers get +1.
String telUri(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) return 'tel:+1$digits';
  if (digits.length == 11 && digits.startsWith('1')) return 'tel:+$digits';
  return 'tel:$digits';
}

/// Google Maps search: the coordinates when set, else the address.
String mapsSearchUri(double? lat, double? lng, String address) {
  final query = lat != null && lng != null ? '$lat,$lng' : address;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  }).toString();
}

/// `https://www.papemosque.ca/` → `papemosque.ca`, for display.
String urlLabel(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;
  final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
  final path = uri.path == '/' ? '' : uri.path;
  return '$host$path';
}

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// Only https URLs, as the database allows.
String? _url(Object? v) {
  final s = _str(v);
  if (s == null) return null;
  final uri = Uri.tryParse(s);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? s : null;
}
