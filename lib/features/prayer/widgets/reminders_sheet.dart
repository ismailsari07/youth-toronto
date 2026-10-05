import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notification_service.dart';
import '../../../core/notification_sounds.dart';
import '../../../core/reminder_settings.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/reminders_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_sheet.dart';
import '../../../ui/components/motion.dart';

/// The one place prayer notifications are set: opened by the Prayer home's
/// bell and by the summary rows on Prayer, Profile and Settings. All read
/// and write [reminderSettingsProvider], so they always agree.
Future<void> showRemindersSheet(BuildContext context) =>
    showAppSheet<void>(context: context, builder: (_) => const _RemindersSheet());

/// "Off", "On · At athan time" or "On · 5 min before iqamah".
String remindersSummary(AppLocalizations l, ReminderSettings s) => !s.active
    ? l.remindersSummaryOff
    : s.timing == ReminderTiming.atAthan
        ? l.remindersSummaryAthan
        : l.remindersSummaryIqamah;

/// The settings row for prayer notifications: a summary that opens the
/// sheet. The same on Prayer, Profile and Settings.
class RemindersRow extends ConsumerWidget {
  const RemindersRow({super.key, this.divided = false, this.background});

  final bool divided;
  final Color? background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(reminderSettingsProvider).valueOrNull ??
        const ReminderSettings();
    return AppListRow(
      divided: divided,
      background: background,
      icon: settings.active ? AppIcons.bell : AppIcons.bellOff,
      title: l.prayerReminders,
      subtitle: remindersSummary(l, settings),
      trailing: const RowChevron(),
      onTap: () => showRemindersSheet(context),
    );
  }
}

class _RemindersSheet extends ConsumerStatefulWidget {
  const _RemindersSheet();

