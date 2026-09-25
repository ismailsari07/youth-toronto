import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Thrown by [DocumentUpload.done] when the upload did not finish.
/// Carries no path, URL or server text.
class UploadFailed implements Exception {
  const UploadFailed({this.cancelled = false});

  final bool cancelled;

  @override
  String toString() => cancelled ? 'UploadFailed(cancelled)' : 'UploadFailed';
}

/// One raw-body POST to Supabase Storage with real progress and cancel.
///
/// `storage_client` has no progress callback, so the body is written here in
/// 64 KB chunks and counted as each chunk is flushed to the socket. Progress
/// stops at 99% until the server answers; 100% means the object is stored.
class DocumentUpload {
  DocumentUpload._(this._bytes, this._contentType);

  /// Starts uploading [bytes] to [endpoint]
  /// (`…/storage/v1/object/{bucket}/{path}`) with [headers] — the caller's
  /// own JWT and the anon key. Never upserts: every upload is a new path.
  factory DocumentUpload.start({
    required Uri endpoint,
    required Map<String, String> headers,
    required Uint8List bytes,
    required String contentType,
  }) {
    final upload = DocumentUpload._(bytes, contentType);
    upload._done = upload._run(endpoint, headers);
    // The caller may cancel without ever awaiting [done].
    upload._done.ignore();
    return upload;
  }

  static const _chunkSize = 64 * 1024;

  final Uint8List _bytes;
  final String _contentType;
  final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 5);
  HttpClientRequest? _request;
  bool _cancelled = false;
  late final Future<void> _done;

  /// 0.0 → 1.0.
  final ValueNotifier<double> progress = ValueNotifier(0);

  /// Completes when the server has stored the object; otherwise throws
  /// [UploadFailed].
  Future<void> get done => _done;

  bool get isCancelled => _cancelled;

  /// Aborts the request. The caller removes any partial object afterwards
  /// (the server may already have stored it).
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _request?.abort(const UploadFailed(cancelled: true));
    _client.close(force: true);
  }

  void dispose() => progress.dispose();

  Future<void> _run(Uri endpoint, Map<String, String> headers) async {
    try {
      final request = await _client.postUrl(endpoint);
      _request = request;
      if (_cancelled) {
        request.abort();
        throw const UploadFailed(cancelled: true);
      }
      headers.forEach(request.headers.set);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, _contentType)
        ..set(HttpHeaders.cacheControlHeader, 'no-store')
        ..set('x-upsert', 'false');
      request.contentLength = _bytes.length;

      for (var sent = 0; sent < _bytes.length;) {
        if (_cancelled) throw const UploadFailed(cancelled: true);
        final end = (sent + _chunkSize).clamp(0, _bytes.length);
        request.add(Uint8List.sublistView(_bytes, sent, end));
        await request.flush();
        sent = end;
        progress.value = 0.99 * sent / _bytes.length;
      }

      final response = await request.close();
      // Drain without keeping or logging the body.
      await response.drain<void>();
      if (response.statusCode != HttpStatus.ok) throw const UploadFailed();
      progress.value = 1;
    } on UploadFailed {
      rethrow;
    } catch (_) {
      throw UploadFailed(cancelled: _cancelled);
    } finally {
      _client.close(force: true);
    }
  }
}
