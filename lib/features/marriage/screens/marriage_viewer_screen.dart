import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../data/document_check.dart';
import '../data/marriage_application.dart';
import '../data/marriage_service.dart';
import '../widgets/marriage_widgets.dart';

/// Spec §8a screen 6, "View". The member's own document, fetched through a
/// 60-second signed link made for this tap and rendered on the device:
/// PDFs by PDFium from memory, photos by [Image.memory]. Nothing is written
/// to disk and no remote viewer is involved. Leaving the screen releases the
/// PDF, evicts the image from the image cache and drops the bytes.
class MarriageViewerScreen extends StatefulWidget {
  const MarriageViewerScreen({super.key, required this.application});

  final MarriageApplication application;

  @override
  State<MarriageViewerScreen> createState() => _MarriageViewerScreenState();
}

class _MarriageViewerScreenState extends State<MarriageViewerScreen> {
  Uint8List? _bytes;
  String? _error;

  /// A random per-view id for pdfrx's cache key, so nothing identifying is
  /// ever handed to the library.
  final _sourceName = 'document-${uuidV4()}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    final bytes = _bytes;
    if (bytes != null && widget.application.kind != DocumentKind.pdf) {
      MemoryImage(bytes).evict();
    }
    _bytes = null;
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final bytes = await MarriageService.downloadOwn(widget.application);
      if (mounted) setState(() => _bytes = bytes);
    } on MarriageException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final error = _error;
    final kind = widget.application.kind;
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: AppStrings.marriageEyebrow,
            title: AppStrings.yourDocument,
            subtitle: kind.label,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                0,
                AppSpace.pageGutter,
                AppSpace.pageGutter,
              ),
              child: error != null
                  ? _Message(text: error, onRetry: _load)
                  : bytes == null
                      ? const _Message(text: AppStrings.openingPrivately)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: ColoredBox(
                            color: AppColor.card,
                            child: kind == DocumentKind.pdf
                                ? _pdf(bytes)
                                : InteractiveViewer(
                                    maxScale: 5,
                                    child: Center(
                                      child: Image.memory(
                                        bytes,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.pageGutter,
              0,
              AppSpace.pageGutter,
              24,
            ),
            child: PrivacyStrip(),
          ),
        ],
      ),
    );
  }

  /// PDFium renders from [bytes] in memory. Link handling stays off (no
  /// `linkHandlerParams`, no `linkWidgetBuilder`), and pdfrx's default error
  /// banner — which links out to its issue tracker — is replaced.
  Widget _pdf(Uint8List bytes) {
    return PdfViewer.data(
      bytes,
      sourceName: _sourceName,
      params: PdfViewerParams(
        backgroundColor: AppColor.ground,
        margin: 8,
        errorBannerBuilder: (context, error, stackTrace, documentRef) =>
            const _Message(text: AppStrings.openFailed),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Align(
      alignment: Alignment.topCenter,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: AppText.body.c(AppColor.ink2)),
            if (retry != null) ...[
              const SizedBox(height: 14),
              GhostButton(label: AppStrings.tryAgain, onTap: retry),
            ],
          ],
        ),
      ),
    );
  }
}
