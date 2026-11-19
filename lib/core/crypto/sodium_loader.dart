import 'dart:ffi';
import 'dart:io';

import 'package:sodium/sodium.dart';

/// libsodium for tests and tools on a development machine or CI (the app
/// itself uses sodium_libs' bundled build: `marriageSodium()`). Fails
/// loudly when it isn't installed, so a crypto test never silently skips:
/// Linux `apt install libsodium23`, macOS `brew install libsodium`.
Future<Sodium> loadSystemSodium() => SodiumInit.init(() {
      final candidates = [
        if (Platform.environment['LIBSODIUM_PATH'] case final p?) p,
        if (Platform.isMacOS) ...[
          '/opt/homebrew/lib/libsodium.dylib',
          '/usr/local/lib/libsodium.dylib',
        ],
        if (Platform.isLinux) ...[
          'libsodium.so.26',
          'libsodium.so.23',
          'libsodium.so',
        ],
      ];
      for (final c in candidates) {
        try {
          return DynamicLibrary.open(c);
        } on ArgumentError {
          continue;
        }
      }
      throw StateError(
        'libsodium not found (tried ${candidates.join(', ')}). '
        'Install it (apt install libsodium23 / brew install libsodium) or set LIBSODIUM_PATH.',
      );
    });
