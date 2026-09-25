import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_strings.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../data/document_check.dart';
import '../data/document_picker.dart';
import '../data/document_upload.dart';
import '../data/marriage_service.dart';
import '../marriage_provider.dart';
import '../marriage_routes.dart';
import '../widgets/marriage_widgets.dart';
import 'marriage_dob_view.dart';

/// Spec §8a screens 2–4, plus the two gates in front of them: a one-time
/// date of birth for accounts created without one, and the 18+ notice.
///
/// Picking a file uploads it immediately — there is nothing else to fill in.
/// With [replacing], a successful upload swaps the member's existing
/// document and returns to Status instead of showing Received.
class MarriageUploadScreen extends ConsumerWidget {
  const MarriageUploadScreen({super.key, this.replacing = false});

  final bool replacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return switch (profile) {
      AsyncData(value: final row?) =>
        switch (eligibilityFor(row['date_of_birth'] as String?)) {
          MarriageEligibility.needsDateOfBirth => const MarriageDobView(),
          MarriageEligibility.underAge => const _NotEligibleView(),
          MarriageEligibility.eligible => _UploadFlow(replacing: replacing),
        },
      // No profile row, or it failed to load (userProfileProvider maps
      // errors to null). Never guess "no date of birth" from that.
      AsyncData() || AsyncError() => _ProfileUnavailableView(
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      _ => const _Frame(title: AppStrings.uploadTitle, body: []),
    };
  }
}

/// Nav bar, scrolling body and optional sticky bar shared by every state.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    this.subtitle,
    required this.body,
    this.bottom,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> body;
  final Widget? bottom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: AppStrings.marriageEyebrow,
            title: title,
            subtitle: subtitle,
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                24,
              ),
              children: body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottom == null ? null : StickyBottomBar(child: bottom!),
    );
  }
}

// ── Upload flow ─────────────────────────────────────────────────────────────

sealed class _Stage {
  const _Stage();
}

/// Nothing chosen yet. [error] is shown after a failed or cancelled upload.
final class _Choosing extends _Stage {
  const _Choosing({this.error});
  final String? error;
}

/// Picked; being checked and cleaned on the device.
final class _Preparing extends _Stage {
  const _Preparing(this.rawSize);
  final int rawSize;
}

final class _Uploading extends _Stage {
  const _Uploading(this.upload, this.path, this.document);
  final DocumentUpload upload;
  final String path;
  final AcceptedDocument document;
}

final class _Rejected extends _Stage {
  const _Rejected(this.reason, this.size, this.kind);
  final RejectReason reason;
  final int size;
  final DocumentKind? kind;
}

class _UploadFlow extends ConsumerStatefulWidget {
  const _UploadFlow({required this.replacing});

  final bool replacing;

  @override
  ConsumerState<_UploadFlow> createState() => _UploadFlowState();
}

class _UploadFlowState extends ConsumerState<_UploadFlow> {
  _Stage _stage = const _Choosing();

  bool get _busy => _stage is _Preparing || _stage is _Uploading;

  @override
  void dispose() {
    // Leaving mid-upload cancels it; `_upload` is still awaiting it and
    // removes whatever reached the server.
    final stage = _stage;
    if (stage is _Uploading && stage.upload.progress.value < 1) {
      stage.upload.cancel();
    }
    super.dispose();
  }

  void _setStage(_Stage next) {
    if (mounted) setState(() => _stage = next);
  }

  Future<void> _pick(Future<Uint8List?> Function() picker) async {
    if (_busy) return;
    final Uint8List? raw;
    try {
      raw = await picker();
    } catch (_) {
      _setStage(const _Rejected(RejectReason.unreadable, 0, null));
      return;
    }
    if (raw == null || !mounted) return;

    _setStage(_Preparing(raw.length));
    final prepared = await prepareDocument(raw);
    if (!mounted) return;
    switch (prepared) {
      case RejectedDocument(:final reason, :final size, :final kind):
        _setStage(_Rejected(reason, size ?? raw.length, kind));
      case AcceptedDocument document:
        await _upload(document);
    }
  }

