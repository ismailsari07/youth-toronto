import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/content_provider.dart';
import 'data/marriage_application.dart';
import 'data/marriage_v2_service.dart';
import 'marriage_provider.dart';

/// Pushed screens of the marriage service (spec §8a). All sit on the root
/// navigator, so the tab bar is hidden.
abstract final class MarriageRoutes {
  static const gate = '/profile/marriage/gate';
  static const upload = '/profile/marriage/upload';
  static const received = '/profile/marriage/received';
  static const status = '/profile/marriage/status';
  static const view = '/profile/marriage/view';

  /// Form v2 (1.5.0+): the encrypted application and its status.
  static const form = '/profile/marriage/form';
  static const submitted = '/profile/marriage/submitted';

  /// Where the service opens for this state: signed out → gate; an old
  /// document application → its status; an encrypted application → its
  /// status; otherwise the new form when `marriage_form_v2` is on, else the
  /// document upload (which itself asks for a date of birth or explains the
  /// age limit when needed). An existing application always wins over the
  /// switch, so it stays visible and can be withdrawn.
  static String entryFor({
    required bool signedIn,
    required MarriageApplication? application,
    MarriageSubmission? submission,
    bool formV2 = false,
  }) {
    if (!signedIn) return gate;
    if (application != null) return status;
    if (submission != null) return submitted;
    return formV2 ? form : upload;
  }

  /// Where a member without an application starts (after a withdrawal too).
  static String startFor({required bool formV2}) => formV2 ? form : upload;

  /// [entryFor] for the current member. If an application can't be loaded
  /// the start screen is the default: the server refuses a second
  /// application anyway (one per member across both kinds).
  static Future<String> resolve(WidgetRef ref) async {
    final signedIn = ref.read(currentUserProvider) != null;
    final formV2 = ref.read(contentProvider).features.marriageFormV2;
    if (!signedIn) return gate;
    Future<T?> quietly<T>(Future<T?> f) => f.then<T?>((v) => v, onError: (_) => null);
    final results = await Future.wait<Object?>([
      quietly(ref.read(myApplicationProvider.future)),
      quietly(ref.read(mySubmissionProvider.future)),
    ]);
    return entryFor(
      signedIn: true,
      application: results[0] as MarriageApplication?,
      submission: results[1] as MarriageSubmission?,
      formV2: formV2,
    );
  }

  /// Opens the service from the Profile row.
  static Future<void> open(BuildContext context, WidgetRef ref) async {
    final route = await resolve(ref);
    if (!context.mounted) return;
    context.push(route);
  }
}
