import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/news/mosque_news.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_tokens.dart';
import 'announcement_photo.dart';

/// A news photo in its 4:5 frame. A crop fills it; "Sığdır" shows the whole
/// photo over the same blurred, darkened fill as announcement cards. A photo
/// that fails keeps the frame, so a gallery never jumps. The home card asks
/// for a 16:9 frame that always crops ([alwaysCover]), centred on the photo.
class NewsPhotoFrame extends StatelessWidget {
  const NewsPhotoFrame({
    super.key,
    required this.photo,
    this.fallbackLabel,
    this.aspectRatio = defaultAspectRatio,
    this.alwaysCover = false,
  });

  static const defaultAspectRatio = 4 / 5;

  final NewsPhoto photo;
  final double aspectRatio;
  final bool alwaysCover;

  /// Read by screen readers when the photo has no text of its own.
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final image = NetworkImage(photo.url);
    final label = photo.altText ?? fallbackLabel;
    final contain = photo.contain && !alwaysCover;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Semantics(
        image: true,
        label: label,
        child: ClipRect(
          child: ColoredBox(
            color: context.colors.shimmerFrom,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (contain) PosterBackdrop(image: image),
                Image(
                  image: image,
                  fit: contain ? BoxFit.contain : BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen gallery: the clean photo, no fill. Swipe between photos, pinch
/// to zoom ([InteractiveViewer], no package); while zoomed or pinching, drags
/// pan the photo instead of changing the page.
Future<void> showNewsViewer(
  BuildContext context, {
  required List<NewsPhoto> photos,
  required int start,
  required String title,
  ValueChanged<int>? onPageChanged,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => NewsViewer(
        photos: photos,
        start: start,
        title: title,
        onPageChanged: onPageChanged,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class NewsViewer extends StatefulWidget {
  const NewsViewer({
    super.key,
    required this.photos,
    required this.start,
    required this.title,
    this.onPageChanged,
  });

  final List<NewsPhoto> photos;
  final int start;
  final String title;
  final ValueChanged<int>? onPageChanged;

  @override
  State<NewsViewer> createState() => _NewsViewerState();
}

class _NewsViewerState extends State<NewsViewer> {
  late final PageController _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;
  bool _zoomed = false;
  int _pointers = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _setPointers(int count) {
    final wasLocked = _pointers >= 2;
    _pointers = count;
    if (wasLocked != _pointers >= 2) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final many = widget.photos.length > 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _setPointers(_pointers + 1),
                onPointerUp: (_) => _setPointers(_pointers - 1),
                onPointerCancel: (_) => _setPointers(_pointers - 1),
                child: PageView.builder(
                  controller: _pages,
                  physics: _zoomed || _pointers >= 2
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: widget.photos.length,
                  onPageChanged: (i) {
                    setState(() {
                      _index = i;
                      _zoomed = false;
                    });
                    widget.onPageChanged?.call(i);
                  },
                  itemBuilder: (_, i) => _ZoomablePhoto(
                    photo: widget.photos[i],
                    title: widget.title,
                    onZoomChanged: (z) {
                      if (z != _zoomed) setState(() => _zoomed = z);
                    },
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
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
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
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: IgnorePointer(
                child: Text(
                  many
                      ? '${_index + 1} / ${widget.photos.length} · ${l.newsViewerHint}'
                      : l.newsViewerHintOne,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.86),
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

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    required this.photo,
    required this.title,
    required this.onZoomChanged,
  });

  final NewsPhoto photo;
  final String title;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _transform = TransformationController();
  bool _zoomed = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _update() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: 4,
      // At 1× a one-finger drag belongs to the page view.
      panEnabled: _zoomed,
      onInteractionUpdate: (_) => _update(),
      onInteractionEnd: (_) => _update(),
      child: Center(
        child: Image(
          image: NetworkImage(widget.photo.url),
          fit: BoxFit.contain,
          semanticLabel: widget.photo.altText ?? widget.title,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
