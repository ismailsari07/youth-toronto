import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../content/content_bundle.dart';

/// One fund from the `donation_funds` table. [titles] is the panel's
/// `title_i18n`; [title] is the plain column (a copy of the Turkish title),
/// which also serves lists cached before translations existed.
@immutable
class DonationFund {
  const DonationFund({
    required this.slug,
    required this.title,
    this.titles = I18n.empty,
  });

  final String slug;
  final String title;
  final I18n titles;

  /// The title in [lang], then English, then Turkish.
  String titleIn(String lang) {
    final text = titles.resolve(lang);
    return text.isEmpty ? title : text;
  }

  @override
  bool operator ==(Object other) =>
      other is DonationFund &&
      other.slug == slug &&
      other.title == title &&
      other.titleIn('tr') == titleIn('tr') &&
      other.titleIn('en') == titleIn('en') &&
      other.titleIn('fr') == titleIn('fr');

  @override
  int get hashCode =>
      Object.hash(slug, title, titleIn('tr'), titleIn('en'), titleIn('fr'));
}

/// The donation funds the app offers. Donations themselves happen on the
/// website, in Safari: the app never shows a form or a web view (Apple's
/// rule for donations).
abstract final class DonationFunds {
  static const _cacheKey = 'donation_funds_v1';

  /// Used when the panel's `links.donation` is empty.
  static const fallbackBase = 'https://papemosque.ca/donation';

  /// The website's holding fund for unmatched payments; never offered.
  static const _holdingFund = 'unassigned';

  static final _slug = RegExp(r'^[a-z0-9_-]{1,64}$');

  /// Active funds in `display_order`, read defensively: a row without a
  /// usable slug or title is skipped. Signed-in admins can read inactive
  /// rows too, so `is_active` is checked here rather than trusted to RLS.
  static List<DonationFund> parse(Object? raw) {
    if (raw is! List) return const [];
    final rows = <(int, int, DonationFund)>[];
    for (final (i, row) in raw.indexed) {
      if (row is! Map || row['is_active'] != true) continue;
      final slug = row['slug'];
      final title = row['title'];
      if (slug is! String || !_slug.hasMatch(slug) || slug == _holdingFund) {
        continue;
      }
      if (title is! String || title.trim().isEmpty) continue;
      final titles = I18n.parse(row['title_i18n']);
      final order = row['display_order'];
      rows.add((
        order is num ? order.toInt() : 1 << 30,
        i,
        DonationFund(slug: slug, title: title.trim(), titles: titles),
      ));
    }
    rows.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    return [for (final r in rows) r.$3];
  }

  /// The last list fetched, or none. Never throws.
  static Future<List<DonationFund>> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) return parse(jsonDecode(cached));
    } catch (_) {
      debugPrint('Cached donation funds could not be read');
    }
    return const [];
  }

  /// Fetches the active funds and saves them as the last good list. Throws
  /// on network errors.
  static Future<List<DonationFund>> fetch() async {
    final raw = await Supabase.instance.client
        .from('donation_funds')
        .select('slug, title, title_i18n, display_order, is_active')
        .eq('is_active', true)
        .order('display_order');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(raw));
    } catch (_) {
      // Shown now, fetched again next launch.
    }
    return parse(raw);
  }

  /// The donation page: the panel's `links.donation` when set, else
  /// [fallbackBase]; with `?fund=<slug>` for one fund. Query parameters
  /// already in the panel's link are kept.
  static Uri pageUri(String? base, {String? fund}) {
    final uri = Uri.parse(base ?? fallbackBase);
    if (fund == null) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'fund': fund},
    );
  }
}
