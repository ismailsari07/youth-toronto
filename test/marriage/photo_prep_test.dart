import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myt_flutter/features/marriage/data/photo_prep.dart';

Uint8List _jpegWithExif({required int w, required int h, int orientation = 1}) {
  final image = img.Image(width: w, height: h)..clear(img.ColorRgb8(200, 30, 30));
  image.exif.imageIfd['Make'] = 'TestPhone';
  image.exif.imageIfd.orientation = orientation;
  image.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(43, 1);
  image.exif.gpsIfd['GPSLongitude'] = img.IfdValueRational(79, 1);
  return img.encodeJpg(image, quality: 90);
}

void main() {
  test('the original carries EXIF (so the test means something)', () {
    final raw = _jpegWithExif(w: 40, h: 20);
    final back = img.decodeJpg(raw)!;
    expect(back.exif.isEmpty, isFalse);
    expect(back.exif.gpsIfd.isEmpty, isFalse);
  });

  test('metadata is removed, size kept when small', () {
    final (photo, problem) = preparePhotoSync(_jpegWithExif(w: 40, h: 20));
    expect(problem, isNull);
    expect((photo!.width, photo.height), (40, 20));
    final back = img.decodeJpg(photo.bytes)!;
    expect(back.exif.isEmpty, isTrue, reason: 'no EXIF at all, location included');
    // No APP1 (EXIF/XMP) marker anywhere in the file.
    final b = photo.bytes;
    for (var i = 0; i + 1 < b.length; i++) {
      if (b[i] == 0xFF && b[i + 1] == 0xE1) fail('APP1 marker found at $i');
    }
  });

  test('orientation is baked into the pixels', () {
    // 6 = rotate 90° clockwise to display: a 40×20 file shows as 20×40.
    final (photo, _) = preparePhotoSync(_jpegWithExif(w: 40, h: 20, orientation: 6));
    expect((photo!.width, photo.height), (20, 40));
  });

  test('the long side is capped at 1600', () {
    final (wide, _) = preparePhotoSync(_jpegWithExif(w: 4000, h: 3000));
    expect((wide!.width, wide.height), (1600, 1200));
    final (tall, _) = preparePhotoSync(_jpegWithExif(w: 1000, h: 3200));
    expect((tall!.width, tall.height), (500, 1600));
    expect(tall.bytes.length, lessThanOrEqualTo(maxPhotoBytes));
  });

  test('PNG with transparency becomes a JPEG', () {
    final png = img.encodePng(img.Image(width: 10, height: 10, numChannels: 4));
    final (photo, problem) = preparePhotoSync(png);
    expect(problem, isNull);
    expect(img.decodeJpg(photo!.bytes), isNotNull);
  });

  test('not an image, or far too large → refused', () {
    expect(preparePhotoSync(Uint8List.fromList(List.filled(100, 7))).$2, PhotoProblem.unreadable);
    expect(preparePhotoSync(Uint8List(maxPhotoInputBytes + 1)).$2, PhotoProblem.tooLarge);
  });
}
