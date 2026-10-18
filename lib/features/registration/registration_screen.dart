import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_schedule.dart';
import '../../core/registration/registration_errors.dart';
import '../../core/registration/registration_form.dart';
import '../../core/registration/registration_state.dart';
import '../../l10n/l10n.dart';
import '../../shared/providers/push_provider.dart';
import '../../shared/providers/registration_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_buttons.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_row.dart';
import '../../ui/components/app_scaffolding.dart';
import 'question_fields.dart';
import 'registration_text.dart';

/// The registration form (pape-admin CLAUDE.md §10.2–10.4): the member's
/// details, the event's questions, and "Kaydı gönder". Pops with true once
/// registered. The answers live in memory only (the session draft, D8).
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.upcoming});

  final UpcomingEvent upcoming;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

enum _Banner { none, fixBelow, formChanged, rejected, offline }

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  late Map<String, Object?> _answers;
  final _controllers = <String, TextEditingController>{};
  final _fieldKeys = <String, GlobalKey>{};
  late final TextEditingController _name;
  late final TextEditingController _phone;
  Map<String, String> _errors = const {};
  _Banner _banner = _Banner.none;
  bool _sending = false;
  bool _nameFilled = false;

  String get _eventId => widget.upcoming.event.id;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(registrationDraftsProvider.notifier).of(_eventId);
    _answers = {...draft.answers};
    _name = TextEditingController(text: draft.fullName);
    _phone = TextEditingController(text: draft.phone);
    _nameFilled = draft.fullName != null;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// The text-based question's controller, starting from the draft.
  TextEditingController _controller(String id) => _controllers.putIfAbsent(
        id,
        () => TextEditingController(
          text: switch (_answers[id]) {
            final String s => s,
            final num n => '$n',
            _ => '',
          },
        ),
      );

  GlobalKey _key(String field) => _fieldKeys.putIfAbsent(field, GlobalKey.new);

  void _saveDraft() => ref.read(registrationDraftsProvider.notifier).save(
        _eventId,
        RegistrationDraft(
          answers: {..._answers},
          fullName: _nameFilled ? _name.text : null,
          phone: _phone.text,
        ),
      );

  void _answer(String id, Object? value) {
    setState(() {
      _answers[id] = value;
      if (_errors.containsKey(id)) _errors = {..._errors}..remove(id);
    });
    _saveDraft();
  }

  void _showErrors(Map<String, String> errors, List<Question> questions) {
    setState(() {
      _errors = errors;
      _banner = errors.containsKey('_answers') ? _Banner.rejected : _Banner.fixBelow;
    });
    // The first field with an error, in screen order.
    final order = ['full_name', 'phone', for (final q in questions) q.id];
    final first = order.where(errors.containsKey).firstOrNull;
    final context = first == null ? null : _fieldKeys[first]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.1,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  Future<void> _submit(RegistrationState s) async {
    final me = s.me;
    if (me == null) {
      await context.push('/profile/sign-in');
      return;
    }
    final fullName = me.nameMissing ? _name.text : null;
    final phone = s.requirePhone && me.phoneMissing ? _phone.text : null;
    final local = localErrors(s.questions, _answers, fullName: fullName, phone: phone);
    if (local.isNotEmpty) return _showErrors(local, s.questions);

    setState(() {
      _sending = true;
      _banner = _Banner.none;
    });
    try {
      final device = await ref.read(deviceCredentialsProvider)();
      await ref.read(registrationApiProvider).register(
            eventId: _eventId,
            formVersion: s.formVersion,
            answers: answersPayload(s.questions, _answers),
            fullName: fullName?.trim(),
            phone: phone?.trim(),
            device: device,
          );
      // The server dropped this device's mute for the event.
      await ref.read(pushProvider.notifier).registeredFor(_eventId);
      ref.read(registrationDraftsProvider.notifier).clear(_eventId);
      ref.invalidate(registrationStateProvider(_eventId));
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      await _failed(RegisterFailure.of(e), s);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _failed(RegisterFailure failure, RegistrationState s) async {
    switch (failure) {
      case RegisterInvalid(:final fields):
        _showErrors(fields, s.questions);
      case RegisterFormChanged():
        ref.invalidate(registrationStateProvider(_eventId));
        try {
          final fresh = await ref.read(registrationStateProvider(_eventId).future);
          if (!mounted) return;
          setState(() {
            _answers = keepAnswers(_answers, fresh.questions);
            for (final MapEntry(:key, :value) in _controllers.entries) {
              if (!_answers.containsKey(key)) value.clear();
            }
            _errors = const {};
            _banner = _Banner.formChanged;
          });
          _saveDraft();
        } catch (_) {
          if (mounted) setState(() => _banner = _Banner.offline);
        }
      case RegisterNeedsSignIn():
        await context.push('/profile/sign-in');
      case RegisterOffline():
        setState(() => _banner = _Banner.offline);
      case RegisterNotAccepting() ||
            RegisterNoProfile() ||
            RegisterStateChanged() ||
            RegisterUnavailable():
        // The event page shows the new state.
        ref.invalidate(registrationStateProvider(_eventId));
        context.pop(false);
    }
  }

  String? _bannerText(AppLocalizations l) => switch (_banner) {
        _Banner.none => null,
        _Banner.fixBelow => l.regFixBelow,
        _Banner.formChanged => l.regFormChanged,
        _Banner.rejected => l.regAnswersRejected,
        _Banner.offline => l.regOffline,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(registrationStateProvider(_eventId));
    final s = async.valueOrNull;
    final banner = _bannerText(l);
    final blocked = s == null || needsUpdate(s.questions);

    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.regEyebrow, title: widget.upcoming.event.title),
          Expanded(
            child: s == null
                ? Center(
                    child: async.hasError
                        ? GhostButton(
                            label: l.tryAgain,
                            onTap: () => ref.invalidate(registrationStateProvider(_eventId)),
                          )
                        : const CircularProgressIndicator.adaptive(),
                  )
                // Not lazy: ten questions at most, and every field's key
                // must exist to scroll to the first error.
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.pageGutter,
                      18,
                      AppSpace.pageGutter,
                      40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (banner != null) ...[
                          _BannerCard(
                            text: banner,
                            warning: _banner == _Banner.formChanged || _banner == _Banner.offline,
                          ),
                          const SizedBox(height: AppSpace.cardGapWide),
                        ],
                        SectionHeader(title: l.regYourDetails),
                        const SizedBox(height: AppSpace.sectionHeaderGap),
                        if (s.me != null) _details(context, s, s.me!),
                        if (s.questions.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.cardGapWide),
                          SectionHeader(title: l.regQuestions),
                          const SizedBox(height: AppSpace.sectionHeaderGap),
                          for (final q in s.questions)
                            if (q.type != QuestionType.unknown || q.required) ...[
                              QuestionField(
                                key: _key(q.id),
                                question: q,
                                value: _answers[q.id],
                                controller: _controller(q.id),
                                error: switch (_errors[q.id]) {
                                  final code? => registrationErrorText(l, q.id, code),
                                  null => null,
                                },
                                onChanged: (v) => _answer(q.id, v),
                              ),
                              const SizedBox(height: AppSpace.cardGap),
                            ],
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: s == null
          ? null
          : StickyBottomBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (blocked)
                    _DisabledSubmit(label: l.regSubmit)
                  else
                    PrimaryButton(
                      key: const Key('registration-submit'),
                      label: l.regSubmit,
                      onTap: _sending ? null : () => _submit(s),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l.regNoCancel,
                    textAlign: TextAlign.center,
                    style: AppText.caption.c(context.colors.ink3),
                  ),
                ],
              ),
            ),
    );
  }

  /// "Bilgilerin": never form questions. Name and phone are inputs only
  /// when missing; register_for_event saves them with the registration.
  Widget _details(BuildContext context, RegistrationState s, RegistrationMe me) {
    final l = context.l10n;
    final c = context.colors;
    if (me.nameMissing && !_nameFilled) {
      // Prefilled with the current (automatic) name, once.
      _nameFilled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _name.text.isEmpty) _name.text = me.fullName;
      });
    }
    final nameError = _errors['full_name'];
    final phoneError = _errors['phone'];

    Widget readOnly(String icon, String label, String value, {bool divided = false}) =>
        AppListRow(
          divided: divided,
          icon: icon,
          tone: RowTone.neutral,
          title: value,
          subtitle: label,
          trailing: AppIcon(AppIcons.lock, size: 15, color: c.ink4),
        );

    Widget input({
      required String field,
      required String label,
      required TextEditingController controller,
      required String? error,
      String? hint,
      String? note,
      TextInputType? keyboard,
      bool divided = false,
    }) =>
        Container(
          key: _key(field),
          decoration: BoxDecoration(
            border: divided ? Border(top: BorderSide(color: c.hairline)) : null,
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            key: ValueKey('field-$field'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(label, required: true),
              if (note != null) ...[
                const SizedBox(height: 3),
                Text(note, style: AppText.caption.c(c.ink3)),
              ],
              const SizedBox(height: 10),
              BoxInput(
                controller: controller,
                hint: hint,
                keyboardType: keyboard,
                maxLength: field == 'full_name' ? 120 : 40,
                error: error != null,
                onChanged: (_) {
                  if (_errors.containsKey(field)) {
                    setState(() => _errors = {..._errors}..remove(field));
                  }
                  _saveDraft();
                },
              ),
              if (error != null) FieldError(registrationErrorText(l, field, error)),
            ],
          ),
        );

    return AppCard(
      grouped: true,
      radius: AppRadius.listCard,
      border: nameError != null || phoneError != null
          ? Border.all(color: c.dangerBorder)
          : null,
      child: Column(
        children: [
          if (me.nameMissing)
            input(
              field: 'full_name',
              label: l.regFullName,
              controller: _name,
              error: nameError,
              keyboard: TextInputType.name,
            )
          else
            readOnly(AppIcons.person, l.regFullName, me.fullName),
          if (me.email.isNotEmpty)
            readOnly(AppIcons.mail, l.regEmail, me.email, divided: true),
          if (s.requirePhone)
            if (me.phoneMissing)
              input(
                field: 'phone',
                label: l.regPhone,
                controller: _phone,
                error: phoneError,
                hint: '(416) 555-0123',
                note: l.regSavedToProfile,
                keyboard: TextInputType.phone,
                divided: true,
              )
            else
              readOnly(AppIcons.phone, l.regPhone, me.phone ?? '', divided: true),
        ],
      ),
    );
  }
}

class _DisabledSubmit extends StatelessWidget {
  const _DisabledSubmit({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: false,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.neutralTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label, style: AppText.buttonLarge.c(context.colors.inkDisabled)),
        ),
      );
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.text, required this.warning});

  final String text;

  /// Amber (form changed, offline) rather than red (errors).
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = warning ? c.amber : c.danger;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        radius: AppRadius.listCard,
        color: warning ? c.amberTint : c.dangerTint,
        border: warning ? null : Border.all(color: c.dangerBorder),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.alert, size: 18, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ).c(ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
