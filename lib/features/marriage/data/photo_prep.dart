import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Photos for the encrypted application (form v2): decoded on the phone,
/// orientation baked into the pixels, long side at most [maxEdge], every
/// piece of metadata removed (EXIF incl. location, ICC, text chunks), and
/// re-encoded as a plain JPEG. Only the result is encrypted and uploaded;
/// the picked original never leaves the phone.

const maxEdge = 1600;

/// The encrypted part must fit the bucket's 3 MB limit with its padding.
const maxPhotoBytes = 2800 * 1024;

/// Larger picks are refused before decoding (memory).
const maxPhotoInputBytes = 40 * 1024 * 1024;

@immutable
class PreparedPhoto {
  const PreparedPhoto(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;

  @override
  String toString() => 'PreparedPhoto(${width}x$height)';
}

enum PhotoProblem { unreadable, tooLarge }

/// Runs [preparePhotoSync] off the UI thread.
Future<(PreparedPhoto?, PhotoProblem?)> preparePhoto(Uint8List raw) =>
    compute(preparePhotoSync, raw);

(PreparedPhoto?, PhotoProblem?) preparePhotoSync(Uint8List raw) {
  if (raw.length > maxPhotoInputBytes) return (null, PhotoProblem.tooLarge);
  img.Image? decoded;
  try {
    decoded = img.decodeImage(raw);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null || decoded.width < 1 || decoded.height < 1) {
    return (null, PhotoProblem.unreadable);
  }
  var image = img.bakeOrientation(img.Image.from(decoded, noAnimation: true));
  final long = image.width > image.height ? image.width : image.height;
  if (long > maxEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxEdge, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: maxEdge, interpolation: img.Interpolation.average);
  }
  // bakeOrientation and copyResize copy metadata across: clear it last.
  image
    ..exif = img.ExifData()
    ..textData = null
    ..iccProfile = null;
  // Transparent pixels (PNG) become white, not black, in a JPEG.
  if (image.hasAlpha) {
    final flat = img.Image(width: image.width, height: image.height)..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(flat, image);
  }
  for (final q in const [86, 75, 62]) {
    final out = img.encodeJpg(image, quality: q);
    if (out.length <= maxPhotoBytes) return (PreparedPhoto(out, image.width, image.height), null);
  }
  return (null, PhotoProblem.tooLarge);
}
