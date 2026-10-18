import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/push/push_sync.dart';
import '../../l10n/l10n.dart';
import '../../shared/providers/push_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_buttons.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_controls.dart';
import '../../ui/components/app_row.dart';
import '../../ui/components/motion.dart';

/// Above the switches in Settings while iOS has notifications off for the
/// app: what's wrong and the way to fix it.
class PushDeniedCard extends ConsumerWidget {
  const PushDeniedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AppCard(
      radius: AppRadius.listCard,
      color: context.colors.amberTint,
      shadow: const [],
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: AppIcons.bellOff,
            fill: context.colors.card,
            glyphColor: context.colors.amber,
          ),
          const SizedBox(width: AppSpace.rowGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.pushDenied,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)
                      .c(context.colors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  l.pushDeniedDetail,
                  style: AppText.caption.c(context.colors.ink2),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  // Solid, so the pill itself stands out from the amber
                  // card (WCAG 1.4.11: 5.1:1 light, 6.5:1 dark); a ghost
                  // pill was 1.02:1 against it.
                  child: IntrinsicWidth(
                    child: PrimaryButton(
                      label: l.pushOpenSettings,
                      height: 36,
                      onTap: () =>
                          ref.read(pushProvider.notifier).openSystemSettings(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The event page's own switch: notifications for this event on this
/// device. Disabled, with the reason, while iOS has notifications off or
/// the "Event notifications" switch is off. Hidden where push doesn't run.
class EventNotifyCard extends ConsumerWidget {
  const EventNotifyCard({super.key, required this.eventId, this.locked = false});

  final String eventId;

  /// The member is registered: reminders come whenever push can arrive, and
  /// the event can't be muted (set_event_notifications answers P0001
  /// registered). Shown on and locked; the rows above still say when push is
  /// off (D5).
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushProvider);
    if (!push.supported) return const SizedBox.shrink();
    final l = context.l10n;
    final warn = AppText.caption
        .copyWith(fontWeight: FontWeight.w500)
        .c(context.colors.amber);
    final enabled = push.eventEnabled(eventId);

    final Widget row;
    if (push.denied) {
      row = AppListRow(
        icon: AppIcons.bellOff,
        title: l.eventNotify,
        subtitle: l.pushDenied,
        subtitleStyle: warn,
        trailing: Pressable(
          onTap: () => ref.read(pushProvider.notifier).openSystemSettings(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(
              l.pushOpenSettings,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                  .c(context.colors.green),
            ),
          ),
        ),
      );
    } else if (!push.events) {
      // The switch lives in Settings; the row leads there.
      row = AppListRow(
        icon: AppIcons.bell,
        title: l.eventNotify,
        subtitle: l.eventNotifyEventsOff,
        subtitleStyle: warn,
        trailing: Opacity(
          opacity: 0.45,
          child: AppSwitch(value: enabled),
        ),
        onTap: () => context.push('/profile/settings'),
      );
    } else if (locked) {
      row = AppListRow(
        icon: AppIcons.bell,
        title: l.eventNotify,
        subtitle: l.regNotifyLocked,
        trailing: const Opacity(opacity: 0.45, child: AppSwitch(value: true)),
      );
    } else {
      row = AppListRow(
        icon: enabled ? AppIcons.bell : AppIcons.bellOff,
        title: l.eventNotify,
        subtitle: enabled ? l.eventNotifyOn : l.eventNotifyOff,
        trailing: AppSwitch(
          value: enabled,
          onChanged: (on) async {
            final messenger = ScaffoldMessenger.of(context);
            final outcome = await ref
                .read(pushProvider.notifier)
                .setEventEnabled(eventId, on);
            if (outcome == MuteOutcome.failed) {
              messenger.showSnackBar(SnackBar(content: Text(l.saveFailedLater)));
            }
          },
        ),
      );
    }
    // Carries its own gap, so nothing is left behind when it's hidden.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.cardGap),
      child: GroupedRows(rows: [row]),
    );
  }
}
