import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../features/community/screens/community_screen.dart';
import '../features/prayer/screens/prayer_home_screen.dart';
import '../features/profile/screens/profile_root_screen.dart';

final _prayerKey = GlobalKey<NavigatorState>(debugLabel: 'prayer');
final _communityKey = GlobalKey<NavigatorState>(debugLabel: 'community');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Spec §1: three tabs, each with its own stack. Pushed screens (event and
/// announcement details, sign in/up, settings, mosque info) are added to
/// their branch in later phases.
final router = GoRouter(
  initialLocation: '/prayer',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
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
            ),
          ],
        ),
      ],
    ),
  ],
);
