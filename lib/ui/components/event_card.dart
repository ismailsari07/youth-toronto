import 'package:flutter/material.dart';

import '../../core/event_schedule.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_buttons.dart';
import 'app_card.dart';
import 'app_controls.dart';
import 'event_when_line.dart';

/// Spec §7.3. Two finished variants of the same card: with a photo band, and
/// starting at the left element when there is no photo. A photo is a layer,
/// never the content — title, date, time and location always come from text
/// fields.
///
/// The left element is the square date tile for an event with a real date
/// (one-off, including prayer-linked one-offs). A recurring programme gets a
/// light circle with its category's icon and a small repeat mark; its
/// cadence is spelled out by the when line ("Every Monday · 7:30 PM"), so
/// the list carries no separate pill.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.upcoming,
    this.onTap,
    this.onRegister,
    this.onShare,
  });

  final UpcomingEvent upcoming;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final VoidCallback? onShare;

  bool get _hasActions => upcoming.event.registrationUri != null;
  bool get _recurring => upcoming.event.repeats.isRecurring;

  RecurringBadge _recurringBadge(
    AppLocalizations l, {
    bool onPhoto = false,
  }) =>
      RecurringBadge(
        icon: AppIcons.forEventCategory(upcoming.event.category),
        spokenLabel: recurrenceSpoken(l, upcoming.event.repeats),
        onPhoto: onPhoto,
      );

  @override
  Widget build(BuildContext context) {
    final imageUrl = upcoming.event.imageUrl;
    final l = context.l10n;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        grouped: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              PhotoBand(
                url: imageUrl,
                topLeft: _recurring
                    ? _recurringBadge(l, onPhoto: true)
                    : DateBadgeOnPhoto(date: upcoming.startsAt),
              ),
            Padding(
              padding: imageUrl != null
                  ? const EdgeInsets.fromLTRB(18, 16, 18, 18)
                  : const EdgeInsets.all(AppSpace.cardPadding),
              child: imageUrl != null ? _body() : _bodyWithBadge(l),
            ),
            if (_hasActions) ...[
              const Divider(height: 1, thickness: 1, color: AppColor.hairline),
              Padding(
                padding: const EdgeInsets.all(AppSpace.cardPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(label: l.register, onTap: onRegister),
                    ),
                    const SizedBox(width: 10),
                    CircleIconButton(icon: AppIcons.share, onTap: onShare),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bodyWithBadge(AppLocalizations l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recurring
            ? _recurringBadge(l)
            : DateBadge(date: upcoming.startsAt),
        const SizedBox(width: 14),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    final location = upcoming.event.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(upcoming.event.title, style: AppText.cardTitle.c(AppColor.ink)),
        const SizedBox(height: 5),
        EventWhenLine(upcoming: upcoming),
        if (location != null && location.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const AppIcon(AppIcons.pin, size: 13, color: AppColor.ink3),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.c(AppColor.ink3),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The photo band. While the mosque has no real photography — and whenever an
/// image fails to load — the mosque silhouette stands in on its own ground,
/// which is a finished design rather than a grey "no image" box.
class PhotoBand extends StatelessWidget {
  const PhotoBand({
    super.key,
    required this.url,
    this.topLeft,
    this.height = 160,
  });

  final String url;

  /// The date tile or recurring badge, 16 / 16 from the top-left.
  final Widget? topLeft;
  final double height;

  @override
  Widget build(BuildContext context) {
    final left = topLeft;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const PhotoBandFallback(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const PhotoBandFallback(),
            ),
          ),
          if (left != null) Positioned(left: 16, top: 16, child: left),
        ],
      ),
    );
  }
}

class PhotoBandFallback extends StatelessWidget {
  const PhotoBandFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.photoBandBg,
      alignment: Alignment.bottomCenter,
      child: const AppIllustration(
        AppIllustration.mosqueSilhouette,
        color: AppColor.photoBandArt,
        fit: BoxFit.contain,
      ),
    );
  }
}
