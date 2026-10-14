import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'announcement_photo.dart';
import 'app_card.dart';
import 'app_row.dart';
import 'motion.dart';

/// Spec §7.4. One announcement: title (with the unread dot), two lines of
/// the body and how long ago it was posted. With a photo, the photo (16:9)
/// sits on top and the bookmark tile is left out. Used by the Announcements list and the Prayer home's Community
/// section.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.item,
    this.unread = false,
    this.onTap,
  });

  final Announcement item;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    return Pressable(
      onTap: onTap,
      pressedOpacity: 0.85,
      child: AppCard(
        radius: AppRadius.listCard,
        grouped: imageUrl != null,
        padding: imageUrl != null ? null : _padding,
        child: imageUrl == null
            ? _body(context, icon: true)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnnouncementPhoto.cover(
                    url: imageUrl,
                    altText: item.imageAltText,
                  ),
                  Padding(padding: _padding, child: _body(context, icon: false)),
                ],
              ),
      ),
    );
  }

  static const _padding = EdgeInsets.symmetric(vertical: 16, horizontal: 18);

  /// [icon]: the bookmark tile, shown only when there is no photo.
  Widget _body(BuildContext context, {required bool icon}) {
    return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon) ...[
              const IconBubble(
                icon: AppIcons.announcement,
                tone: RowTone.blue,
                square: true,
              ),
              const SizedBox(width: AppSpace.rowGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppText.rowTitle
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              )
                              .c(context.colors.ink),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4, top: 6),
                          decoration: BoxDecoration(
                            color: context.colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.45)
                        .c(context.colors.ink2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.postedAgo(timeAgo(context.l10n, item.date)),
                    style: const TextStyle(fontSize: 12).c(context.colors.ink3),
                  ),
                ],
              ),
            ),
          ],
        );
  }
}
