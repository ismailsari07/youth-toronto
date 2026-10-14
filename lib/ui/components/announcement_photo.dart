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
  /// Cropped to 16:9 (cover, top-weighted), for the cards.
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

    final image = Image(
      image: NetworkImage(widget.url),
      width: double.infinity,
      fit: widget.natural ? BoxFit.fitWidth : BoxFit.cover,
      // Top-weighted crop, so faces and poster headers survive in portrait
      // photos.
      alignment: widget.natural ? Alignment.center : const Alignment(0, -0.4),
      // Labelled below, so the placeholder carries the alt text too.
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, sync) {
        if (frame == null) return placeholder;
        return widget.natural
            ? child
            : AspectRatio(aspectRatio: 16 / 9, child: child);
      },
      errorBuilder: (_, _, _) {
        // Collapse after this frame; returning an empty box meanwhile.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_failed) setState(() => _failed = true);
        });
        return const SizedBox.shrink();
      },
    );

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
