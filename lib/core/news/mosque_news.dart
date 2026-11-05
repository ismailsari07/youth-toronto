import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One photo of a news item, as the panel stores it. [contain]: the whole
/// photo over a blurred, darkened copy of itself; otherwise a 4:5 crop.
@immutable
class NewsPhoto {
  const NewsPhoto({required this.url, this.contain = false, this.altText});

  final String url;
  final bool contain;
  final String? altText;

  static final _url = RegExp(
    r'^https://[a-z0-9-]+\.supabase\.co/storage/v1/object/public/news-images/'
    r'[0-9a-f-]{36}/[0-9a-f-]{36}\.jpg$',
  );

  /// Null for anything that isn't a photo in the news bucket.
  static NewsPhoto? parse(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'];
    if (url is! String || !_url.hasMatch(url)) return null;
    final alt = raw['alt'];
    return NewsPhoto(
      url: url,
      contain: raw['fit'] == 'contain',
      altText: alt is String && alt.trim().isNotEmpty ? alt.trim() : null,
    );
  }
}

/// "Camimizden Haberler": a notable past happening, in one language. A news
/// item never expires. (Named apart from [newsProvider], which means
/// announcements.)
@immutable
class MosqueNews {
  const MosqueNews({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.cover,
    this.photos = const [],
    this.featured = false,
  });

  final String id;
  final String title;
  final String body;

  /// The day it happened, on the mosque's calendar (a date, no time).
  final DateTime date;
  final NewsPhoto cover;
  final List<NewsPhoto> photos;
  final bool featured;

  /// The gallery's slides: the cover, then the rest.
  List<NewsPhoto> get slides => [cover, ...photos];

  /// Null without a title, a day or a usable cover (publishing requires them).
  static MosqueNews? parse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    final body = raw['body'];
    final day = raw['news_date'];
    final cover = NewsPhoto.parse(raw['cover']);
    if (id is! String || title is! String || title.trim().isEmpty) return null;
    if (body is! String || day is! String || cover == null) return null;
    final date = DateTime.tryParse(day);
    if (date == null) return null;
    final photos = raw['photos'];
    return MosqueNews(
      id: id,
      title: title.trim(),
      body: body.trim(),
      date: DateTime.utc(date.year, date.month, date.day),
      cover: cover,
      photos: photos is List
          ? photos.map(NewsPhoto.parse).whereType<NewsPhoto>().toList()
          : const [],
      featured: raw['is_featured'] == true,
    );
  }
}

/// Rows arrive newest first; a row that can't be read is skipped.
List<MosqueNews> parseNewsList(Object? raw) => raw is List
    ? raw.map(MosqueNews.parse).whereType<MosqueNews>().toList()
    : const [];

/// The home rail's order: featured first, then the rest, each newest first.
List<MosqueNews> newsRailOrder(List<MosqueNews> items) => [
  ...items.where((n) => n.featured),
  ...items.where((n) => !n.featured),
];

abstract final class MosqueNewsService {
  static const _cacheKey = 'mosque_news_v1';
  static const _columns =
      'id, title, body, news_date, cover, photos, is_featured, published_at';

  /// The published list, saved as the last good one. Filtered here too:
  /// admins signed into the app can read drafts. Throws on network errors.
  static Future<List<MosqueNews>> fetch() async {
    final raw = await Supabase.instance.client
        .from('mosque_news')
        .select(_columns)
        .eq('status', 'published')
        .order('news_date', ascending: false)
        .order('published_at', ascending: false, nullsFirst: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(raw));
    } catch (_) {
      // Shown now, fetched again next launch.
    }
    return parseNewsList(raw);
  }

  /// The last list fetched, or none. Never throws.
  static Future<List<MosqueNews>> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) return parseNewsList(jsonDecode(cached));
    } catch (_) {
      debugPrint('Cached news could not be read');
    }
    return const [];
  }

  /// One item, for a tapped notification; null when it's gone or unpublished.
  static Future<MosqueNews?> fetchOne(String id) async {
    final row = await Supabase.instance.client
        .from('mosque_news')
        .select(_columns)
        .eq('id', id)
        .eq('status', 'published')
        .maybeSingle();
    return row == null ? null : MosqueNews.parse(row);
  }
}
