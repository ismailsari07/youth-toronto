import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Picks one document and hands back its bytes only. The file name is never
/// returned, and any copy a picker left in the app's temp storage is deleted
/// before this returns.
abstract final class DocumentPicker {
  /// Files: PDF, JPG or PNG from the system document picker. The extension
  /// filter only narrows the picker; the bytes are checked afterwards.
  static Future<Uint8List?> pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } finally {
      await _quietly(FilePicker.clearTemporaryFiles);
    }
  }

  /// Photos: one image from the library. `requestFullMetadata: false` means
  /// no location permission is requested; the size cap and quality make the
  /// plugin hand back a JPEG, so an iPhone converts HEIC on the device. EXIF
  /// is stripped afterwards regardless (see `prepareDocument`).
  static Future<Uint8List?> pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
      maxWidth: 3000,
      maxHeight: 3000,
      imageQuality: 90,
    );
    if (photo == null) return null;
    try {
      return await photo.readAsBytes();
    } finally {
      if (_isPickerTempCopy(photo.path)) {
        await _quietly(() => File(photo.path).delete());
      }
    }
  }

  /// On iOS and Android the photo picker hands back a copy in the app's own
  /// temp directory, which is ours to delete. On desktop it returns the
  /// member's original file, which must never be touched.
  static bool _isPickerTempCopy(String path) {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    final temp = Directory.systemTemp.absolute.path;
    return File(path).absolute.path.startsWith('$temp${Platform.pathSeparator}');
  }

  static Future<void> _quietly(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Best effort; the OS clears the temp directory eventually.
    }
  }
}
