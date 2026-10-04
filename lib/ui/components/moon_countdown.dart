import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_tokens.dart';

/// Spec §6 — the signature element. A full moon that fills with glowing white
/// liquid as the next prayer approaches.
///
/// Occupies the reserved 176×176 square (`AppMoon.box`); the disc itself is
/// Ø144 (`AppMoon.disc`), centred, leaving a 16 px ring the glow paints into.
/// Deliberately unclipped — the halo needs that ring. The card clips instead,
/// so nothing escapes the rounded corner.
class MoonCountdown extends StatefulWidget {
  const MoonCountdown({super.key, required this.fill});

  /// Elapsed fraction of the current prayer window, 0..1. 0 = empty and dark,
  /// 1 = full and brightest.
  final double fill;

  @override
  State<MoonCountdown> createState() => _MoonCountdownState();
}

class _MoonCountdownState extends State<MoonCountdown>
    with SingleTickerProviderStateMixin {
  /// The surface phase advances 2π every [_cycle], from continuously elapsed
  /// time — never from a repeating 0..1 value. A repeating value wraps back
  /// to its start every cycle, and any wave whose speed is not a whole
  /// multiple of that cycle (the second one drifts at −1.5×) visibly jumps
  /// at the wrap. Elapsed time has no wrap, so the ripple flows forever.
  static const _cycle = Duration(seconds: 6);

  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<double> _phase = ValueNotifier(0);

  /// Phase when the ticker last (re)started; a ticker's elapsed time starts
  /// again from zero on every start.
  double _phaseAtStart = 0;

  bool _rippling = false;

  void _onTick(Duration elapsed) {
    _phase.value =
        _phaseAtStart +
        2 * math.pi * elapsed.inMicroseconds / _cycle.inMicroseconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion: hold the surface still. The fill level and the digits
    // keep updating — only the ripple stops. A hidden tab mutes the ticker
    // through `TickerMode`, so no frames are spent while it is offscreen.
    final media = MediaQuery.of(context);
    final wantRipple = !media.disableAnimations && !media.accessibleNavigation;
    if (wantRipple == _rippling) return;
    _rippling = wantRipple;
    if (wantRipple) {
      _phaseAtStart = _phase.value;
      _ticker.start();
    } else {
      _ticker.stop();
      _phase.value = 0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: AppMoon.box,
        height: AppMoon.box,
        child: ValueListenableBuilder<double>(
          valueListenable: _phase,
          builder: (_, phase, _) => CustomPaint(
            size: const Size(AppMoon.box, AppMoon.box),
            isComplex: true,
            painter: _MoonPainter(
              fill: widget.fill.clamp(0.0, 1.0),
              phase: phase,
            ),
          ),
        ),
      ),
    );
  }
}

