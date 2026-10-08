import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../app/tab_branch_container.dart';
import '../features/community/screens/announcement_detail_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/community/screens/event_detail_screen.dart';
import '../features/marriage/data/marriage_application.dart';
import '../features/marriage/screens/marriage_gate_screen.dart';
import '../features/marriage/screens/marriage_received_screen.dart';
import '../features/marriage/screens/marriage_status_screen.dart';
import '../features/marriage/screens/marriage_upload_screen.dart';
import '../features/marriage/screens/marriage_viewer_screen.dart';
import '../features/prayer/screens/prayer_home_screen.dart';
import '../features/profile/screens/burial_services_screen.dart';
import '../features/profile/screens/delete_account_screen.dart';
import '../features/profile/screens/mosque_info_screen.dart';
import '../features/profile/screens/profile_root_screen.dart';
import '../features/profile/screens/service_detail_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/profile/screens/sign_in_screen.dart';
import '../features/profile/screens/sign_up_screen.dart';
import 'content/content_bundle.dart';
import 'event_schedule.dart';
import 'models.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _prayerKey = GlobalKey<NavigatorState>(debugLabel: 'prayer');
final _communityKey = GlobalKey<NavigatorState>(debugLabel: 'community');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Spec §1: three tabs, each with its own stack. Pushed screens (event and
/// announcement details, sign in/up, settings, mosque info) are added to
/// their branch in later phases.
final router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/prayer',
  routes: [
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      // The indexed stack go_router builds by default, plus the staggered
      // entrance of the tab being shown.
      navigatorContainerBuilder: (context, navigationShell, children) =>
          TabBranchContainer(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
      branches: [
        StatefulShellBranch(
          navigatorKey: _prayerKey,
          routes: [
            GoRoute(
              path: '/prayer',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PrayerHomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _communityKey,
          routes: [
            GoRoute(
              path: '/community',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CommunityScreen()),
              routes: [
                // Pushed on the root navigator: pushed screens hide the
                // island and own their own bottom bar (spec §1, §7.6).
                GoRoute(
                  path: 'event',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) =>
                      EventDetailScreen(upcoming: state.extra! as UpcomingEvent),
                ),
                GoRoute(
                  path: 'announcement',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => AnnouncementDetailScreen(
                    item: state.extra! as Announcement,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileKey,
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileRootScreen()),
              routes: [
                GoRoute(
                  path: 'sign-in',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const SignInScreen(),
                ),
                GoRoute(
                  path: 'sign-up',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const SignUpScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'delete',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const DeleteAccountScreen(),
                ),
                GoRoute(
                  path: 'mosque',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const MosqueInfoScreen(),
                ),
                GoRoute(
                  path: 'burial',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const BurialServicesScreen(),
                ),
                GoRoute(
                  path: 'service',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) =>
                      ServiceDetailScreen(service: state.extra! as Service),
                ),
                // Marriage service (spec §8a). Paths match MarriageRoutes.
                GoRoute(
                  path: 'marriage/gate',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const MarriageGateScreen(),
                ),
                GoRoute(
                  path: 'marriage/upload',
                  parentNavigatorKey: _rootKey,
                  // extra: true when replacing an existing document.
                  builder: (context, state) =>
                      MarriageUploadScreen(replacing: state.extra == true),
                ),
                GoRoute(
                  path: 'marriage/received',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const MarriageReceivedScreen(),
                ),
                GoRoute(
                  path: 'marriage/status',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const MarriageStatusScreen(),
                ),
                GoRoute(
                  path: 'marriage/view',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => MarriageViewerScreen(
                    application: state.extra! as MarriageApplication,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
