import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/auth_provider.dart';
import 'data/marriage_application.dart';
import 'data/marriage_service.dart';
import 'data/marriage_v2_service.dart';

/// The signed-in member's own application, or null when signed out or not
/// applied. Errors surface as AsyncError; the Profile row then shows its
/// default subtitle rather than guessing a state.
final myApplicationProvider =
    FutureProvider<MarriageApplication?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return MarriageService.fetchOwn();
});

/// The member's encrypted application (form v2), or null. Read whatever the
/// flag says, so an application sent while the form was on still shows
/// (and can be withdrawn) after the form is switched off.
final mySubmissionProvider = FutureProvider<MarriageSubmission?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return MarriageV2Service.fetchOwn();
});

/// The published form and whether a key is ready, fetched together when the
/// form opens. `key == false` = the service isn't open yet.
final marriageFormProvider =
    FutureProvider.autoDispose<({PublishedMarriageForm? form, bool keyReady})>((ref) async {
  final results = await Future.wait([
    MarriageV2Service.fetchForm(),
    MarriageV2Service.fetchServiceKey(),
  ]);
  return (form: results[0] as PublishedMarriageForm?, keyReady: results[1] != null);
});

enum MarriageEligibility { needsDateOfBirth, underAge, eligible }

/// Whether a member with date of birth [dob] (`YYYY-MM-DD`, from
/// `user_profiles`) may apply. This only chooses which screen to show; the
/// server's `is_adult()` check is what actually allows or refuses the upload.
MarriageEligibility eligibilityFor(String? dob, {DateTime? today}) {
  final born = dob == null || dob.isEmpty ? null : DateTime.tryParse(dob);
  if (born == null) return MarriageEligibility.needsDateOfBirth;
  final now = today ?? DateTime.now();
  var eighteenth = DateTime(born.year + 18, born.month, born.day);
  // 29 February → 28 February in a non-leap year, as Postgres does for
  // `date + interval '18 years'` (Dart would roll over to 1 March).
  if (eighteenth.month != born.month) {
    eighteenth = DateTime(born.year + 18, born.month + 1, 0);
  }
  final todayDate = DateTime(now.year, now.month, now.day);
  return todayDate.isBefore(eighteenth)
      ? MarriageEligibility.underAge
      : MarriageEligibility.eligible;
}
