import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/crypto/marriage_crypto.dart';
import '../../../core/crypto/marriage_sodium.dart';
import '../../../core/crypto/service_keys.dart';
import '../../../core/forms_v2/marriage_form.dart';
import 'marriage_service.dart' show uuidV4;
import 'photo_prep.dart';

/// The encrypted application (form v2, app 1.5.0+; pape-admin CLAUDE.md §3
/// `marriage_submissions`). The server stores only ciphertext: answers and
/// photos are sealed on the phone to the service key, which only the
/// mosque's key holders can open. Nothing here logs, and errors carry a
/// fixed reason only.

/// The published form the app renders.
class PublishedMarriageForm {
  const PublishedMarriageForm(this.version, this.schema);

  final int version;
  final Map<String, dynamic> schema;
}

/// The member's own encrypted application: status and dates only (the app
/// can't read its own answers back, by design).
class MarriageSubmission {
  const MarriageSubmission({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.photoCount,
  });

  static const columns = 'id, status, photo_count, created_at';

  factory MarriageSubmission.fromRow(Map<String, dynamic> row) => MarriageSubmission(
        id: row['id'] as String,
        status: row['status'] as String? ?? 'under_review',
        photoCount: (row['photo_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  final String id;
  final String status;
  final DateTime createdAt;
  final int photoCount;

  @override
  String toString() => 'MarriageSubmission';
}

enum SubmitFailure {
  /// The switch is off, or no pinned key is active yet.
  closed,
  notAdult,
  alreadyApplied,
  formChanged,
  sendFailed,
}

class SubmitException implements Exception {
  const SubmitException(this.failure);

  final SubmitFailure failure;

  @override
  String toString() => 'SubmitException(${failure.name})';
}

/// The published form uses something this build doesn't understand.
class FormUnsupportedException implements Exception {
  const FormUnsupportedException();
}

class WithdrawV2Exception implements Exception {
  const WithdrawV2Exception();
}

/// One photo ready to send, with the number it will have (1…3).
typedef NumberedPhoto = ({int n, PreparedPhoto photo});

abstract final class MarriageV2Service {
  static const bucket = 'marriage-sealed';

  static SupabaseClient get _client => Supabase.instance.client;
  static StorageFileApi get _storage => _client.storage.from(bucket);

  static String _uid() {
    final user = _client.auth.currentUser;
    if (user == null) throw const SubmitException(SubmitFailure.sendFailed);
    return user.id;
  }

  /// The published form, or null when none is published. Throws
  /// [FormUnsupportedException] when it fails the format check (the app
  /// never renders a form it doesn't understand: update the app).
  static Future<PublishedMarriageForm?> fetchForm() async {
    final row = await _client
        .from('marriage_forms')
        .select('version, schema')
        .eq('status', 'published')
        .maybeSingle();
    if (row == null) return null;
    final schema = row['schema'];
    final version = row['version'];
    if (version is! int || schema is! Map<String, dynamic> || !marriageFormValid(schema)) {
      throw const FormUnsupportedException();
    }
    return PublishedMarriageForm(version, schema);
  }

  /// The key to seal to, or null while the service isn't open (no key
  /// that is active in the database and pinned in this build).
  static Future<({int keyId, Uint8List publicKey})?> fetchServiceKey({
    Map<int, String> pinned = kPinnedServiceKeys,
  }) async {
    if (pinned.isEmpty) return null;
    final rows = await _client.from('marriage_service_keys').select('key_id, public_key, retired_at');
    return pickServiceKey(List<Map<String, dynamic>>.from(rows), pinned);
  }

  /// The caller's encrypted application, or null.
  static Future<MarriageSubmission?> fetchOwn() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('marriage_submissions')
        .select(MarriageSubmission.columns)
        .eq('user_id', user.id)
        .maybeSingle();
    return row == null ? null : MarriageSubmission.fromRow(row);
  }

  /// Seals and sends one application. [answers] are the CLEAN answers from
  /// `validateAnswers`; the photos field's answer must be `[1…n]` for the
  /// [photos] given. On any failure the uploaded parts are removed.
  static Future<void> submit({
    required PublishedMarriageForm form,
    required Map<String, Object> answers,
    required List<NumberedPhoto> photos,
    required String locale,
    String? appVersion,
    void Function(int done, int total)? onProgress,
  }) async {
    final uid = _uid();
    final key = await fetchServiceKey().catchError((_) => null);
    if (key == null) throw const SubmitException(SubmitFailure.closed);

    final id = uuidV4();
    final sodium = await marriageSodium();
    final sealed = sealApplication(
      sodium,
      submissionId: id,
      payload: answersPayload(
        formVersion: form.version,
        answers: answers,
        photos: [for (final p in photos) (n: p.n, width: p.photo.width, height: p.photo.height)],
        submittedAt: DateTime.now(),
        locale: locale,
        appVersion: appVersion,
      ),
      photos: [for (final p in photos) p.photo.bytes],
      servicePublicKey: key.publicKey,
    );

    final uploaded = <String>[];
    final total = photos.length + 1;
    try {
      for (var i = 0; i < sealed.photos.length; i++) {
        onProgress?.call(i, total);
        final path = '$uid/$id/${photos[i].n}.bin';
        await _storage.uploadBinary(
          path,
          sealed.photos[i],
          fileOptions: const FileOptions(contentType: 'application/octet-stream', upsert: false),
        );
        uploaded.add(path);
      }
      onProgress?.call(photos.length, total);
      await _client.rpc('submit_marriage_application', params: {
        'p_id': id,
        'p_form_version': form.version,
        'p_key_id': key.keyId,
        'p_sealed_key': sealed.sealedKey,
        'p_answers_ct': sealed.answersCt,
        'p_photo_count': photos.length,
        'p_app_version': appVersion,
      });
      onProgress?.call(total, total);
    } on PostgrestException catch (e) {
      await _discard(uploaded);
      throw SubmitException(failureFor(e.code, e.message));
    } catch (_) {
      await _discard(uploaded);
      throw const SubmitException(SubmitFailure.sendFailed);
    }
  }

  /// Server error → reason (pape-admin `submit_marriage_application`).
  static SubmitFailure failureFor(String? code, String message) => switch ((code, message)) {
        ('P0001', 'unavailable') || ('P0001', 'key_changed') => SubmitFailure.closed,
        ('P0001', 'not_adult') => SubmitFailure.notAdult,
        ('P0001', 'already_applied') || ('23505', _) => SubmitFailure.alreadyApplied,
        ('P0001', 'form_changed') => SubmitFailure.formChanged,
        _ => SubmitFailure.sendFailed,
      };

  /// Withdraw: the photos first (through the Storage API), then the row.
  /// If the photos can't be deleted the row stays, so the member still sees
  /// the application and can retry.
  static Future<void> withdraw(MarriageSubmission submission) async {
    try {
      final uid = _uid();
      final folder = '$uid/${submission.id}';
      for (var round = 0; round < 5; round++) {
        final files = await _storage.list(path: folder);
        if (files.isEmpty) break;
        await _storage.remove([for (final f in files) '$folder/${f.name}']);
      }
      await _client.rpc('withdraw_marriage_application');
    } catch (_) {
      throw const WithdrawV2Exception();
    }
  }

  static Future<void> _discard(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _storage.remove(paths);
    } catch (_) {
      // Left in the member's own folder; removed on withdraw or account deletion.
    }
  }
}
