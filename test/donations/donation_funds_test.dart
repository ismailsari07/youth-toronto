import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/core/donations/donation_funds.dart';

/// The live `donation_funds` rows (2026-10-14), plus the hidden holding
/// fund an admin's session can also read.
List<dynamic> liveRows() => jsonDecode(jsonEncode([
      {'slug': 'zekat', 'title': 'Zekât', 'display_order': 1, 'is_active': true},
      {'slug': 'sadaka', 'title': 'Sadaka', 'display_order': 2, 'is_active': true},
      {
        'slug': 'general',
        'title': 'Cami Yardımı',
        'display_order': 3,
        'is_active': true,
      },
      {
        'slug': 'cenaze',
        'title': 'Cenaze Hizmetleri',
        'display_order': 4,
        'is_active': true,
      },
      {
        'slug': 'unassigned',
        'title': 'Atanmamış',
        'display_order': 99,
        'is_active': false,
      },
    ])) as List<dynamic>;

void main() {
  group('DonationFunds.parse', () {
    test('reads the live rows in display order, titles as written', () {
      final funds = DonationFunds.parse(liveRows());
      expect(funds.map((f) => f.slug), ['zekat', 'sadaka', 'general', 'cenaze']);
      expect(funds.first.title, 'Zekât');
    });

    test('sorts by display_order, keeping row order on ties', () {
      final funds = DonationFunds.parse([
        {'slug': 'b', 'title': 'B', 'display_order': 2, 'is_active': true},
        {'slug': 'a', 'title': 'A', 'display_order': 1, 'is_active': true},
        {'slug': 'c', 'title': 'C', 'display_order': 2, 'is_active': true},
        {'slug': 'z', 'title': 'Z', 'is_active': true},
      ]);
      expect(funds.map((f) => f.slug), ['a', 'b', 'c', 'z']);
    });

    test('skips inactive rows even when RLS lets an admin read them', () {
      final funds = DonationFunds.parse([
        {'slug': 'fitre', 'title': 'Fitre', 'display_order': 1, 'is_active': false},
        {'slug': 'zekat', 'title': 'Zekât', 'display_order': 2},
      ]);
      expect(funds, isEmpty);
    });

    test('never offers the holding fund', () {
      final funds = DonationFunds.parse([
        {'slug': 'unassigned', 'title': 'Atanmamış', 'is_active': true},
      ]);
      expect(funds, isEmpty);
    });

    test('skips rows without a usable slug or title', () {
      final funds = DonationFunds.parse([
        {'slug': 'Zekat', 'title': 'Upper case', 'is_active': true},
        {'slug': 'a b', 'title': 'Space', 'is_active': true},
        {'slug': 'x?y=1', 'title': 'Query', 'is_active': true},
        {'slug': 'ok', 'title': '   ', 'is_active': true},
        {'slug': 'ok', 'title': 5, 'is_active': true},
        {'title': 'No slug', 'is_active': true},
        'not a row',
        {'slug': 'good', 'title': '  Trimmed  ', 'is_active': true},
      ]);
      expect(funds, [const DonationFund(slug: 'good', title: 'Trimmed')]);
    });

    test('anything but a list is no funds', () {
      expect(DonationFunds.parse(null), isEmpty);
      expect(DonationFunds.parse({'slug': 'zekat'}), isEmpty);
      expect(DonationFunds.parse('[]'), isEmpty);
    });
  });

  group('DonationFunds.pageUri', () {
    test('uses the panel link when set', () {
      expect(
        DonationFunds.pageUri('https://papemosque.ca/donation').toString(),
        'https://papemosque.ca/donation',
      );
      expect(
        DonationFunds.pageUri('https://example.org/give', fund: 'zekat')
            .toString(),
        'https://example.org/give?fund=zekat',
      );
    });

    test('falls back to the hardcoded page when the link is empty', () {
      expect(
        DonationFunds.pageUri(null).toString(),
        'https://papemosque.ca/donation',
      );
      expect(
        DonationFunds.pageUri(null, fund: 'general').toString(),
        'https://papemosque.ca/donation?fund=general',
      );
    });

    test('keeps query parameters already in the panel link', () {
      final uri = DonationFunds.pageUri(
        'https://papemosque.ca/donation?utm_source=app',
        fund: 'sadaka',
      );
      expect(uri.queryParameters, {'utm_source': 'app', 'fund': 'sadaka'});
      expect(uri.path, '/donation');
    });

    test('a fund parameter in the link is replaced, not repeated', () {
      final uri = DonationFunds.pageUri(
        'https://papemosque.ca/donation?fund=zekat',
        fund: 'cenaze',
      );
      expect(uri.queryParametersAll['fund'], ['cenaze']);
    });
  });
}