/// A crater, in unit-disc coordinates: centre and radius as fractions of the
/// disc radius, so the whole set scales with the moon.
class _Crater {
  const _Crater(this.dx, this.dy, this.r);
  final double dx;
  final double dy;
  final double r;
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.fill, required this.phase});

  final double fill;
  final double phase;

  /// Fixed positions — a moon's face does not rearrange itself between frames.
  static const _craters = <_Crater>[
    _Crater(-0.30, -0.32, 0.155),
    _Crater(0.22, -0.45, 0.100),
    _Crater(0.44, -0.10, 0.135),
    _Crater(-0.52, 0.10, 0.095),
    _Crater(-0.10, 0.12, 0.200),
    _Crater(0.28, 0.38, 0.115),
    _Crater(-0.35, 0.47, 0.130),
    _Crater(0.58, 0.34, 0.075),
    _Crater(0.02, -0.66, 0.070),
  ];

  // Surface ripple. The amplitude knob is a fraction of `_ampMax`, kept low on
  // purpose: a calm ripple, not a sloshing glass.
  static const _amp = 0.05;
  static const _ampMax = 50.0;
  static const _wave1 = 132.0; // wavelength, px
  static const _wave2 = 87.0;
  static const _speed1 = 1.0;
  static const _speed2 = -1.5; // opposite drift, so crests meet and part

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = AppMoon.disc / 2;
    final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));

    _paintHalo(canvas, size, c, r);

    canvas.save();
    canvas.clipPath(disc);

    // Unfilled moon: a barely-there wash over the navy, so the empty disc is
    // present without glowing.
    canvas.drawCircle(c, r, Paint()..color = const Color(0x14FFFFFF));
    _paintCraters(
      canvas,
      c,
      r,
      body: const Color(0x1A7C8A9E),
      highlight: const Color(0x0DFFFFFF),
    );

    if (fill > 0) {
      final surface = _surfacePath(c, r, size);
      canvas.save();
      canvas.clipPath(surface);
      _paintLiquid(canvas, c, r);
      // Craters read through the liquid too — that is what keeps it a moon
      // rather than a glass of milk.
      _paintCraters(
        canvas,
        c,
        r,
        body: const Color(0x38B8C4D2),
        highlight: const Color(0x8CFFFFFF),
      );
      canvas.restore();

      _paintSurfaceLine(canvas, c, r, size);
    }

    canvas.restore();
  }

  /// Layer 1 — the halo in the 16 px ring, brightening with the fill.
  void _paintHalo(Canvas canvas, Size size, Offset c, double r) {
    final peak = ui.lerpDouble(0.06, 0.42, fill)!;
    final outer = size.width / 2;
    const glow = Color(0xFFCFE0FF);
    canvas.drawCircle(
      c,
      outer,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          outer,
          [
            glow.withValues(alpha: 0),
            glow.withValues(alpha: peak),
            glow.withValues(alpha: 0),
          ],
          // Peaks just outside the disc edge, fading to nothing at the box.
          [r / outer * 0.94, r / outer, 1.0],
        )
        ..blendMode = BlendMode.plus,
    );
  }

  /// Layers 3 and 5 — craters, painted once dim under the empty moon and once
  /// brighter under the liquid.
  void _paintCraters(
    Canvas canvas,
    Offset c,
    double r, {
    required Color body,
    required Color highlight,
  }) {
    final bodyPaint = Paint()..color = body;
    final highlightPaint = Paint()..color = highlight;
    for (final crater in _craters) {
      final centre = Offset(c.dx + crater.dx * r, c.dy + crater.dy * r);
      final radius = crater.r * r;
      canvas.drawCircle(centre, radius, bodyPaint);
      // A lighter disc offset up-left: the rim catching light.
      canvas.drawCircle(
        centre.translate(-radius * 0.28, -radius * 0.28),
        radius * 0.82,
        highlightPaint,
      );
    }
  }

  /// Layer 4 — the liquid body, shaded from an upper-left light source.
  void _paintLiquid(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-0.35 * r, -0.35 * r),
          1.25 * r,
          const [Color(0xFFFFFFFF), Color(0xFFDCE3EC)],
          const [0.0, 1.0],
        ),
    );
  }

  /// Layer 6 — the crest highlight, a soft glow pass under a crisp one.
  void _paintSurfaceLine(Canvas canvas, Offset c, double r, Size size) {
    final amplitude = _amplitude;
    if (amplitude <= 0.01 && (fill <= 0.001 || fill >= 0.999)) return;

    final line = Path();
    final y0 = _surfaceY(0, c, r);
    line.moveTo(0, y0);
    for (var x = 2.0; x <= size.width; x += 2) {
      line.lineTo(x, _surfaceY(x, c, r));
    }

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = const Color(0x99FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF),
    );
  }

  /// The amplitude tapers to nothing at both ends, so a crest never pokes
  /// above a full moon or below an empty one.
  double get _amplitude {
    final taper = math.min(fill, 1 - fill) / 0.06;
    return _amp * _ampMax * taper.clamp(0.0, 1.0);
  }

  /// Sum of two sines at different wavelengths and drift speeds.
  double _surfaceY(double x, Offset c, double r) {
    final level = c.dy + r - fill * 2 * r;
    final a = _amplitude;
    if (a == 0) return level;
    return level +
        a * 0.62 * math.sin(2 * math.pi * x / _wave1 + phase * _speed1) +
        a * 0.38 * math.sin(2 * math.pi * x / _wave2 + phase * _speed2 + 1.1);
  }

  /// Everything below the wave, as a closed region to clip the liquid to.
  Path _surfacePath(Offset c, double r, Size size) {
    final path = Path()..moveTo(0, _surfaceY(0, c, r));
    for (var x = 2.0; x <= size.width; x += 2) {
      path.lineTo(x, _surfaceY(x, c, r));
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.fill != fill || old.phase != phase;
}
