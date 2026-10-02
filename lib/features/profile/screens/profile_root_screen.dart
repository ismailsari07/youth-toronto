import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/reminder_sync.dart';
import '../../../l10n/l10n.dart';
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
import '../widgets/language_sheet.dart';

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
    final l = context.l10n;

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
          title: l.tabProfile,
          row: user == null ? _signedOutRow(l) : _identityRow(l, user, profile),
          footer: user != null
              ? null
              : Column(
                  children: [
                    PrimaryOnGradientButton(
                      label: l.signIn,
                      onTap: () => context.push('/profile/sign-in'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedOnGradientButton(
                      label: l.createAccount,
                      onTap: () => context.push('/profile/sign-up'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        SectionHeader(title: l.mosqueServices),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        GroupedRows(
          rows: [
            _marriageRow(
              l,
              user == null ? null : ref.watch(myApplicationProvider).valueOrNull,
            ),
          ],
        ),
        if (user != null) ...[
          const SizedBox(height: AppSpace.cardGapWide),
          SectionHeader(title: l.yourDetails),
          const SizedBox(height: AppSpace.sectionHeaderGap),
          _detailsCard(l, user, profile),
        ],
        const SizedBox(height: AppSpace.cardGapWide),
        SectionHeader(title: l.settings),
        const SizedBox(height: AppSpace.sectionHeaderGap),
        GroupedRows(
          rows: [
            AppListRow(
              icon: AppIcons.bell,
              title: l.prayerReminders,
              subtitle: l.prayerRemindersDetail,
              trailing: AppSwitch(
                value: _remindersOn ?? true,
                onChanged: _remindersOn == null ? null : _setReminders,
              ),
            ),
            const LanguageRow(divided: true),
            if (user != null)
              AppListRow(
                divided: true,
                icon: AppIcons.person,
                title: l.settings,
                subtitle: l.settingsRowSubtitle,
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
              title: l.mosqueAndContact,
              trailing: const RowChevron(),
              onTap: () => context.push('/profile/mosque'),
            ),
            AppListRow(
              divided: true,
              icon: AppIcons.info,
              title: l.aboutThisApp,
              subtitle: l.versionLabel('1.0'),
              trailing: const RowChevron(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l.worksWithoutAccount,
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
  Widget _marriageRow(AppLocalizations l, MarriageApplication? application) {
    return AppListRow(
      icon: AppIcons.documentLock,
      title: l.marriageService,
      subtitle: application == null
          ? l.marriageServiceRow
          : l.submittedOn(dayMonth(l, application.createdAt)),
      trailing: application == null
          ? const RowChevron()
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [UnderReviewPill(), SizedBox(width: 8), RowChevron()],
            ),
      onTap: () => MarriageRoutes.open(context, ref),
    );
  }

  Widget _signedOutRow(AppLocalizations l) => HeroRow(
        icon: AppIcons.person,
        title: l.notSignedIn,
        subtitle: l.notSignedInBody,
        circleSize: 46,
      );

  Widget _identityRow(
    AppLocalizations l,
    User user,
    Map<String, dynamic>? profile,
  ) {
    final name = (profile?['full_name'] as String?) ??
        user.email?.split('@').first ??
        l.member;
    final since = _memberSince(l, profile?['created_at'] as String?);
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
            _initials(l, name),
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

  Widget _detailsCard(
    AppLocalizations l,
    User user,
    Map<String, dynamic>? profile,
  ) {
    final phone = profile?['phone'] as String?;
    final dob = profile?['date_of_birth'] as String?;
    return GroupedRows(
      rows: [
        AppListRow(
          icon: AppIcons.person,
          title: (profile?['full_name'] as String?) ?? '—',
          subtitle: l.name,
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.mail,
          title: user.email ?? '—',
          subtitle: l.email,
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.phone,
          title: phone == null || phone.isEmpty ? l.notAdded : phone,
          subtitle: l.phone,
        ),
        AppListRow(
          divided: true,
          icon: AppIcons.calendar,
          title: _formatDob(l, dob) ?? l.notAdded,
          subtitle: l.dobField,
        ),
      ],
    );
  }

  /// Turkish-aware, so "ismail" gives "İ" in Turkish.
  String _initials(AppLocalizations l, String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return upper('${parts.first[0]}${parts.last[0]}', l.localeName);
    }
    return name.isEmpty ? '?' : upper(name[0], l.localeName);
  }

  String _memberSince(AppLocalizations l, String? createdAt) {
    final date = createdAt == null ? null : DateTime.tryParse(createdAt);
    if (date == null) return l.member;
    return l.memberSince(monthYear(l, date));
  }

  String? _formatDob(AppLocalizations l, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final date = DateTime.tryParse(raw);
    return date == null ? null : longDate(l, date);
  }
}
