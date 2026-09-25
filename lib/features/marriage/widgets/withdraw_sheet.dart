import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../data/marriage_service.dart';

/// Spec §8a screen 7. Shows the sheet and, if the member confirms, withdraws
/// (files first, then the row). Resolves true once everything is deleted;
/// false if they kept their application.
Future<bool> showWithdrawSheet(BuildContext context) async {
  final withdrawn = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6B0F1C17), // rgba(15,28,23,.42)
    builder: (_) => const _WithdrawSheet(),
  );
  return withdrawn ?? false;
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _withdraw() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MarriageService.withdraw();
      if (mounted) Navigator.of(context).pop(true);
    } on MarriageException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return PopScope(
      // Don't let a swipe dismiss the sheet halfway through deleting.
      canPop: !_busy,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3E0),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColor.dangerTint,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  AppIcons.trash,
                  size: 24,
                  color: AppColor.danger,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.withdrawSheetTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                    .c(AppColor.ink),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.withdrawSheetBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, height: 1.45)
                    .c(AppColor.ink2),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5).c(AppColor.danger),
                ),
              ],
              const SizedBox(height: 22),
              Opacity(
                opacity: _busy ? 0.55 : 1,
                child: DestructiveButton(
                  label: _busy ? AppStrings.withdrawing : AppStrings.withdrawConfirm,
                  onTap: _busy ? null : _withdraw,
                ),
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: AppStrings.withdrawKeep,
                height: 46,
                onTap: _busy ? null : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
