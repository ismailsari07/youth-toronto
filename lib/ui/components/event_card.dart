import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_buttons.dart';
import 'app_card.dart';
import 'app_controls.dart';

/// Spec §7.3. Two finished variants of the same card: with a photo band, and
/// starting at the date badge when there is no photo. A photo is a layer,
/// never the content — title, date, time and location always come from text
/// fields.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onRegister,
    this.onShare,
  });

  final YouthEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final VoidCallback? onShare;

  bool get _hasActions => event.registrationUri != null;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        grouped: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) PhotoBand(url: imageUrl, date: event.dateTime),
            Padding(
              padding: imageUrl != null
                  ? const EdgeInsets.fromLTRB(18, 16, 18, 18)
                  : const EdgeInsets.all(AppSpace.cardPadding),
              child: imageUrl != null ? _body() : _bodyWithBadge(),
            ),
            if (_hasActions) ...[
              const Divider(height: 1, thickness: 1, color: AppColor.hairline),
              Padding(
                padding: const EdgeInsets.all(AppSpace.cardPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(label: 'Register', onTap: onRegister),
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

  Widget _bodyWithBadge() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateBadge(date: event.dateTime),
        const SizedBox(width: 14),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    final location = event.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event.title, style: AppText.cardTitle.c(AppColor.ink)),
        const SizedBox(height: 5),
        Text(
          heroDateTime(event.dateTime),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)
              .c(AppColor.ink2),
        ),
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
    this.date,
    this.height = 160,
  });

  final String url;
  final DateTime? date;
  final double height;

  @override
  Widget build(BuildContext context) {
    final badgeDate = date;
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
          if (badgeDate != null)
            Positioned(
              left: 16,
              top: 16,
              child: DateBadgeOnPhoto(date: badgeDate),
            ),
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
