import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Spec §6. A semicircle drawn in a 300×170 coordinate space: centre
/// (150, 150), radius 128, sweeping from 180° (left) over the top to 0°
/// (right). The whole space scales to the card's width.
class CountdownArc extends StatelessWidget {
  const CountdownArc({super.key, required this.progress});

  /// Elapsed fraction of the current prayer window, 0..1.
  final double progress;

  static const designWidth = 300.0;
  static const designHeight = 170.0;
  static const stackHeightDesign = 180.0;

  /// The art is fixed-size (spec §6): it only ever scales *down*, on screens
  /// narrower than the design. Scaling up would push the arc's ends past the
  /// 180 stack and over the row beneath it.
  static double scaleFor(double width) =>
      math.min(1.0, width / designWidth);

  /// Height the surrounding stack must reserve for this arc.
  static double stackHeight(double width) =>
      stackHeightDesign * scaleFor(width);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = scaleFor(constraints.maxWidth);
        return CustomPaint(
          size: Size(constraints.maxWidth, designHeight * scale),
          painter: _ArcPainter(
            progress: progress.clamp(0, 1),
            scale: scale,
            availableWidth: constraints.maxWidth,
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.scale,
    required this.availableWidth,
  });

  final double progress;
  final double scale;
  final double availableWidth;

  static const _centre = Offset(150, 150);
  static const _radius = 128.0;
  static const _stroke = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    // Centre the fixed-size art in whatever width the card gives us.
    final dx = (availableWidth - CountdownArc.designWidth * scale) / 2;
    canvas.translate(dx / scale, 0);

    final rect = Rect.fromCircle(center: _centre, radius: _radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColor.heroArcTrack; // white 18%

    // Full semicircle: from 180° through the top to 0°.
    canvas.drawArc(rect, math.pi, math.pi, false, track);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = AppColor.onHero,
      );
    }

    // Knob at the progress end point (spec's end-point maths).
    final angleDeg = 180 - progress * 180;
    final a = angleDeg * math.pi / 180;
    final knob = Offset(
      _centre.dx + _radius * math.cos(a),
      _centre.dy - _radius * math.sin(a),
    );
    canvas.drawCircle(knob, 10, Paint()..color = AppColor.heroKnobHalo);
    canvas.drawCircle(knob, 5.2, Paint()..color = AppColor.onHero);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.scale != scale ||
      old.availableWidth != availableWidth;
}
