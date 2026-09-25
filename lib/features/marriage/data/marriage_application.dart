import 'document_check.dart';

/// The signed-in member's own `marriage_applications` row.
///
/// Only the columns the app needs. `original_name` is never read or written:
/// the file name is not stored anywhere.
class MarriageApplication {
  const MarriageApplication({
    required this.filePath,
    required this.kind,
    required this.sizeBytes,
    required this.createdAt,
  });

  static const columns = 'file_path, mime_type, size_bytes, created_at';

  factory MarriageApplication.fromRow(Map<String, dynamic> row) {
    return MarriageApplication(
      filePath: row['file_path'] as String,
      kind: DocumentKind.fromMimeType(row['mime_type'] as String) ??
          DocumentKind.pdf,
      sizeBytes: (row['size_bytes'] as num).toInt(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  /// `{user_id}/{uuid}.{ext}` inside the private bucket.
  final String filePath;
  final DocumentKind kind;
  final int sizeBytes;
  final DateTime createdAt;

  // Keep the path and details out of any accidental log or error message.
  @override
  String toString() => 'MarriageApplication';
}
