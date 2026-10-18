import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feature_flags.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/providers/reminders_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/motion.dart';
import '../../donations/donate_sheet.dart';
import 'reminders_sheet.dart';

/// Row 1 of the Prayer hero: the app icon's mosque on its green, the
/// organisation and the mosque, the Donate pill and (while reminders are on)
/// the reminders bell.
class HeroIdentityRow extends StatelessWidget {
  const HeroIdentityRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Row(
      children: [
        const _BrandTile(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // One line always: on a narrow phone the name scales down
              // a touch rather than wrapping.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l.organisationName,
                  key: const Key('hero-organisation'),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ).c(colors.onHero),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                l.homeMosqueLine,
                key: const Key('hero-mosque-line'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                ).c(colors.onHeroSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const DonatePill(),
        if (kPrayerRemindersEnabled) ...[
          const SizedBox(width: 8),
          _ReminderBell(),
        ],
      ],
    );
  }
}

/// The Donate pill on the hero: heart and label, white with the green text
/// of the hero's white button, so it stands out without a new colour. Opens
/// the donate sheet (funds → Safari). 36 pt tall inside a 44 pt tap target.
class DonatePill extends StatelessWidget {
  const DonatePill({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Semantics(
      // The full phrase for VoiceOver, also where the visible label is short.
      label: l.donation,
      button: true,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => showDonateSheet(context),
        child: ConstrainedBox(
          // At very large text sizes the label scales down instead of
          // crowding out the organisation's name.
          constraints: BoxConstraints(
            minWidth: 44,
            minHeight: 44,
            maxWidth: MediaQuery.sizeOf(context).width * 0.45,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              key: const Key('donate-pill'),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: colors.onHero,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: context.shadows.onGradientButton,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      AppIcons.heart,
                      size: 16,
                      color: colors.onGradientButtonText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.donatePill,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ).c(colors.onGradientButtonText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app icon's mosque, cream on the icon's green, as a small tile.
class _BrandTile extends StatelessWidget {
  const _BrandTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.brandTile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/brand/mosque-mark.png',
        width: 24,
        height: 24,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// The reminders bell on the hero. Shown only while
/// [kPrayerRemindersEnabled].
class _ReminderBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(reminderSettingsProvider).valueOrNull?.active ?? true;
    return _HeroCircleButton(
      label: context.l10n.prayerReminders,
      icon: on ? AppIcons.bell : AppIcons.bellOff,
      onTap: () => showRemindersSheet(context),
    );
  }
}

/// A white glyph in a translucent circle on the hero, 44 pt to tap.
class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.heroCircleBg,
                shape: BoxShape.circle,
              ),
              child: AppIcon(icon, size: 21, color: context.colors.onHero),
            ),
          ),
        ),
      ),
    );
  }
}
