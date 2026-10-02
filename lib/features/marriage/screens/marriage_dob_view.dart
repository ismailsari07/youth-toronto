import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_field.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../data/marriage_service.dart';
import '../widgets/marriage_widgets.dart';

/// One-time date of birth, shown in place of Upload for accounts created
/// without one. The database allows empty → date once and blocks any later
/// change, so the copy says so before the member saves. Once saved, the
/// profile reloads and the Upload screen shows the flow or the 18+ notice.
class MarriageDobView extends ConsumerStatefulWidget {
  const MarriageDobView({super.key});

  @override
  ConsumerState<MarriageDobView> createState() => _MarriageDobViewState();
}

class _MarriageDobViewState extends ConsumerState<MarriageDobView> {
  final _field = TextEditingController();
  DateTime? _date;
  bool _busy = false;
  MarriageFailure? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _field.text = longDate(context.l10n, picked);
      _error = null;
    });
  }

  Future<void> _save() async {
    final date = _date;
    if (date == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MarriageService.saveDateOfBirth(date);
      ref.invalidate(userProfileProvider);
    } on MarriageException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.failure;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final error = _error;
    final ready = _date != null && !_busy;
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.marriageEyebrow,
            title: l.dobTitle,
            subtitle: l.dobSubtitle,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                24,
              ),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.cardPadding),
                  child: Text(
                    l.dobBody,
                    style: AppText.body.c(AppColor.ink2),
                  ),
                ),
                const SizedBox(height: AppSpace.cardGapWide),
                FieldGroup(
                  children: [
                    AppField(
                      label: l.dobField,
                      icon: AppIcons.calendar,
                      controller: _field,
                      hint: l.dobHint,
                      readOnly: true,
                      onTap: _busy ? null : _pickDate,
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error.message(l),
                    style: const TextStyle(fontSize: 13.5).c(AppColor.danger),
                  ),
                ],
                const SizedBox(height: AppSpace.cardGapWide),
                const PrivacyStrip(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomBar(
        child: Opacity(
          opacity: ready ? 1 : 0.4,
          child: PrimaryButton(
            label: _busy ? l.saving : l.dobContinue,
            onTap: ready ? _save : null,
          ),
        ),
      ),
    );
  }
}
