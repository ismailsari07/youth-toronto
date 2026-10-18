import 'package:supabase_flutter/supabase_flutter.dart';

import 'registration_state.dart';

/// This device's push identity, passed to the registration RPCs so the
/// server can count the view and link the device to the member. Never
/// logged.
typedef DeviceCredentials = ({String installId, String secret});

/// The three registration RPCs (pape-admin CLAUDE.md §10). Errors are
/// thrown as they come (PostgrestException); see registration_errors.dart.
abstract class RegistrationApi {
  /// Anonymous or signed in. P0002 = no registration (any more).
  Future<RegistrationState> state(String eventId);

  /// "X kişi görüntüledi": null below the server's threshold.
  Future<int?> recordView(String eventId, DeviceCredentials device);

  /// `already: true` (a double tap, or registered elsewhere) is success too.
  Future<void> register({
    required String eventId,
    required String formVersion,
    required Map<String, Object> answers,
    String? fullName,
    String? phone,
    DeviceCredentials? device,
  });
}

class SupabaseRegistrationApi implements RegistrationApi {
  const SupabaseRegistrationApi();

  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<RegistrationState> state(String eventId) async {
    final json = await _db.rpc(
      'event_registration_state',
      params: {'p_event_id': eventId},
    );
    return RegistrationState.fromJson((json as Map).cast<String, dynamic>());
  }

  @override
  Future<int?> recordView(String eventId, DeviceCredentials device) async {
    final json = await _db.rpc('record_event_view', params: {
      'p_install_id': device.installId,
      'p_secret': device.secret,
      'p_event_id': eventId,
    });
    return ((json as Map)['views'] as num?)?.toInt();
  }

  @override
  Future<void> register({
    required String eventId,
    required String formVersion,
    required Map<String, Object> answers,
    String? fullName,
    String? phone,
    DeviceCredentials? device,
  }) =>
      _db.rpc('register_for_event', params: {
        'p_event_id': eventId,
        'p_form_version': formVersion,
        'p_answers': answers,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_install_id': device?.installId,
        'p_secret': device?.secret,
      });
}
