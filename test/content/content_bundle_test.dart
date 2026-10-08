import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/content/content_bundle.dart';

/// The shape `app_content_bundle()` returns (trimmed live data, 2026-10-08),
/// decoded the way the network and the cache decode it.
Map<String, dynamic> liveJson() =>
    jsonDecode(jsonEncode(_live)) as Map<String, dynamic>;

const _live = {
  'version': '2026-10-08T20:43:10.063852+00:00',
  'content': {
    'mosque_info': {
      'name': 'Turkish Islamic Center Canada',
      'name_secondary': 'Pape Camii · Kanada Türk İslam Vakfı',
      'street': '336 Pape Avenue',
      'city': 'Toronto, ON',
      'postal_code': 'M4M 2W7',
      'phone': '647 834 2000',
      'email': 'info@papecami.com',
      'website': 'https://papemosque.ca',
      'hours': [
        {
          'label': {
            'tr': 'Cuma namazı',
            'en': "Jumu'ah",
            'fr': 'Prière du vendredi',
          },
          'value': {'tr': 'Cuma günleri', 'en': 'Fridays', 'fr': 'Le vendredi'},
        },
      ],
    },
    'cemetery': {
      'name': 'Pine Ridge Memorial Gardens',
      'street': '1757 Church St N',
      'city': 'Ajax, ON L1T 4T2',
      'history': {'tr': 'Tarihçe', 'en': 'History', 'fr': 'Histoire'},
    },
    'links': {
      'website': 'https://papemosque.ca',
      'donation': 'https://papemosque.ca/donation',
    },
    'app_config': {
      'min_supported_version': '1.0.0',
      'latest_build': '1.0.0',
      'features': {
        'events': true,
        'announcements': true,
        'burial_service': true,
        'marriage_service': true,
      },
    },
  },
  'services': [
    {
      'id': 'm',
      'kind': 'marriage',
      'icon': 'heart',
      'title': {'tr': 'Evlilik Hizmeti', 'en': 'Marriage service'},
      'summary': {'tr': 'Gizlilik içinde aracılık'},
      'body': null,
    },
    {
      'id': 'b',
      'kind': 'burial',
      'icon': 'leaf',
      'title': {'tr': 'Defin Hizmetleri', 'en': 'Burial services'},
      'body': {'tr': 'Giriş', 'en': 'Intro'},
    },
  ],
  'contacts': [
    {
      'id': 'c1',
      'group': 'burial',
      'name': 'Fatih Sirinogullari',
      'phone': '437 995 9470',
      'email': null,
      'position': {'tr': 'Cenaze ve defin'},
    },
  ],
};

/// Stands in for the bundled defaults.
final defaults = ContentBundle.parse(
  liveJson(),
  fallback: ContentBundle.empty,
  source: ContentSource.defaults,
);

ContentBundle parse(Object? raw, {ContentSource source = ContentSource.live}) =>
    ContentBundle.parse(raw, fallback: defaults, source: source);

Map<String, dynamic> content(Map<String, dynamic> json) =>
    json['content'] as Map<String, dynamic>;

