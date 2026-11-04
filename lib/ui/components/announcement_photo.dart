import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_tokens.dart';

/// An announcement's optional photo. The panel stores one JPEG per
/// announcement (long side ≤ 1600 px) in the public `announcement-images`
/// bucket. Every use reads the same [NetworkImage], so the card, the detail
/// page and the viewer share one download and one decode from Flutter's
/// image cache, as event photos do.
///
/// While loading, a neutral block holds the photo's place; if the image
/// fails, the photo collapses to nothing (never a broken-image icon), so the
/// card looks as it would without a photo.
class AnnouncementPhoto extends StatefulWidget {
  /// A 16:9 frame that never crops, for the cards: see [PosterFrame].
  const AnnouncementPhoto.cover({
    super.key,
    required this.url,
    this.altText,
  })  : natural = false,
        onTap = null,
        wrap = null;

  /// The whole photo at its own aspect ratio, full width, for the detail
  /// page. Until the size is known the placeholder is 16:9.
  const AnnouncementPhoto.natural({
    super.key,
    required this.url,
    this.altText,
    this.onTap,
    this.wrap,
  }) : natural = true;

  final String url;
  final String? altText;
  final bool natural;
  final VoidCallback? onTap;

  /// Frames the photo (its card, the gap below it); dropped with the photo
  /// when it fails to load.
  final Widget Function(Widget photo)? wrap;

  @override
  State<AnnouncementPhoto> createState() => _AnnouncementPhotoState();
}

class _AnnouncementPhotoState extends State<AnnouncementPhoto> {
  bool _failed = false;

  @override
  void didUpdateWidget(AnnouncementPhoto old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final alt = widget.altText?.trim();
    final placeholder = AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(color: context.colors.shimmerFrom),
    );

    void collapse() {
      // After this frame; an empty box meanwhile.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_failed) setState(() => _failed = true);
      });
    }

    final Widget image = widget.natural
        ? Image(
            image: NetworkImage(widget.url),
            width: double.infinity,
            fit: BoxFit.fitWidth,
            // Labelled below, so the placeholder carries the alt text too.
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, sync) =>
                frame == null ? placeholder : child,
            errorBuilder: (_, _, _) {
              collapse();
              return const SizedBox.shrink();
            },
          )
        : PosterFrame(image: NetworkImage(widget.url), onFailed: collapse);

    final onTap = widget.onTap;
    final labelled = alt == null || alt.isEmpty
        ? image
        : Semantics(image: true, label: alt, child: image);
    final photo = onTap == null
        ? labelled
        : Semantics(
            button: true,
            child: GestureDetector(onTap: onTap, child: labelled),
          );
    return widget.wrap?.call(photo) ?? photo;
  }
}

/// How far from the frame's shape an image may be and still fill it: a 16:9
/// photo whose pixel size rounds to 1.77 or 1.78 shouldn't grow side bars.
const _sameShapeTolerance = 0.02;

/// The card's 16:9 frame around an image of any shape, the website's rule: the
/// whole image always shows (contain), and a blurred, darkened copy of it fills
/// what's left. A 16:9 photo fills the frame and looks as it always did.
class PosterFrame extends StatefulWidget {
  const PosterFrame({super.key, required this.image, this.onFailed});

  static const aspectRatio = 16 / 9;

  final ImageProvider image;

  /// The image can't be loaded; the caller decides what's left.
  final VoidCallback? onFailed;

  /// Whether an image of this shape leaves part of the frame empty.
  static bool leavesRoom(double imageAspect) =>
      (imageAspect / aspectRatio - 1).abs() > _sameShapeTolerance;

  @override
  State<PosterFrame> createState() => _PosterFrameState();
}

class _PosterFrameState extends State<PosterFrame> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listen();
  }

  @override
  void didUpdateWidget(PosterFrame old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) {
      _aspect = null;
      _listen();
    }
  }

  /// Only the size is wanted here; the visible [Image]s read the same
  /// provider, so this adds no download.
  void _listen() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stopListening();
    final listener = ImageStreamListener(
      (info, _) {
        final aspect = info.image.width / info.image.height;
        info.dispose();
        if (mounted) setState(() => _aspect = aspect);
      },
      // The visible Image reports the failure.
      onError: (_, _) {},
    );
    _stream = stream..addListener(listener);
    _listener = listener;
  }

  void _stopListening() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect;
    final backdrop = aspect != null && PosterFrame.leavesRoom(aspect);
    return AspectRatio(
      aspectRatio: PosterFrame.aspectRatio,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (backdrop) _PosterBackdrop(image: widget.image),
            Image(
              image: widget.image,
              // Fills exactly when the shapes match; otherwise never crops.
              fit: aspect == null || backdrop ? BoxFit.contain : BoxFit.cover,
              // Labelled by AnnouncementPhoto, placeholder included.
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, sync) => frame == null
                  ? ColoredBox(color: context.colors.shimmerFrom)
                  : child,
              errorBuilder: (_, _, _) {
                widget.onFailed?.call();
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A small decode of the same image, stretched and blurred: at this size it
/// costs almost nothing to draw while a list of cards scrolls.
class _PosterBackdrop extends StatelessWidget {
  const _PosterBackdrop({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('poster-backdrop'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
              tileMode: TileMode.clamp,
            ),
            child: Image(
              image: ResizeImage(image, width: 96),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          // The same in light and dark: it sits under a photo, not on the page.
          const ColoredBox(color: Color(0x59000000)),
        ],
      ),
    );
  }
}

/// Full-screen photo: pinch to zoom, tap or swipe down to close.
/// [InteractiveViewer] is Flutter's own; no package needed.
Future<void> showAnnouncementPhotoViewer(
  BuildContext context, {
  required String url,
  String? altText,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) =>
          _PhotoViewer(url: url, altText: altText),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.url, this.altText});

  final String url;
  final String? altText;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  final _transform = TransformationController();
  double _drag = 0;

  bool get _zoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final alt = widget.altText?.trim();
    final fade = (1 - _drag.abs() / 400).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black.withValues(alpha: fade),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  // Swipe to close only at 1×; once zoomed, drags pan.
                  child: InteractiveViewer(
                    transformationController: _transform,
                    onInteractionUpdate: (d) {
                      if (d.pointerCount == 1 && !_zoomed) {
                        setState(() => _drag += d.focalPointDelta.dy);
                      }
                    },
                    onInteractionEnd: (d) {
                      if (!_zoomed &&
                          (_drag.abs() > 120 ||
                              d.velocity.pixelsPerSecond.dy.abs() > 800)) {
                        _close();
                      } else if (_drag != 0) {
                        setState(() => _drag = 0);
                      }
                    },
                    maxScale: 4,
                    child: Center(
                      child: Image(
                        image: NetworkImage(widget.url),
                        fit: BoxFit.contain,
                        semanticLabel:
                            alt == null || alt.isEmpty ? null : alt,
                        excludeFromSemantics: alt == null || alt.isEmpty,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Semantics(
                button: true,
                label: MaterialLocalizations.of(context).closeButtonTooltip,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      AppIcons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