  @override
  ConsumerState<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends ConsumerState<_RemindersSheet> {
  /// iOS's answer: false only once notifications are refused or switched
  /// off; null where it can't be told.
  bool? _allowed;
  late final AppLifecycleListener _lifecycle;

  /// The sound being previewed, until it ends or is stopped.
  ReminderSound? _playing;
  Timer? _playTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    // Back from the Settings app: show the new state straight away.
    _lifecycle = AppLifecycleListener(onResume: _checkPermission);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _playTimer?.cancel();
    if (_playing != null) NotificationSounds.stopPreview();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final allowed = await NotificationService.notificationsAllowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  ReminderSettingsNotifier get _settings =>
      ref.read(reminderSettingsProvider.notifier);

  Future<void> _setEnabled(bool on) async {
    // The sync asks for permission first when turning on, so check after.
    await _settings.setEnabled(on);
    await _checkPermission();
  }

  Future<void> _togglePreview(ReminderSound sound) async {
    _playTimer?.cancel();
    if (_playing == sound) {
      setState(() => _playing = null);
      await NotificationSounds.stopPreview();
      return;
    }
    final length = await NotificationSounds.preview(sound);
    if (!mounted) return;
    setState(() => _playing = length == null ? null : sound);
    if (length != null) {
      _playTimer = Timer(length, () {
        if (mounted) setState(() => _playing = null);
      });
    }
  }

  Future<void> _openSettings() async {
    try {
      // UIApplication.openSettingsURLString: the app's own Settings page.
      await launchUrl(Uri.parse('app-settings:'));
    } catch (_) {
      /* nothing to do: the button simply doesn't navigate */
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(reminderSettingsProvider);
    final settings = async.valueOrNull ?? const ReminderSettings();
    final ready = async.hasValue;
    final off = !settings.enabled;
    final blocked = settings.active && _allowed == false;
    final athanBundled = ref.watch(athanBundledProvider).valueOrNull ?? false;
    final sound = settings.soundWith(athanBundled: athanBundled);
    final atAthan = settings.timing == ReminderTiming.atAthan;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.ground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE3E0),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.prayerReminders,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)
                    .c(AppColor.ink),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GroupedRows(
                        rows: [
                          AppListRow(
                            icon: settings.active
                                ? AppIcons.bell
                                : AppIcons.bellOff,
                            title: l.prayerNotifications,
                            trailing: AppSwitch(
                              value: settings.active,
                              onChanged: ready ? _setEnabled : null,
                            ),
                          ),
                        ],
                      ),
                      FadeSwitch(
                        animateSize: true,
                        child: blocked
                            ? Padding(
                                key: const ValueKey('blocked'),
                                padding: const EdgeInsets.only(top: 14),
                                child: _BlockedNote(onOpenSettings: _openSettings),
                              )
                            : const SizedBox(
                                key: ValueKey('ok'),
                                width: double.infinity,
                              ),
                      ),
                      const SizedBox(height: AppSpace.cardGapWide),
                      _Section(
                        title: l.remindersPrayers,
                        off: off,
                        rows: [
                          for (final (i, p)
                              in ReminderSettings.allPrayers.indexed)
                            AppListRow(
                              divided: i > 0,
                              icon: AppIcons.forPrayer(p),
                              title: prayerLabel(l, p),
                              trailing: AppSwitch(
                                value: settings.prayers.contains(p),
                                onChanged: ready && !off
                                    ? (on) => _settings.setPrayer(p, on)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.cardGapWide),
                      _Section(
                        title: l.remindersNotifyMe,
                        off: off,
                        rows: [
                          _ChoiceRow(
                            title: l.notifyAtAthan,
                            selected: atAthan,
                            onTap: () =>
                                _settings.setTiming(ReminderTiming.atAthan),
                          ),
                          _ChoiceRow(
                            divided: true,
                            title: l.notifyBeforeIqamah,
                            selected: !atAthan,
                            onTap: () => _settings
                                .setTiming(ReminderTiming.beforeIqamah),
                          ),
                        ],
                      ),
                      // The sound only applies at athan time.
                      FadeSwitch(
                        animateSize: true,
                        child: atAthan
                            ? Padding(
                                key: const ValueKey('sound'),
                                padding: const EdgeInsets.only(
                                  top: AppSpace.cardGapWide,
                                ),
                                child: _Section(
                                  title: l.notificationSound,
                                  off: off,
                                  rows: [
                                    for (final (i, s) in [
                                      if (athanBundled) ReminderSound.athan,
                                      ReminderSound.standard,
                                      ReminderSound.silent,
                                    ].indexed)
                                      _ChoiceRow(
                                        divided: i > 0,
                                        title: _soundName(l, s),
                                        selected: s == sound,
                                        onTap: () => _settings.setSound(s),
                                        preview: s == ReminderSound.silent
                                            ? null
                                            : _PreviewButton(
                                                playing: _playing == s,
                                                onTap: () => _togglePreview(s),
                                              ),
                                      ),
                                  ],
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('no-sound'),
                                width: double.infinity,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _soundName(AppLocalizations l, ReminderSound s) => switch (s) {
        ReminderSound.athan => l.soundAthan,
        ReminderSound.standard => l.soundStandard,
        ReminderSound.silent => l.soundSilent,
      };
}

/// A titled group of rows, faded and locked while the master switch is off.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.off, required this.rows});

  final String title;
  final bool off;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: off,
      child: AnimatedOpacity(
        opacity: off ? 0.45 : 1,
        duration: AppMotion.fade(context, AppMotion.base),
        curve: AppMotion.standard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: title),
            const SizedBox(height: AppSpace.sectionHeaderGap),
            GroupedRows(rows: rows),
          ],
        ),
      ),
    );
  }
}

/// One option of a single choice: a check on the selected one.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.divided = false,
    this.preview,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool divided;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final previewButton = preview;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AppListRow(
        divided: divided,
        title: title,
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (previewButton != null) ...[
              previewButton,
              const SizedBox(width: 12),
            ],
            SizedBox(
              width: 22,
              child: selected
                  ? const AppIcon(AppIcons.check, size: 22, color: AppColor.green)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      label: playing ? l.stopSound : l.playSound,
      button: true,
      excludeSemantics: true,
      child: CircleIconButton(
        icon: playing ? AppIcons.stop : AppIcons.play,
        size: 34,
        iconSize: 15,
        onTap: onTap,
      ),
    );
  }
}

class _BlockedNote extends StatelessWidget {
  const _BlockedNote({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.remindersDeniedNote,
          style: const TextStyle(fontSize: 13.5, height: 1.45).c(AppColor.ink2),
        ),
        const SizedBox(height: 12),
        GhostButton(label: l.openSettings, onTap: onOpenSettings),
      ],
    );
  }
}