  Future<void> _upload(AcceptedDocument document) async {
    final ({DocumentUpload upload, String path}) started;
    try {
      started = await MarriageService.startUpload(document);
    } catch (_) {
      _setStage(const _Choosing(error: AppStrings.uploadFailed));
      return;
    }
    if (!mounted) {
      started.upload.cancel();
      return;
    }
    _setStage(_Uploading(started.upload, started.path, document));

    try {
      await started.upload.done;
    } on UploadFailed catch (e) {
      await MarriageService.discard(started.path);
      if (!e.cancelled) {
        _setStage(const _Choosing(error: AppStrings.uploadFailed));
      }
      return;
    }

    try {
      await MarriageService.commit(started.path, document);
    } on MarriageException catch (e) {
      _setStage(_Choosing(error: e.message));
      return;
    }
    ref.invalidate(myApplicationProvider);
    if (!mounted) return;
    if (widget.replacing) {
      context.pop();
    } else {
      context.pushReplacement(MarriageRoutes.received);
    }
  }

  void _cancel() {
    final stage = _stage;
    if (stage is! _Uploading || stage.upload.progress.value >= 1) return;
    stage.upload.cancel();
    // `_upload` removes the partial object once `done` settles.
    _setStage(const _Choosing());
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return _Frame(
      title: AppStrings.uploadTitle,
      subtitle: widget.replacing
          ? AppStrings.replaceSubtitle
          : AppStrings.uploadSubtitle,
      onBack: () => context.pop(),
      body: [
        switch (stage) {
          _Choosing(:final error) => _ChooseCard(
              error: error,
              onFiles: () => _pick(DocumentPicker.pickFile),
              onPhotos: () => _pick(DocumentPicker.pickPhoto),
            ),
          _Preparing(:final rawSize) => _ProgressCard(
              caption: fileSize(rawSize),
              label: AppStrings.preparingPrivately,
              progress: null,
            ),
          _Uploading(:final upload, :final document) =>
            ValueListenableBuilder<double>(
              valueListenable: upload.progress,
              builder: (_, value, _) => _ProgressCard(
                typeLabel: document.kind.label,
                caption: '${fileSize(document.size)} · ${document.kind.label}',
                label: AppStrings.uploadingPrivately,
                progress: value,
                onCancel: value < 1 ? _cancel : null,
              ),
            ),
          _Rejected() => _RejectedCard(
              rejected: stage,
              onFiles: () => _pick(DocumentPicker.pickFile),
              onPhotos: () => _pick(DocumentPicker.pickPhoto),
            ),
        },
        const SizedBox(height: AppSpace.cardGapWide),
        const SectionHeader(title: AppStrings.whatToInclude),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.whatToIncludeBody1,
                style: AppText.body.c(AppColor.ink2),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.whatToIncludeBody2,
                style: AppText.body.c(AppColor.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const PrivacyStrip(),
      ],
      bottom: _busy
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: 0.55,
                  child: PrimaryButton(label: AppStrings.uploading),
                ),
                StickyCaption(AppStrings.keepAppOpen),
              ],
            )
          : const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DisabledSubmitButton(),
                StickyCaption(AppStrings.chooseFileToContinue),
              ],
            ),
    );
  }
}

class _PickButtons extends StatelessWidget {
  const _PickButtons({required this.onFiles, required this.onPhotos});

  final VoidCallback onFiles;
  final VoidCallback onPhotos;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GhostButton(
            label: AppStrings.files,
            icon: AppIcons.document,
            height: 46,
            onTap: onFiles,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GhostButton(
            label: AppStrings.photos,
            icon: AppIcons.photo,
            height: 46,
            onTap: onPhotos,
          ),
        ),
      ],
    );
  }
}

/// Screen 2: the dashed drop zone.
class _ChooseCard extends StatelessWidget {
  const _ChooseCard({
    required this.onFiles,
    required this.onPhotos,
    this.error,
  });

