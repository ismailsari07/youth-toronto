import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_row.dart';
import 'motion.dart';

/// Spec §7.4. One announcement: title (with the unread dot), two lines of
/// the body and how long ago it was posted. Used by the Announcements list
/// and the Prayer home's Community section.
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
    return Pressable(
      onTap: onTap,
      pressedOpacity: 0.85,
      child: AppCard(
        radius: AppRadius.listCard,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconBubble(
              icon: AppIcons.announcement,
              tone: RowTone.blue,
              square: true,
            ),
            const SizedBox(width: AppSpace.rowGap),
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
                              .c(AppColor.ink),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4, top: 6),
                          decoration: const BoxDecoration(
                            color: AppColor.green,
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
                        .c(AppColor.ink2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.postedAgo(timeAgo(context.l10n, item.date)),
                    style: const TextStyle(fontSize: 12).c(AppColor.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
