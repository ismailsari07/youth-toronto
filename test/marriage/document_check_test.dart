import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myt_flutter/features/marriage/data/document_check.dart';

/// True if [needle] occurs anywhere in [haystack].
bool containsBytes(Uint8List haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

/// A 40×20 photo tagged the way a phone camera tags one: GPS position,
/// camera make and model, and orientation 6 (rotate 90° clockwise).
img.Image taggedPhoto() {
  final photo = img.Image(width: 40, height: 20);
  img.fill(photo, color: img.ColorRgb8(30, 120, 80));
  photo.exif.gpsIfd.setGpsLocation(latitude: 43.6858, longitude: -79.3502);
  photo.exif.imageIfd
    ..make = 'PhoneMaker'
    ..model = 'SecretPhone 12'
    ..orientation = 6;
  return photo;
}

AcceptedDocument accepted(PreparedDocument result) {
  expect(result, isA<AcceptedDocument>());
  return result as AcceptedDocument;
}

RejectedDocument rejected(PreparedDocument result) {
  expect(result, isA<RejectedDocument>());
  return result as RejectedDocument;
}

void main() {
  group('magic bytes', () {
    test('identifies PDF, JPEG and PNG by content', () {
      expect(sniffDocumentKind(Uint8List.fromList(ascii.encode('%PDF-1.7\n'))),
          DocumentKind.pdf);
      expect(sniffDocumentKind(img.encodeJpg(img.Image(width: 2, height: 2))),
          DocumentKind.jpg);
      expect(sniffDocumentKind(img.encodePng(img.Image(width: 2, height: 2))),
          DocumentKind.png);
    });

    test('rejects text, HEIC and empty files whatever they are called', () {
      final text = Uint8List.fromList(utf8.encode('hello, this is not a pdf'));
      final heic = Uint8List.fromList(
          [0, 0, 0, 0x18, ...ascii.encode('ftypheic'), 0, 0, 0, 0]);
      for (final bytes in [text, heic, Uint8List(0), Uint8List(3)]) {
        expect(sniffDocumentKind(bytes), isNull);
        expect(rejected(prepareDocumentSync(bytes)).reason,
            RejectReason.unsupportedType);
      }
    });

    test('a truncated PNG header is not a PNG', () {
      expect(sniffDocumentKind(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])),
          isNull);
    });

    test('an image that fails to decode is unreadable, not accepted', () {
      final fakeJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
      expect(rejected(prepareDocumentSync(fakeJpeg)).reason,
          RejectReason.unreadable);
    });
  });

  group('size limit', () {
    Uint8List pdfOfSize(int size) {
      final bytes = Uint8List(size);
      bytes.setAll(0, ascii.encode('%PDF-1.4\n'));
      return bytes;
    }

    test('a PDF of exactly 4 MB is accepted unchanged', () {
      final pdf = pdfOfSize(maxDocumentBytes);
      final result = accepted(prepareDocumentSync(pdf));
      expect(result.kind, DocumentKind.pdf);
      expect(identical(result.bytes, pdf), isTrue);
    });

    test('a PDF one byte over 4 MB is rejected with its size', () {
      final result = rejected(prepareDocumentSync(pdfOfSize(maxDocumentBytes + 1)));
      expect(result.reason, RejectReason.tooLarge);
      expect(result.size, maxDocumentBytes + 1);
      expect(result.kind, DocumentKind.pdf);
    });

    test('an image that cannot fit under 4 MB is rejected', () {
      // 3000×3000 of random noise does not compress below 4 MB as a PNG or
      // as a JPEG at either quality.
      final noise = img.Image(width: 3000, height: 3000);
      var seed = 7;
      for (final p in noise) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        p
          ..r = seed & 0xff
          ..g = (seed >> 8) & 0xff
          ..b = (seed >> 16) & 0xff;
      }
      final result = rejected(prepareDocumentSync(img.encodePng(noise)));
      expect(result.reason, RejectReason.tooLarge);
      expect(result.size, greaterThan(maxDocumentBytes));
    });
  });

  group('photo metadata', () {
    test('the fixture really carries GPS before cleaning', () {
      final original = img.encodeJpg(taggedPhoto());
      final reread = img.decodeJpg(original)!;
      expect(reread.exif.gpsIfd.gpsLatitude, closeTo(43.6858, 0.001));
      expect(containsBytes(original, ascii.encode('SecretPhone')), isTrue);
    });

    test('JPEG: GPS, camera and every EXIF block are removed', () {
      final result =
          accepted(prepareDocumentSync(img.encodeJpg(taggedPhoto())));
      expect(result.kind, DocumentKind.jpg);

      final out = img.decodeJpg(result.bytes)!;
      expect(out.exif.gpsIfd.gpsLatitude, isNull);
      expect(out.exif.gpsIfd.gpsLongitude, isNull);
      expect(out.exif.isEmpty, isTrue);
      // No APP1 "Exif\0\0" segment and no trace of the camera in the file.
      expect(containsBytes(result.bytes, [...ascii.encode('Exif'), 0, 0]),
          isFalse);
      expect(containsBytes(result.bytes, ascii.encode('SecretPhone')), isFalse);
      expect(containsBytes(result.bytes, ascii.encode('PhoneMaker')), isFalse);
    });

    test('JPEG: orientation is baked into the pixels', () {
      final result =
          accepted(prepareDocumentSync(img.encodeJpg(taggedPhoto())));
      final out = img.decodeJpg(result.bytes)!;
      // 40×20 rotated 90° is 20×40, and no orientation tag is left to apply.
      expect(out.width, 20);
      expect(out.height, 40);
      expect(out.exif.imageIfd.hasOrientation, isFalse);
    });

    test('PNG: EXIF, GPS and text chunks are removed', () {
      final photo = taggedPhoto()
        ..textData = {'Author': 'Jane Member', 'Comment': 'home address'};
      final original = img.encodePng(photo);
      expect(containsBytes(original, ascii.encode('Jane Member')), isTrue);

      final result = accepted(prepareDocumentSync(original));
      expect(result.kind, DocumentKind.png);
      final out = img.decodePng(result.bytes)!;
      expect(out.exif.gpsIfd.gpsLatitude, isNull);
      expect(out.exif.isEmpty, isTrue);
      expect(out.textData, anyOf(isNull, isEmpty));
      for (final chunk in ['eXIf', 'tEXt', 'iTXt', 'zTXt', 'iCCP']) {
        expect(containsBytes(result.bytes, ascii.encode(chunk)), isFalse,
            reason: '$chunk chunk should be gone');
      }
      expect(containsBytes(result.bytes, ascii.encode('Jane Member')), isFalse);
    });

    test('large photos are scaled so the long edge is 3000 px', () {
      final big = img.Image(width: 4000, height: 1000);
      final result = accepted(prepareDocumentSync(img.encodeJpg(big)));
      final out = img.decodeJpg(result.bytes)!;
      expect(out.width, 3000);
      expect(out.height, 750);
    });
  });
}
