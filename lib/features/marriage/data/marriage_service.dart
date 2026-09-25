import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/prayer_service.dart';
import '../../../l10n/app_strings.dart';
import 'document_check.dart';
import 'document_upload.dart';
import 'marriage_application.dart';

/// A failure with a fixed, user-facing [message]. It never carries a path,
/// URL, row or server error text, so it is safe to show and safe if logged.
class MarriageException implements Exception {
  const MarriageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Spec §8a, client side. Row-level security and the storage policies are
/// the real guarantee; this class only ever asks for the caller's own data.
///
/// Nothing here logs. Errors are caught and replaced by [MarriageException].
abstract final class MarriageService {
  static const bucket = 'marriage-documents';

  /// Spec §8a: signed links live for 60 seconds and are made per tap.
  static const signedUrlSeconds = 60;

  static SupabaseClient get _client => Supabase.instance.client;
  static StorageFileApi get _storage => _client.storage.from(bucket);

  static String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) throw const MarriageException(AppStrings.uploadFailed);
    return user.id;
  }

  /// The caller's row, or null if they have not applied.
  static Future<MarriageApplication?> fetchOwn() async {
    final row = await _client
        .from('marriage_applications')
        .select(MarriageApplication.columns)
        .eq('user_id', _uid)
        .maybeSingle();
    return row == null ? null : MarriageApplication.fromRow(row);
  }

  /// `{user_id}/{random uuid}.{ext}`. The original file name never appears.
  static String newObjectPath(String userId, DocumentKind kind) =>
      '$userId/${uuidV4()}.${kind.extension}';

  /// Starts uploading [document] to a fresh path in the caller's folder.
  /// Pair with [commit] on success, or [discard] on failure or cancel.
  static Future<({DocumentUpload upload, String path})> startUpload(
    AcceptedDocument document,
  ) async {
    final uid = _uid;
    final token = await _accessToken();
    final path = newObjectPath(uid, document.kind);
    final upload = DocumentUpload.start(
      endpoint: Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$path'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        'apikey': supabaseAnonKey,
      },
      bytes: document.bytes,
      contentType: document.kind.mimeType,
    );
    return (upload: upload, path: path);
  }

  /// Records a finished upload at [path]. A first submission inserts the
  /// row; a replacement swaps the row to the new file. Only after the row
  /// points at the new file is anything else in the folder deleted — so the
  /// old document survives any failure before this point. If the row can't
  /// be written, the new object is removed and the old one is untouched.
  static Future<void> commit(String path, AcceptedDocument document) async {
    final uid = _uid;
    final values = {
      'file_path': path,
      'mime_type': document.kind.mimeType,
      'size_bytes': document.size,
    };
    try {
      final existing = await _client
          .from('marriage_applications')
          .select('user_id')
          .eq('user_id', uid)
          .maybeSingle();
      if (existing == null) {
        await _client
            .from('marriage_applications')
            .insert({'user_id': uid, ...values});
      } else {
        await _client
            .from('marriage_applications')
            .update(values)
            .eq('user_id', uid);
      }
    } catch (_) {
      await discard(path);
      throw const MarriageException(AppStrings.uploadFailed);
    }
    // The old object and any leftovers from cancelled uploads. Best effort:
    // whatever survives is swept next time, on withdraw, or on account
    // deletion.
    try {
      await _sweep(uid, keep: path);
    } catch (_) {}
  }

  /// Removes a partial or unwanted upload. Never throws.
  static Future<void> discard(String path) async {
    try {
      await _storage.remove([path]);
    } catch (_) {
      // Left for the next sweep.
    }
  }

  /// Withdraw: delete every object in the caller's folder first, then the
  /// row. If the files can't be deleted, the row is kept so the member still
  /// sees their application and can retry.
  static Future<void> withdraw() async {
    final uid = _uid;
    try {
      await _sweep(uid);
      await _client.from('marriage_applications').delete().eq('user_id', uid);
    } catch (_) {
      throw const MarriageException(AppStrings.withdrawFailed);
    }
  }

  /// The caller's document as bytes, fetched through a 60-second signed
  /// link. Held in memory only; nothing is written to disk.
  static Future<Uint8List> downloadOwn(MarriageApplication application) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final url = await _storage.createSignedUrl(
        application.filePath,
        signedUrlSeconds,
      );
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw const MarriageException(AppStrings.openFailed);
      }
      final builder = BytesBuilder(copy: false);
      await response.forEach(builder.add);
      return builder.takeBytes();
    } catch (_) {
      throw const MarriageException(AppStrings.openFailed);
    } finally {
      client.close(force: true);
    }
  }

  /// One-time date of birth for accounts created without one. The database
  /// trigger allows empty → date once and blocks any later change.
  static Future<void> saveDateOfBirth(DateTime date) async {
    final dob = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    try {
      await _client
          .from('user_profiles')
          .update({'date_of_birth': dob})
          .eq('id', _uid)
          .select('id')
          .single();
    } catch (_) {
      throw const MarriageException(AppStrings.dobSaveFailed);
    }
  }

  /// Deletes every object in the caller's folder except [keep].
  static Future<void> _sweep(String uid, {String? keep}) async {
    for (var page = 0; page < 10; page++) {
      final objects = await _storage.list(
        path: uid,
        searchOptions: const SearchOptions(limit: 100),
      );
      final paths = [
        for (final o in objects)
          if ('$uid/${o.name}' != keep) '$uid/${o.name}',
      ];
      if (paths.isEmpty) return;
      await _storage.remove(paths);
    }
  }

  /// A current access token, refreshed first if it is about to expire, so a
  /// long upload doesn't start with a token that dies halfway.
  static Future<String> _accessToken() async {
    var session = _client.auth.currentSession;
    final expiresAt = session?.expiresAt;
    final soon = DateTime.now()
            .add(const Duration(minutes: 2))
            .millisecondsSinceEpoch ~/
        1000;
    if (session != null && expiresAt != null && expiresAt < soon) {
      try {
        session = (await _client.auth.refreshSession()).session;
      } catch (_) {
        // Fall through with the current token; the server will decide.
      }
    }
    final token = session?.accessToken;
    if (token == null) throw const MarriageException(AppStrings.uploadFailed);
    return token;
  }
}

/// A random (version 4) UUID from a cryptographically secure source.
String uuidV4([Random? random]) {
  final rng = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
