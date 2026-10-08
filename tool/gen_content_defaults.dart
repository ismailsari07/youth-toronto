// Regenerates assets/content_defaults.json from the live content bundle.
//
//   dart run tool/gen_content_defaults.dart
//
// Run it before every release build and commit the result if it changed.
// The defaults are what a first launch without a network shows; the app
// replaces them with the live bundle as soon as it can fetch it.
//
// Read-only: calls app_content_bundle() with the app's public anon key,
// exactly as the app does. The banner is left out, since a bundled banner
// could never be switched off.
import 'dart:convert';
import 'dart:io';

const _output = 'assets/content_defaults.json';
const _keySource = 'lib/core/prayer_service.dart';

Future<void> main() async {
  final source = File(_keySource).readAsStringSync();
  final url = RegExp(r"supabaseUrl\s*=\s*'([^']+)'").firstMatch(source)?[1];
  final key = RegExp(r"supabaseAnonKey\s*=\s*'([^']+)'").firstMatch(source)?[1];
  if (url == null || key == null) {
    stderr.writeln(
      'Could not read the Supabase URL and anon key from $_keySource',
    );
    exit(1);
  }

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$url/rest/v1/rpc/app_content_bundle'),
    );
    request.headers
      ..set('apikey', key)
      ..set('Authorization', 'Bearer $key')
      ..contentType = ContentType.json;
    request.write('{}');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      stderr.writeln('app_content_bundle() answered ${response.statusCode}');
      exit(1);
    }

    final bundle = jsonDecode(body);
    if (bundle is! Map<String, dynamic> || bundle['content'] is! Map) {
      stderr.writeln('app_content_bundle() did not return a bundle');
      exit(1);
    }
    final content = bundle['content'] as Map<String, dynamic>;
    final hadBanner = content.remove('app_banner') != null;

    const encoder = JsonEncoder.withIndent('  ');
    File(_output).writeAsStringSync('${encoder.convert(_sorted(bundle))}\n');
    stdout.writeln(
      'Wrote $_output (version ${bundle['version']})'
      '${hadBanner ? ', banner left out' : ''}',
    );
  } finally {
    client.close();
  }
}

/// Sorted keys, so regenerating unchanged content gives an unchanged file.
Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}
