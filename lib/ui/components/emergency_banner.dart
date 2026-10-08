import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_bundle.dart';
import '../../l10n/l10n.dart';
import '../../shared/providers/content_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_card.dart';

/// The panel's emergency banner, at the top of the Prayer home (spec §7.1
/// step 0). The app decides for itself whether it shows: enabled, with
/// text, and before `ends_at` (an admin signed in receives it even while
/// it's off, and a cached copy must expire offline). Leaves no gap when
/// there is nothing to show; disappears on its own at `ends_at`.
class EmergencyBanner extends ConsumerStatefulWidget {
  const EmergencyBanner({super.key});

  @override
  ConsumerState<EmergencyBanner> createState() => _EmergencyBannerState();
}

class _EmergencyBannerState extends ConsumerState<EmergencyBanner> {
  Timer? _expiry;

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  /// Rebuilds once the banner's end passes while it is on screen.
  void _scheduleExpiry(DateTime? endsAt, DateTime now) {
    _expiry?.cancel();
    _expiry = endsAt == null
        ? null
        : Timer(endsAt.difference(now), () {
            if (mounted) setState(() {});
          });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final banner = ref.watch(contentProvider).activeBanner(now);
    _scheduleExpiry(banner?.endsAt, now);
    if (banner == null) return const SizedBox.shrink();

    final (fill, ink, icon) = switch (banner.tone) {
      BannerTone.info => (AppColor.blueTint, AppColor.blue, AppIcons.info),
      BannerTone.warning => (
        AppColor.amberTint,
        AppColor.amber,
        AppIcons.alert,
      ),
      BannerTone.urgent => (
        AppColor.dangerTint,
        AppColor.danger,
        AppIcons.alert,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: AppCard(
          radius: AppRadius.listCard,
          color: fill,
          shadow: const [],
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, size: 20, color: ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  banner.text.resolve(context.l10n.localeName),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ).c(ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
