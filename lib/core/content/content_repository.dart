import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_bundle.dart';

/// Where the content comes from: the network, the last good bundle saved on
/// the device, and the defaults shipped in the app, in that order.
abstract final class ContentRepository {
  static const defaultsAsset = 'assets/content_defaults.json';
  static const _cacheKey = 'content_bundle_v1';

  static ContentBundle _defaults = ContentBundle.empty;

  /// The bundled defaults, once [loadLocal] has read them.
  static ContentBundle get defaults => _defaults;

  /// The cached bundle, else the bundled defaults. Local only, so main()
  /// can await it before the first frame. Never throws.
  static Future<ContentBundle> loadLocal() async {
    try {
      final raw = await rootBundle.loadString(defaultsAsset);
      _defaults = ContentBundle.parse(
        jsonDecode(raw),
        fallback: ContentBundle.empty,
        source: ContentSource.defaults,
      );
    } catch (_) {
      debugPrint('Content defaults could not be read');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        return ContentBundle.parse(
          jsonDecode(cached),
          fallback: _defaults,
          source: ContentSource.cache,
        );
      }
    } catch (_) {
      debugPrint('Cached content could not be read');
    }
    return _defaults;
  }

  /// Fetches `app_content_bundle()` and saves it as the last good bundle.
  /// Null when the answer isn't a bundle; throws on network errors.
  static Future<ContentBundle?> fetch() async {
    final raw = await Supabase.instance.client.rpc('app_content_bundle');
    if (raw is! Map || raw['content'] is! Map) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(raw));
    } catch (_) {
      // Shown now, fetched again next launch.
    }
    return ContentBundle.parse(
      raw,
      fallback: _defaults,
      source: ContentSource.live,
    );
  }
}