void main() {
  group('parsing a valid bundle', () {
    final b = parse(liveJson());

    test('reads every section', () {
      expect(b.version, '2026-10-08T20:43:10.063852+00:00');
      expect(b.source, ContentSource.live);
      expect(b.mosque.name, 'Turkish Islamic Center Canada');
      expect(b.mosque.nameSecondary, 'Pape Camii · Kanada Türk İslam Vakfı');
      expect(b.mosque.hours.single.value.resolve('en'), 'Fridays');
      expect(b.cemetery.city, 'Ajax, ON L1T 4T2');
      expect(b.links.donation, 'https://papemosque.ca/donation');
      expect(b.config.minSupportedVersion.toString(), '1.0.0');
      expect(b.services.map((s) => s.kind), [
        ServiceKind.marriage,
        ServiceKind.burial,
      ]);
      expect(b.services.first.icon, 'heart');
      expect(b.services.first.body.isEmpty, isTrue);
      expect(b.contactsIn('burial').single.name, 'Fatih Sirinogullari');
      expect(b.contacts.single.email, isNull);
    });

    test('omitted links and no banner stay empty', () {
      expect(b.links.appStore, isNull);
      expect(b.links.instagram, isNull);
      expect(b.banner, isNull);
      expect(b.mosque.lat, isNull);
    });

    test('derives phone and maps links', () {
      expect(b.mosque.phoneUri, 'tel:+16478342000');
      expect(b.contacts.single.phoneUri, 'tel:+14379959470');
      expect(
        b.mosque.mapsUri,
        startsWith('https://www.google.com/maps/search/'),
      );
      expect(
        Uri.parse(b.mosque.mapsUri).queryParameters['query'],
        '336 Pape Avenue, Toronto, ON M4M 2W7',
      );
      expect(urlLabel('https://www.papemosque.ca/'), 'papemosque.ca');
      expect(
        urlLabel('https://papemosque.ca/donation'),
        'papemosque.ca/donation',
      );
    });

    test('coordinates win over the address for maps', () {
      final json = liveJson();
      (content(json)['cemetery'] as Map)
        ..['lat'] = 43.9
        ..['lng'] = -79.0;
      expect(
        Uri.parse(parse(json).cemetery.mapsUri).queryParameters['query'],
        '43.9,-79.0',
      );
    });
  });

  group('missing fields', () {
    test('a required field falls back to the default, field by field', () {
      final json = liveJson();
      (content(json)['mosque_info'] as Map)
        ..remove('phone')
        ..['name'] = 'Renamed';
      final b = parse(json);
      expect(b.mosque.phone, '647 834 2000');
      expect(b.mosque.name, 'Renamed');
    });

    test('a missing optional field is empty, not the default', () {
      final json = liveJson();
      (content(json)['links'] as Map).remove('donation');
      (content(json)['mosque_info'] as Map).remove('name_secondary');
      final b = parse(json);
      expect(b.links.donation, isNull);
      expect(b.links.website, 'https://papemosque.ca');
      expect(b.mosque.nameSecondary, isNull);
    });

    test('missing sections fall back to the defaults', () {
      final json = liveJson()..['content'] = <String, dynamic>{};
      json.remove('services');
      final b = parse(json);
      expect(b.mosque.name, defaults.mosque.name);
      expect(b.cemetery.name, defaults.cemetery.name);
      expect(b.links.donation, defaults.links.donation);
      expect(b.services.length, 2);
    });

    test('an empty list is respected: everything hidden in the panel', () {
      final json = liveJson()
        ..['services'] = []
        ..['contacts'] = [];
      final b = parse(json);
      expect(b.services, isEmpty);
      expect(b.contactsIn('burial'), isEmpty);
    });

    test('a missing feature flag keeps the default', () {
      final json = liveJson();
      ((content(json)['app_config'] as Map)['features'] as Map)
        ..remove('events')
        ..['announcements'] = false;
      final b = parse(json);
      expect(b.features.events, isTrue);
      expect(b.features.announcements, isFalse);
    });
  });

  group('wrong types', () {
    test('null, a list or a string instead of a bundle → the fallback', () {
      for (final raw in [null, [], 'x', 42]) {
        final b = parse(raw);
        expect(b.mosque.name, defaults.mosque.name);
        expect(b.services.length, 2);
      }
    });

    test('wrong field types fall back or drop, never throw', () {
      final json = liveJson();
      content(json)
        ..['cemetery'] = 'oops'
        ..['links'] = {
          'website': 42,
          'donation': 'http://insecure.example',
          'youtube': 'not a url',
        };
      (content(json)['mosque_info'] as Map)
        ..['phone'] = 6478342000
        ..['hours'] = 'all day'
        ..['lat'] = '43.6';
      json['services'] = [
        'nonsense',
        {
          'id': 'x',
          'kind': 'party',
          'title': {'tr': 'Kutlama'},
        },
        {'id': 'y', 'kind': 'info', 'title': 'no i18n'},
        {
          'id': 'z',
          'kind': 'info',
          'title': {'tr': 'Kuran kursu'},
          'icon': 7,
        },
      ];
      json['contacts'] = [
        {'id': 'c', 'group': 'burial', 'name': 'No phone'},
        null,
      ];
      final b = parse(json);
      expect(b.cemetery.name, defaults.cemetery.name);
      expect(b.links.website, isNull);
      expect(b.links.donation, isNull);
      expect(b.links.youtube, isNull);
      expect(b.mosque.phone, '647 834 2000');
      expect(b.mosque.hours.length, defaults.mosque.hours.length);
      expect(b.mosque.lat, isNull);
      expect(b.services.single.id, 'z');
      expect(b.services.single.icon, 'info');
      expect(b.contacts, isEmpty);
    });

    test('blank strings count as missing', () {
      final json = liveJson();
      (content(json)['mosque_info'] as Map)['email'] = '   ';
      expect(parse(json).mosque.email, 'info@papecami.com');
    });

    test('hours rows without both label and value are dropped', () {
      final json = liveJson();
      (content(json)['mosque_info'] as Map)['hours'] = [
        {
          'label': {'tr': 'Ofis'},
        },
        42,
        {
          'label': {'en': 'Office'},
          'value': {'en': 'Call'},
        },
      ];
      expect(parse(json).mosque.hours.single.label.resolve('tr'), 'Office');
    });
  });

  group('language fallback', () {
    const all = I18n({'tr': 'Merhaba', 'en': 'Hello', 'fr': 'Bonjour'});
    const noFr = I18n({'tr': 'Merhaba', 'en': 'Hello'});
    const trOnly = I18n({'tr': 'Merhaba'});

    test('the chosen language first', () {
      expect(all.resolve('fr'), 'Bonjour');
      expect(all.resolve('tr'), 'Merhaba');
      expect(all.resolve('en_CA'), 'Hello');
    });

    test('then English, then Turkish', () {
      expect(noFr.resolve('fr'), 'Hello');
      expect(trOnly.resolve('fr'), 'Merhaba');
      expect(trOnly.resolve('en'), 'Merhaba');
    });

    test('empty strings and other keys are ignored', () {
      final t = I18n.parse({'fr': '  ', 'en': 'Hello', 'de': 'Hallo', 'tr': 5});
      expect(t.resolve('fr'), 'Hello');
      expect(t.resolve('de'), 'Hello');
      expect(I18n.parse(null).resolve('tr'), '');
    });
  });

  group('version comparison', () {
    SemVer v(String s) => SemVer.tryParse(s)!;

    test('compares numerically, part by part', () {
      expect(v('1.0.1').compareTo(v('1.0.0')), greaterThan(0));
      expect(v('1.0.10').compareTo(v('1.0.9')), greaterThan(0));
      expect(v('1.10.0').compareTo(v('1.9.9')), greaterThan(0));
      expect(v('2.0.0').compareTo(v('1.99.99')), greaterThan(0));
      expect(v('1.2.3').compareTo(v('1.2.3')), 0);
    });

    test('ignores build and pre-release suffixes', () {
      expect(v('1.0.1+7').toString(), '1.0.1');
      expect(v(' 1.0.1-beta ').toString(), '1.0.1');
    });

    test('rejects anything that is not x.y.z', () {
      for (final s in [
        '1.0',
        '1',
        'v1.0.0',
        '1.0.0.0',
        '',
        'a.b.c',
        null,
        100,
      ]) {
        expect(SemVer.tryParse(s), isNull, reason: '$s');
      }
    });
  });

  group('update required', () {
    Map<String, dynamic> withConfig(String min, {String? appStore}) {
      final json = liveJson();
      (content(json)['app_config'] as Map)['min_supported_version'] = min;
      if (appStore != null) {
        (content(json)['links'] as Map)['app_store'] = appStore;
      }
      return json;
    }

    const store = 'https://apps.apple.com/app/id123';

    test('below the minimum with a store link: blocked', () {
      expect(
        parse(withConfig('1.0.1', appStore: store)).requiresUpdate('1.0.0'),
        isTrue,
      );
      expect(
        parse(
          withConfig('1.0.1', appStore: store),
          source: ContentSource.cache,
        ).requiresUpdate('1.0.0'),
        isTrue,
      );
    });

    test('at or above the minimum: not blocked', () {
      final b = parse(withConfig('1.0.1', appStore: store));
      expect(b.requiresUpdate('1.0.1'), isFalse);
      expect(b.requiresUpdate('1.1.0'), isFalse);
    });

    test(
      'never blocks on the defaults, without a store link, or on bad versions',
      () {
        expect(
          parse(
            withConfig('9.0.0', appStore: store),
            source: ContentSource.defaults,
          ).requiresUpdate('1.0.0'),
          isFalse,
        );
        expect(parse(withConfig('9.0.0')).requiresUpdate('1.0.0'), isFalse);
        expect(
          parse(withConfig('nine', appStore: store)).requiresUpdate('1.0.0'),
          isFalse,
        );
        expect(
          parse(withConfig('9.0.0', appStore: store)).requiresUpdate('unknown'),
          isFalse,
        );
      },
    );
  });

  group('banner', () {
    final now = DateTime.utc(2026, 10, 8, 12);

    ContentBundle withBanner(Object? banner) {
      final json = liveJson();
      content(json)['app_banner'] = banner;
      return parse(json);
    }

    Map<String, dynamic> banner({
      bool enabled = true,
      Object? endsAt,
      Object? tone = 'warning',
      Object? text = const {'tr': 'Cuma namazı 13:30\'da'},
    }) => {'enabled': enabled, 'tone': tone, 'text': text, 'ends_at': endsAt};

    test('enabled without an end: active', () {
      final b = withBanner(banner()).activeBanner(now);
      expect(b, isNotNull);
      expect(b!.tone, BannerTone.warning);
      expect(b.text.resolve('en'), 'Cuma namazı 13:30\'da');
    });

    test('before ends_at: active; at or after: expired', () {
      expect(
        withBanner(
          banner(endsAt: '2026-10-09T03:59:59.999+00:00'),
        ).activeBanner(now),
        isNotNull,
      );
      expect(
        withBanner(banner(endsAt: '2026-10-08T12:00:00Z')).activeBanner(now),
        isNull,
      );
      expect(
        withBanner(banner(endsAt: '2026-10-07T03:59:59Z')).activeBanner(now),
        isNull,
      );
    });

    test('disabled (an admin still receives it): hidden', () {
      expect(withBanner(banner(enabled: false)).activeBanner(now), isNull);
    });

    test('malformed: hidden, never a crash', () {
      expect(withBanner(banner(endsAt: 'next week')).activeBanner(now), isNull);
      expect(withBanner(banner(text: {})).activeBanner(now), isNull);
      expect(withBanner(banner(text: 'plain')).activeBanner(now), isNull);
      expect(
        withBanner({
          'enabled': 'yes',
          'text': {'tr': 'x'},
        }).activeBanner(now),
        isNull,
      );
      expect(withBanner('on').activeBanner(now), isNull);
      expect(withBanner(null).activeBanner(now), isNull);
    });

    test('an unknown tone shows as info', () {
      expect(
        withBanner(banner(tone: 'party')).activeBanner(now)!.tone,
        BannerTone.info,
      );
    });
  });

  group('feature toggles', () {
    ContentBundle withFeatures(Map<String, Object?> features) {
      final json = liveJson();
      (content(json)['app_config'] as Map)['features'] = {
        'events': true,
        'announcements': true,
        'burial_service': true,
        'marriage_service': true,
        ...features,
      };
      return parse(json);
    }

    test('all on: everything shows', () {
      final b = withFeatures({});
      expect(b.visibleServices.map((s) => s.kind), [
        ServiceKind.marriage,
        ServiceKind.burial,
      ]);
      expect(b.showEvents && b.showAnnouncements && b.showCommunity, isTrue);
    });

    test('services off: their rows go, info services stay', () {
      final json = liveJson();
      (json['services'] as List).add({
        'id': 'q',
        'kind': 'info',
        'icon': 'book',
        'title': {'tr': 'Kuran kursu'},
      });
      (content(json)['app_config'] as Map)['features'] = {
        'marriage_service': false,
        'burial_service': false,
      };
      expect(parse(json).visibleServices.map((s) => s.id), ['q']);
    });

    test('events or announcements off: that part goes', () {
      final noEvents = withFeatures({'events': false});
      expect(noEvents.showEvents, isFalse);
      expect(noEvents.showCommunity, isTrue);
      final neither = withFeatures({'events': false, 'announcements': false});
      expect(neither.showCommunity, isFalse);
    });

    test('a non-boolean flag keeps the default (on)', () {
      expect(withFeatures({'events': 'false'}).showEvents, isTrue);
    });
  });
}
