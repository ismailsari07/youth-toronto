import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The three file types the marriage service accepts, identified by their
/// leading bytes — never by the file name or extension.
enum DocumentKind {
  pdf('application/pdf', 'pdf', 'PDF'),
  jpg('image/jpeg', 'jpg', 'JPG'),
  png('image/png', 'png', 'PNG');

  const DocumentKind(this.mimeType, this.extension, this.label);

  final String mimeType;
  final String extension;
  final String label;

  static DocumentKind? fromMimeType(String mimeType) {
    for (final kind in values) {
      if (kind.mimeType == mimeType) return kind;
    }
    return null;
  }
}

/// Spec §8a: files must be under 4 MB. The bucket enforces the same limit.
const maxDocumentBytes = 4 * 1024 * 1024;

/// Images above this are refused before decoding, so a huge file can't
/// exhaust memory on the phone.
const _maxImageInputBytes = 40 * 1024 * 1024;

/// Longest edge of a re-encoded photo. Plenty for reading a document, and it
/// keeps a phone photo well under [maxDocumentBytes].
const _maxImageEdge = 3000;

/// Identifies [bytes] by magic number: `%PDF`, JPEG `FF D8 FF`, PNG
/// `89 50 4E 47 0D 0A 1A 0A`. Anything else (including HEIC) is null.
DocumentKind? sniffDocumentKind(Uint8List bytes) {
  bool startsWith(List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0x25, 0x50, 0x44, 0x46])) return DocumentKind.pdf;
  if (startsWith(const [0xFF, 0xD8, 0xFF])) return DocumentKind.jpg;
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return DocumentKind.png;
  }
  return null;
}

enum RejectReason { tooLarge, unsupportedType, unreadable }

/// The outcome of [prepareDocument]. Deliberately carries no file name.
sealed class PreparedDocument {
  const PreparedDocument();
}

/// Ready to upload: [bytes] are exactly what will be sent.
final class AcceptedDocument extends PreparedDocument {
  const AcceptedDocument(this.bytes, this.kind);

  final Uint8List bytes;
  final DocumentKind kind;

  int get size => bytes.length;
}

final class RejectedDocument extends PreparedDocument {
  const RejectedDocument(this.reason, {this.size, this.kind});

  final RejectReason reason;

  /// The size that was over the limit, for the "5.6 MB · too large" caption.
  final int? size;
  final DocumentKind? kind;
}

/// Validates and cleans a picked file off the UI thread. See
/// [prepareDocumentSync].
Future<PreparedDocument> prepareDocument(Uint8List raw) =>
    Isolate.run(() => prepareDocumentSync(raw));

/// Validates [raw] by its bytes and returns what may be uploaded.
///
/// PDFs pass through unchanged. Photos are always decoded and re-encoded:
/// the EXIF orientation is applied to the pixels, then every EXIF block
/// (including GPS), PNG text chunk and ICC profile is dropped, so nothing but
/// pixels leaves the phone. The size limit applies to the bytes that would
/// actually be uploaded.
PreparedDocument prepareDocumentSync(Uint8List raw) {
  final kind = sniffDocumentKind(raw);
  if (kind == null) {
    return const RejectedDocument(RejectReason.unsupportedType);
  }

  if (kind == DocumentKind.pdf) {
    if (raw.length > maxDocumentBytes) {
      return RejectedDocument(RejectReason.tooLarge, size: raw.length, kind: kind);
    }
    return AcceptedDocument(raw, kind);
  }

  if (raw.length > _maxImageInputBytes) {
    return RejectedDocument(RejectReason.tooLarge, size: raw.length, kind: kind);
  }

  final img.Image? decoded;
  try {
    decoded = kind == DocumentKind.jpg ? img.decodeJpg(raw) : img.decodePng(raw);
  } catch (_) {
    return RejectedDocument(RejectReason.unreadable, kind: kind);
  }
  if (decoded == null) {
    return RejectedDocument(RejectReason.unreadable, kind: kind);
  }

  final clean = stripImage(decoded);

  // Keep the picked format where it fits; a PNG that is still too large is
  // tried as a JPEG, and a JPEG at a lower quality, before giving up.
  final attempts = <(DocumentKind, Uint8List Function())>[
    if (kind == DocumentKind.png)
      (DocumentKind.png, () => img.encodePng(clean, level: 6)),
    (DocumentKind.jpg, () => img.encodeJpg(clean, quality: 88)),
    (DocumentKind.jpg, () => img.encodeJpg(clean, quality: 75)),
  ];
  var smallest = 0;
  for (final (outKind, encode) in attempts) {
    final out = encode();
    if (out.length <= maxDocumentBytes) return AcceptedDocument(out, outKind);
    smallest = out.length;
  }
  return RejectedDocument(RejectReason.tooLarge, size: smallest, kind: kind);
}

/// Returns a single-frame copy of [source] with orientation baked into the
/// pixels, the long edge capped, and all metadata removed.
img.Image stripImage(img.Image source) {
  var image = img.bakeOrientation(img.Image.from(source, noAnimation: true));
  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge > _maxImageEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: _maxImageEdge)
        : img.copyResize(image, height: _maxImageEdge);
  }
  // copyResize and bakeOrientation copy metadata across, so clear it last.
  image
    ..exif = img.ExifData()
    ..textData = null
    ..iccProfile = null;
  return image;
}
