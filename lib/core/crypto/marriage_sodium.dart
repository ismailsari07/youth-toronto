import 'package:sodium_libs/sodium_libs.dart';

Future<Sodium>? _sodium;

/// The app's libsodium (bundled by sodium_libs), loaded once on first use.
Future<Sodium> marriageSodium() => _sodium ??= SodiumInit.init();
