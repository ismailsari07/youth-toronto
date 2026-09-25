import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/auth_provider.dart';
import 'data/marriage_application.dart';
import 'marriage_provider.dart';

/// Pushed screens of the marriage service (spec §8a). All sit on the root
/// navigator, so the tab bar is hidden.
abstract final class MarriageRoutes {
  static const gate = '/profile/marriage/gate';
  static const upload = '/profile/marriage/upload';
  static const received = '/profile/marriage/received';
  static const status = '/profile/marriage/status';
  static const view = '/profile/marriage/view';

  /// Where the service opens for this state: signed out → gate; applied →
  /// status; otherwise upload (which itself asks for a date of birth or
  /// explains the age limit when needed).
  static String entryFor({
    required bool signedIn,
    required MarriageApplication? application,
  }) {
    if (!signedIn) return gate;
    return application == null ? upload : status;
  }

  /// Opens the service from the Profile row. If the application hasn't
  /// loaded yet it waits for it; if it can't be loaded, Upload is the safe
  /// default — a new file then replaces any existing one rather than
  /// creating a second application.
  static Future<void> open(BuildContext context, WidgetRef ref) async {
    final signedIn = ref.read(currentUserProvider) != null;
    MarriageApplication? application;
    if (signedIn) {
      try {
        application = await ref.read(myApplicationProvider.future);
      } catch (_) {
        application = null;
      }
    }
    if (!context.mounted) return;
    context.push(entryFor(signedIn: signedIn, application: application));
  }
}