  final VoidCallback onFiles;
  final VoidCallback onPhotos;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final message = error;
    return DropZoneCard(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColor.greenTint,
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              AppIcons.upload,
              size: 26,
              color: AppColor.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.chooseOneFile,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)
                .c(AppColor.ink),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.fileRules,
            style: const TextStyle(fontSize: 13).c(AppColor.ink3),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.4)
                  .c(AppColor.danger),
            ),
          ],
          const SizedBox(height: 18),
          _PickButtons(onFiles: onFiles, onPhotos: onPhotos),
        ],
      ),
    );
  }
}

/// Screen 3: the file card with its progress. [progress] null means the
/// file is still being checked on the device (indeterminate, no cancel).
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    this.typeLabel = '',
    required this.caption,
    required this.label,
    required this.progress,
    this.onCancel,
  });

  final String typeLabel;
  final String caption;
  final String label;
  final double? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.cardPadding),
      child: Column(
        children: [
          FileTile(
            typeLabel: typeLabel,
            caption: caption,
            trailing: onCancel == null
                ? null
                : CircleIconButton(
                    icon: AppIcons.close,
                    size: 44,
                    iconSize: 18,
                    bordered: true,
                    onTap: onCancel,
                  ),
          ),
          const SizedBox(height: 16),
          UploadProgressBar(value: value ?? 0),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ).c(AppColor.greenDark),
                ),
              ),
              if (value != null)
                Text(
                  '${(value * 100).floor()}%',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ).c(AppColor.ink2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Screen 4: what was wrong, and the pick buttons again.
class _RejectedCard extends StatelessWidget {
  const _RejectedCard({
    required this.rejected,
    required this.onFiles,
    required this.onPhotos,
  });

  final _Rejected rejected;
  final VoidCallback onFiles;
  final VoidCallback onPhotos;

  @override
  Widget build(BuildContext context) {
    final (why, explanation) = switch (rejected.reason) {
      RejectReason.tooLarge => (AppStrings.tooLarge, AppStrings.tooLargeBody),
      RejectReason.unsupportedType => (
          AppStrings.unsupportedType,
          AppStrings.unsupportedTypeBody,
        ),
      RejectReason.unreadable => (AppStrings.cantBeRead, AppStrings.unreadableFile),
    };
    final caption =
        rejected.size > 0 ? '${fileSize(rejected.size)} · $why' : why;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.cardPadding),
      border: Border.all(color: const Color(0xFFE9C3BF), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FileTile(
            danger: true,
            typeLabel: rejected.kind?.label ?? '',
            caption: caption,
            captionColor: AppColor.danger,
            captionWeight: FontWeight.w600,
          ),
          const SizedBox(height: 14),
          Text(
            explanation,
            style: const TextStyle(fontSize: 13.5, height: 1.45)
                .c(AppColor.ink2),
          ),
          const SizedBox(height: 16),
          _PickButtons(onFiles: onFiles, onPhotos: onPhotos),
        ],
      ),
    );
  }
}

// ── Gates in front of the flow ──────────────────────────────────────────────

class _NotEligibleView extends StatelessWidget {
  const _NotEligibleView();

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: AppStrings.marriageGateTitle,
      subtitle: AppStrings.marriageGateSubtitle,
      body: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBubble(
                    icon: AppIcons.documentLock,
                    size: 44,
                    iconSize: 21,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      AppStrings.notEligibleTitle,
                      style: AppText.cardTitle.c(AppColor.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.notEligibleBody,
                style: AppText.body.c(AppColor.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const PrivacyStrip(),
      ],
    );
  }
}

class _ProfileUnavailableView extends StatelessWidget {
  const _ProfileUnavailableView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: AppStrings.uploadTitle,
      subtitle: AppStrings.uploadSubtitle,
      body: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.detailsUnavailable,
                style: AppText.body.c(AppColor.ink2),
              ),
              const SizedBox(height: 14),
              GhostButton(label: AppStrings.tryAgain, onTap: onRetry),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const PrivacyStrip(),
      ],
    );
  }
}
