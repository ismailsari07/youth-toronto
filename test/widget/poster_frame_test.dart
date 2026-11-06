import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myt_flutter/theme/app_theme.dart';
import 'package:myt_flutter/ui/components/announcement_photo.dart';

/// A real PNG: a coloured field with a bright bar along each edge, so a crop
/// would show on the saved picture.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = width.toDouble(), h = height.toDouble();
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1F7A5C));
  final edge = Paint()..color = const Color(0xFFFFD54F);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.05), edge);
  canvas.drawRect(Rect.fromLTWH(0, h * 0.95, w, h * 0.05), edge);
  canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.05, h), edge);
  canvas.drawRect(Rect.fromLTWH(w * 0.95, 0, w * 0.05, h), edge);
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  test('only a different shape needs the backdrop', () {
    expect(PosterFrame.leavesRoom(16 / 9), isFalse);
    expect(PosterFrame.leavesRoom(1600 / 901), isFalse, reason: 'rounding');
    expect(PosterFrame.leavesRoom(3 / 4), isTrue, reason: 'portrait poster');
    expect(PosterFrame.leavesRoom(1), isTrue, reason: 'square');
    expect(PosterFrame.leavesRoom(3 / 1), isTrue, reason: 'wider than the frame');
  });

  Future<void> show(WidgetTester tester, Uint8List bytes, ThemeData theme) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 358,
            child: RepaintBoundary(key: key, child: PosterFrame(image: MemoryImage(bytes))),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    shots[tester.testDescription] = key;
  }

  final shotDir = Platform.environment['SHOT_DIR'];

  Future<void> save(WidgetTester tester, String name) async {
    if (shotDir == null) return;
    final key = shots[tester.testDescription]!;
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shotDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  for (final (name, theme) in [('light', appLightTheme), ('dark', appDarkTheme)]) {
    testWidgets('$name: a portrait poster shows whole, with the backdrop', (tester) async {
      final bytes = (await tester.runAsync(() => _png(600, 900)))!;
      await show(tester, bytes, theme);

      final frame = tester.getSize(find.byType(PosterFrame));
      expect(frame.width / frame.height, closeTo(16 / 9, 0.01), reason: "the card's frame");
      expect(find.byKey(const Key('poster-backdrop')), findsOneWidget);

      final front = tester.widgetList<Image>(find.byType(Image)).last;
      expect(front.fit, BoxFit.contain);
      await save(tester, 'portrait-$name');
    });

    testWidgets('$name: a 16:9 photo fills the frame, no backdrop', (tester) async {
      final bytes = (await tester.runAsync(() => _png(1600, 900)))!;
      await show(tester, bytes, theme);
      expect(find.byKey(const Key('poster-backdrop')), findsNothing);
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
      await save(tester, 'wide-$name');
    });
  }

  testWidgets('a square poster also shows whole', (tester) async {
    final bytes = (await tester.runAsync(() => _png(800, 800)))!;
    await show(tester, bytes, appLightTheme);
    expect(find.byKey(const Key('poster-backdrop')), findsOneWidget);
    expect(tester.widgetList<Image>(find.byType(Image)).last.fit, BoxFit.contain);
    await save(tester, 'square-light');
  });
}

final shots = <String, GlobalKey>{};
