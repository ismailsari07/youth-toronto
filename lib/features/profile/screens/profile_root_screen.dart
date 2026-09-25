import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/reminder_sync.dart';
import '../../../l10n/app_strings.dart';
import '../../marriage/data/marriage_application.dart';
import '../../marriage/marriage_provider.dart';
import '../../marriage/marriage_routes.dart';
import '../../marriage/widgets/marriage_widgets.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_controls.dart';
import '../../../ui/components/app_row.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/refreshable.dart';

/// Spec §7.9. Never empty: settings exist whether or not anyone is signed in.
class ProfileRootScreen extends ConsumerStatefulWidget {
  const ProfileRootScreen({super.key});

  @override
  ConsumerState<ProfileRootScreen> createState() => _ProfileRootScreenState();
}

class _ProfileRootScreenState extends ConsumerState<ProfileRootScreen> {
  bool? _remindersOn;

  @override
  void initState() {
    super.initState();
    ReminderSync.isEnabled().then((on) {
      if (mounted) setState(() => _remindersOn = on);
    });
  }

  Future<void> _setReminders(bool value) async {
    setState(() => _remindersOn = value);
    await ReminderSync.setEnabled(value);
    ReminderSync.sync();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return RefreshableList(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(myApplicationProvider);
        await ref.read(userProfileProvider.future);
      },
      padding: EdgeInsets.fromLTRB(
        AppSpace.pageGutter,
        topInset(context),
        AppSpace.pageGutter,
        AppSpace.scrollBottomInset,
      ),
      children: [
        GradientTabHeader(
          title: 'Profile',
          row: user == null ? _signedOutRow() : _identityRow(user, profile),
          footer: user != null
              ? null
              : Column(
                  children: [
                    PrimaryOnGradientButton(
                      label: 'Sign in',
                      onTap: () => context.push('/profile/sign-in'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedOnGradientButton(
                      label: 'Create an account',
                      onTap: () => context.push('/profile/sign-up'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const SectionHeader(title: AppStrings.mosqueServices),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        GroupedRows(
          rows: [
            _marriageRow(
              user == null ? null : ref.watch(myApplicationProvider).valueOrNull,
            ),
          ],
        ),
        if (user != null) ...[
          const SizedBox(height: AppSpace.cardGapWide),
          const SectionHeader(title: 'Your details'),
          const SizedBox(height: AppSpace.sectionHeaderGap),
          _detailsCard(user, profile),
        ],
        const SizedBox(height: AppSpace.cardGapWide),
        const SectionHeader(title: 'Settings'),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        GroupedRows(
          rows: [
            AppListRow(
              icon: AppIcons.bell,
              title: 'Prayer reminders',
              subtitle: '5 minutes before each iqamah',
              trailing: AppSwitch(
                value: _remindersOn ?? true,
                onChanged: _remindersOn == null ? null : _setReminders,
              ),
            ),
            AppListRow(
              divided: true,
              icon: AppIcons.globe,
              title: 'Language',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EN',
                    style: const TextStyle(fontSize: 13.5).c(AppColor.ink3),
                  ),
                  const SizedBox(width: 6),
                  const RowChevron(),
                ],
              ),
            ),
            if (user != null)
              AppListRow(
                divided: true,
                icon: AppIcons.person,
                title: 'Settings',
                subtitle: 'Reminders, language, account',
                trailing: const RowChevron(),
                onTap: () => context.push('/profile/settings'),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        GroupedRows(
          rows: [
            AppListRow(
              icon: AppIcons.pin,
              title: 'Mosque & contact',
              trailing: const RowChevron(),
              onTap: () => context.push('/profile/mosque'),
            ),
            const AppListRow(
              divided: true,
              icon: AppIcons.info,
              title: 'About this app',
              subtitle: 'Version 1.0',
              trailing: RowChevron(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Prayer times, events and announcements work without an account.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.5).c(AppColor.ink3),
        ),
      ],
    );
  }

  /// Spec §8a placement table. Signed out or not applied: the plain row.
  /// Applied: "Submitted 12 September" and the "Under review" pill. While
  /// the application loads (or if it can't), the plain row shows — tapping
  /// it still resolves the right screen.
  Widget _marriageRow(MarriageApplication? application) {
    return AppListRow(
      icon: AppIcons.documentLock,
      title: AppStrings.marriageService,
      subtitle: application == null
          ? AppStrings.marriageServiceRow
          : AppStrings.submittedOn(dayMonth(application.createdAt)),
      trailing: application == null
          ? const RowChevron()
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [UnderReviewPill(), SizedBox(width: 8), RowChevron()],
            ),
      onTap: () => MarriageRoutes.open(context, ref),
    );
  }

  Widget _signedOutRow() => const HeroRow(
        icon: AppIcons.person,
        title: "You're not signed in",
        subtitle: 'Sign in to register for events and keep your reminders '
            'across devices.',
        circleSize: 46,
      );

  Widget _identityRow(User user, Map<String, dynamic>? profile) {
    final name = (profile?['full_name'] as String?) ??
        user.email?.split('@').first ??
        'Member';
    final since = _memberSince(profile?['created_at'] as String?);
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColor.heroCircleBg,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(name),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ).c(AppColor.onHero),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ).c(AppColor.onHero),
              ),
              const SizedBox(height: 2),
              Text(
                since,
                style: AppText.countdownSub.c(AppColor.onHeroSecondary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/profile/settings'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColor.heroCircleBg,
              shape: BoxShape.circle,
            ),
            child: const RowChevron(color: AppColor.onHero, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _detailsCard(User user, Map<String, dynamic>? profile) {
    final phone = profile?['phone'] as String?;
    final dob = profile?['date_of_birth'] as String?;
    return GroupedRows(
      rows: [
        AppListRow(
          icon: AppIcons.person,
          title: (profile?['full_name'] as String?) ?? '—',
          subtitle: 'Name',
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.mail,
          title: user.email ?? '—',
          subtitle: 'Email',
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.phone,
          title: phone == null || phone.isEmpty ? 'Not added' : phone,
          subtitle: 'Phone',
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.calendar,
          title: _formatDob(dob) ?? 'Not added',
          subtitle: 'Date of birth',
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  String _memberSince(String? createdAt) {
    final date = createdAt == null ? null : DateTime.tryParse(createdAt);
    if (date == null) return 'Member';
    return 'Member since ${monthYear(date)}';
  }

  String? _formatDob(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final date = DateTime.tryParse(raw);
    return date == null ? null : longDate(date);
  }
}
