import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/forms_v2/marriage_form.dart';
import '../../../core/mosque_time.dart';
import '../../../core/registration/registration_form.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/formatters.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/content_provider.dart';
import '../../../theme/app_icon.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_buttons.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_scaffolding.dart';
import '../../../ui/components/app_sheet.dart';
import '../../../ui/components/motion.dart';
import '../../registration/question_fields.dart';
import '../../registration/registration_text.dart';
import '../data/document_picker.dart';
import '../data/marriage_v2_service.dart';
import '../data/photo_prep.dart';
import '../marriage_provider.dart';
import '../marriage_routes.dart';
import '../widgets/marriage_widgets.dart';
import 'marriage_dob_view.dart';
import 'marriage_upload_screen.dart' show MarriageNotEligibleView, MarriageProfileUnavailableView;

/// The encrypted marriage application (form v2, app 1.5.0+). The form comes
/// from the panel (`marriage_forms`, published version); answers and photos
/// stay in memory only until they are encrypted and sent. The same answer
/// checks run here and in the key holder's browser (`validateAnswers`).
class MarriageFormScreen extends ConsumerWidget {
  const MarriageFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return switch (profile) {
      AsyncData(value: final row?) => switch (eligibilityFor(row['date_of_birth'] as String?)) {
          MarriageEligibility.needsDateOfBirth => const MarriageDobView(),
          MarriageEligibility.underAge => const MarriageNotEligibleView(),
          MarriageEligibility.eligible => _FormLoader(profile: row),
        },
      AsyncData() || AsyncError() => MarriageProfileUnavailableView(
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      _ => const _Frame(body: []),
    };
  }
}

class _FormLoader extends ConsumerWidget {
  const _FormLoader({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final open = ref.watch(contentProvider.select((c) => c.features.marriageFormV2));
    if (!open) return _Message(title: l.mfClosedTitle, body: l.mfClosedBody);
    return switch (ref.watch(marriageFormProvider)) {
      AsyncData(value: (form: final form?, keyReady: true)) =>
        MarriageFormBody(
          key: ValueKey(form.version),
          form: form,
          profile: profile,
          accountEmail: Supabase.instance.client.auth.currentUser?.email ?? '',
        ),
      AsyncData() => _Message(title: l.mfClosedTitle, body: l.mfClosedBody),
      AsyncError(error: FormUnsupportedException()) => _Message(title: l.mfTitle, body: l.mfUpdateBody),
      AsyncError() => _Message(
          title: l.mfTitle,
          body: l.mfLoadFailed,
          onRetry: () => ref.invalidate(marriageFormProvider),
        ),
      _ => const _Frame(body: []),
    };
  }
}

/// Nav bar, scrolling body and optional sticky bar.
class _Frame extends StatelessWidget {
  const _Frame({required this.body, this.bottom, this.controller});

  final List<Widget> body;
  final Widget? bottom;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(eyebrow: l.marriageEyebrow, title: l.mfTitle, subtitle: l.mfSubtitle),
          Expanded(
            child: ListView(
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(AppSpace.pageGutter, 18, AppSpace.pageGutter, 24),
              children: body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottom == null ? null : StickyBottomBar(child: bottom!),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.onRetry});

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Frame(
      body: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppText.cardTitle.c(context.colors.ink)),
              const SizedBox(height: 10),
              Text(body, style: AppText.body.c(context.colors.ink2)),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                GhostButton(label: l.tryAgain, onTap: onRetry),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.cardGapWide),
        const PrivacyStrip(),
      ],
    );
  }
}

// ── The form ────────────────────────────────────────────────────────────────

/// Field types the app renders with the registration widgets.
const _sharedTypes = {
  'short_text', 'long_text', 'number', 'single_choice', 'multiple_choice', 'yes_no', 'date', 'phone',
};

/// Sends a checked application ([MarriageV2Service.submit] in the app).
typedef SubmitApplication = Future<void> Function({
  required PublishedMarriageForm form,
  required Map<String, Object> answers,
  required List<NumberedPhoto> photos,
  required String locale,
  String? appVersion,
  void Function(int done, int total)? onProgress,
});

/// The form itself, for a published [form]. [pickPhoto] and [submit] are
/// the real picker and sender in the app, fakes in tests.
class MarriageFormBody extends ConsumerStatefulWidget {
  const MarriageFormBody({
    super.key,
    required this.form,
    required this.profile,
    required this.accountEmail,
    this.pickPhoto = DocumentPicker.pickPhoto,
    this.submit = MarriageV2Service.submit,
  });

  final PublishedMarriageForm form;
  final Map<String, dynamic> profile;
  final String accountEmail;
  final Future<Uint8List?> Function() pickPhoto;
  final SubmitApplication submit;

  @override
  ConsumerState<MarriageFormBody> createState() => _FormBodyState();
}

class _FormBodyState extends ConsumerState<MarriageFormBody> {
  late PublishedMarriageForm _form = widget.form;
  final _answers = <String, Object?>{};
  final _controllers = <String, TextEditingController>{};
  final _keys = <String, GlobalKey>{};
  final _photos = <PreparedPhoto>[];
  final _scroll = ScrollController();

  /// The profile's date of birth, shown read-only for a `birth_date` field.
  String? _dob;
  Map<String, String> _errors = const {};
  bool _tried = false;
  bool _dirty = false;
  bool _sending = false;
  bool _leaving = false;
  double? _progress;
  bool _preparingPhoto = false;
  PhotoProblem? _photoProblem;

  AppLocalizations get l => context.l10n;
  List<Map> get _fields => allFields(_form.schema);
  Map? get _photosField => _fields.where((f) => f['type'] == 'photos').firstOrNull;

  @override
  void initState() {
    super.initState();
    _dob = widget.profile['date_of_birth'] as String?;
    _prefill();
  }

  /// Birth date, phone and email from the profile and the account, where the
  /// form asks for them. Everything else starts empty.
  void _prefill() {
    final phone = widget.profile['phone'];
    final email = widget.accountEmail;
    for (final f in _fields) {
      final id = f['id'] as String;
      if (f['type'] == 'date' && f['role'] == 'birth_date' && _dob != null) _answers[id] = _dob;
      if (f['type'] == 'phone' && f['prefill'] == 'profile' && phone is String && phone.isNotEmpty) {
        _answers[id] = phone;
        _controller(id).text = phone;
      }
      if (f['type'] == 'email' && f['prefill'] == 'account' && email.isNotEmpty && !email.endsWith('@privaterelay.appleid.com')) {
        _answers[id] = email;
        _controller(id).text = email;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  TextEditingController _controller(String id) => _controllers.putIfAbsent(id, TextEditingController.new);
  GlobalKey _key(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  String get _today => isoDate(mosqueNow());

  Map<String, Object?> _currentAnswers() => {
        ..._answers,
        if (_photosField case final p?) p['id'] as String: _photos.isEmpty ? null : [for (var i = 0; i < _photos.length; i++) i + 1],
      };

  void _set(String id, Object? value) {
    setState(() {
      _answers[id] = value;
      _dirty = true;
      if (_tried) _errors = validateAnswers(_form.schema, _currentAnswers(), _today).errors;
    });
  }

  void _photosChanged() {
    _dirty = true;
    if (_tried) _errors = validateAnswers(_form.schema, _currentAnswers(), _today).errors;
  }

  // ── Photos ──

  Future<void> _addPhoto() async {
    setState(() => _photoProblem = null);
    final raw = await widget.pickPhoto();
    if (raw == null || !mounted) return;
    setState(() => _preparingPhoto = true);
    final (photo, problem) = await preparePhoto(raw);
    raw.fillRange(0, raw.length, 0);
    if (!mounted) return;
    setState(() {
      _preparingPhoto = false;
      _photoProblem = problem;
      if (photo != null) {
        _photos.add(photo);
        _photosChanged();
      }
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _photoProblem = null;
      _photosChanged();
    });
  }

  // ── Sending ──

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final check = validateAnswers(_form.schema, _currentAnswers(), _today);
    setState(() {
      _tried = true;
      _errors = check.errors;
    });
    if (check.errors.isNotEmpty) {
      _scrollToFirstError();
      return;
    }
    setState(() {
      _sending = true;
      _progress = 0;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.submit(
        form: _form,
        answers: check.clean,
        photos: [for (var i = 0; i < _photos.length; i++) (n: i + 1, photo: _photos[i])],
        locale: formLanguage(context),
        appVersion: ref.read(appVersionProvider),
        onProgress: (done, total) {
          if (mounted) setState(() => _progress = done / total);
        },
      );
      if (!mounted) return;
      _leaving = true;
      ref.invalidate(mySubmissionProvider);
      context.pushReplacement(MarriageRoutes.submitted, extra: true);
    } on SubmitException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _progress = null;
      });
      switch (e.failure) {
        case SubmitFailure.closed:
          messenger.showSnackBar(SnackBar(content: Text(l.mfClosedBody)));
          ref.invalidate(marriageFormProvider);
        case SubmitFailure.notAdult:
          messenger.showSnackBar(SnackBar(content: Text(l.mfErrTooYoung)));
        case SubmitFailure.alreadyApplied:
          messenger.showSnackBar(SnackBar(content: Text(l.mfErrAlready)));
          _leaving = true;
          ref.invalidate(myApplicationProvider);
          ref.invalidate(mySubmissionProvider);
          final route = await MarriageRoutes.resolve(ref);
          if (mounted) context.pushReplacement(route);
        case SubmitFailure.formChanged:
          await _reloadForm();
          messenger.showSnackBar(SnackBar(content: Text(l.mfErrFormChanged)));
        case SubmitFailure.sendFailed:
          messenger.showSnackBar(SnackBar(content: Text(l.mfErrSend)));
      }
    }
  }

  /// A newer form was published while filling in: take it, keep the answers
  /// whose questions still exist (the checks then say what's missing).
  Future<void> _reloadForm() async {
    PublishedMarriageForm? next;
    try {
      next = await MarriageV2Service.fetchForm();
    } catch (_) {
      next = null;
    }
    if (!mounted) return;
    if (next == null) {
      ref.invalidate(marriageFormProvider);
      return;
    }
    final form = next;
    setState(() {
      _form = form;
      final ids = {for (final f in _fields) f['id']};
      _answers.removeWhere((k, _) => !ids.contains(k));
      if (_photosField == null) _photos.clear();
      _errors = validateAnswers(_form.schema, _currentAnswers(), _today).errors;
    });
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final f in _fields) {
        final ctx = _keys[f['id']]?.currentContext;
        if (_errors.containsKey(f['id']) && ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
          return;
        }
      }
    });
  }

  // ── Leaving ──

  Future<void> _confirmLeave() async {
    if (_sending) return;
    final leave = await showAppSheet<bool>(context: context, builder: (_) => const _LeaveSheet());
    if (leave == true && mounted) {
      _leaving = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final answers = _currentAnswers();
    final lang = formLanguage(context);
    final sections = (_form.schema['sections'] as List).cast<Map>();
    return PopScope(
      canPop: _leaving || (!_dirty && !_sending),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: _Frame(
        controller: _scroll,
        body: [
          PrivacyStrip(text: l.mfPrivacy),
          if (_tried && _errors.isNotEmpty) ...[
            const SizedBox(height: AppSpace.cardGap),
            Text(l.mfFixErrors, style: AppText.body.c(context.colors.danger)),
          ],
          for (final section in sections)
            if ((section['fields'] as List).any((f) => isVisible(_form.schema, answers, (f as Map)['id'] as String))) ...[
              const SizedBox(height: AppSpace.cardGapWide + 6),
              Text(pickText(section['title'], lang), style: AppText.sectionHeader.c(context.colors.ink)),
              if (pickText(section['help'], lang) case final help when help.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(help, style: AppText.caption.c(context.colors.ink2)),
              ],
              for (final f in (section['fields'] as List).cast<Map>())
                if (isVisible(_form.schema, answers, f['id'] as String)) ...[
                  const SizedBox(height: AppSpace.cardGap),
                  KeyedSubtree(key: _key(f['id'] as String), child: _field(f, lang)),
                ],
            ],
          const SizedBox(height: AppSpace.cardGapWide),
        ],
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_progress case final p?) ...[
              UploadProgressBar(value: p),
              const SizedBox(height: 10),
            ],
            Opacity(
              opacity: _sending || _preparingPhoto ? 0.55 : 1,
              child: PrimaryButton(
                label: _sending ? l.mfSending : l.mfSend,
                icon: _sending ? null : AppIcons.lock,
                onTap: _sending || _preparingPhoto ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _error(Map f) {
    final code = _errors[f['id']];
    if (code == null) return null;
    return switch ((f['type'], code)) {
      (_, 'too_young') => l.mfErrTooYoung,
      (_, 'invalid_email') => l.mfErrEmail,
      ('photos', _) => l.mfErrPhotos,
      ('consent', _) => l.mfErrConsent,
      _ => registrationErrorText(l, f['id'] as String, code),
    };
  }

  Widget _field(Map f, String lang) {
    final id = f['id'] as String;
    final type = f['type'] as String;
    final error = _error(f);
    if (type == 'date' && f['role'] == 'birth_date' && _dob != null) {
      return _BirthDateCard(field: f, dob: _dob!, today: _today, lang: lang, error: error);
    }
    if (_sharedTypes.contains(type)) {
      final q = _question(f);
      return QuestionField(
        question: q,
        value: _answers[id],
        controller: _controller(id),
        error: error,
        onChanged: (v) => _set(id, v),
      );
    }
    return switch (type) {
      'email' => _EmailField(
          field: f,
          lang: lang,
          controller: _controller(id),
          error: error,
          onChanged: (v) => _set(id, v),
        ),
      'photos' => _PhotosField(
          field: f,
          lang: lang,
          photos: _photos,
          preparing: _preparingPhoto,
          problem: _photoProblem,
          error: error,
          onAdd: _sending ? null : _addPhoto,
          onRemove: _sending ? null : _removePhoto,
        ),
      'consent' => _ConsentField(
          field: f,
          lang: lang,
          value: _answers[id] == true,
          error: error,
          onChanged: (v) => _set(id, v ? true : null),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  static Question _question(Map f) {
    final type = f['type'] as String;
    Map<String, dynamic> map(Object? v) => v is Map ? v.cast<String, dynamic>() : const {};
    final unit = (f['unit'] as String?)?.trim();
    return Question(
      id: f['id'] as String,
      type: QuestionType.parse(type),
      required: f['required'] == true,
      label: map(f['label']),
      options: [
        for (final o in (f['options'] as List? ?? const []).cast<Map>())
          ChoiceOption(o['id'] as String, map(o['label'])),
      ],
      min: f['min'] as num?,
      max: f['max'] as num?,
      integer: f['integer'] == true,
      maxLength: (f['max_length'] as num?)?.toInt() ??
          (type == 'short_text' ? FormLimits.shortDefault : type == 'long_text' ? FormLimits.longDefault : null),
      unit: unit == null || unit.isEmpty ? null : unit,
      help: f['help'] is Map ? map(f['help']) : null,
    );
  }
}

// ── Field cards that registration forms don't have ─────────────────────────

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.field, required this.lang, required this.child, this.error, this.hint});

  final Map field;
  final String lang;
  final Widget child;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final help = pickText(field['help'], lang);
    return AppCard(
      radius: AppRadius.listCard,
      border: error != null ? Border.all(color: context.colors.dangerBorder) : null,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (field['type'] != 'consent')
            FieldLabel(pickText(field['label'], lang), required: field['required'] == true),
          if (help.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(help, style: AppText.caption.c(context.colors.ink2)),
          ],
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!, style: AppText.caption.c(context.colors.ink3)),
          ],
          const SizedBox(height: 12),
          child,
          if (error case final e?) FieldError(e),
        ],
      ),
    );
  }
}

class _BirthDateCard extends StatelessWidget {
  const _BirthDateCard({required this.field, required this.dob, required this.today, required this.lang, this.error});

  final Map field;
  final String dob;
  final String today;
  final String lang;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final day = DateTime.parse(dob);
    return _FieldCard(
      field: field,
      lang: lang,
      error: error,
      child: Row(
        children: [
          AppIcon(AppIcons.calendar, size: 18, color: context.colors.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${dayMonthYear(l, day)} · ${l.mfAge(ageOn(dob, today))}',
              style: AppText.rowTitle.c(context.colors.ink),
            ),
          ),
          Text(l.mfFromProfile, style: AppText.caption.c(context.colors.ink3)),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.field, required this.lang, required this.controller, required this.onChanged, this.error});

  final Map field;
  final String lang;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return _FieldCard(
      field: field,
      lang: lang,
      error: error,
      child: BoxInput(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        maxLength: 254,
        hint: 'ad@example.com',
        error: error != null,
        formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        onChanged: onChanged,
      ),
    );
  }
}

class _ConsentField extends StatelessWidget {
  const _ConsentField({required this.field, required this.lang, required this.value, required this.onChanged, this.error});

  final Map field;
  final String lang;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final label = pickText(field['label'], lang);
    return _FieldCard(
      field: field,
      lang: lang,
      error: error,
      child: Semantics(
        checked: value,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: () => onChanged(!value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoiceMark(on: value, round: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 15, height: 1.4).c(context.colors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotosField extends StatelessWidget {
  const _PhotosField({
    required this.field,
    required this.lang,
    required this.photos,
    required this.preparing,
    required this.problem,
    required this.onAdd,
    required this.onRemove,
    this.error,
  });

  final Map field;
  final String lang;
  final List<PreparedPhoto> photos;
  final bool preparing;
  final PhotoProblem? problem;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;
  final String? error;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final max = (field['max'] as num).toInt();
    return _FieldCard(
      field: field,
      lang: lang,
      hint: l.mfPhotosHint(max),
      error: error ??
          switch (problem) {
            PhotoProblem.unreadable => l.mfPhotoUnreadable,
            PhotoProblem.tooLarge => l.mfPhotoTooLarge,
            null => null,
          },
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < photos.length; i++)
            _Thumb(bytes: photos[i].bytes, size: _size, onRemove: onRemove == null ? null : () => onRemove!(i)),
          if (preparing)
            SizedBox(
              width: _size,
              height: _size,
              child: Semantics(
                label: l.mfPreparingPhoto,
                child: const Center(child: CircularProgressIndicator.adaptive()),
              ),
            )
          else if (photos.length < max)
            Semantics(
              button: true,
              label: l.mfAddPhoto,
              excludeSemantics: true,
              child: Pressable(
                onTap: onAdd,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: c.ground,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    border: Border.all(color: error != null ? c.dangerBorder : c.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(AppIcons.photo, size: 22, color: c.green),
                      const SizedBox(height: 6),
                      Text(l.mfAddPhoto, textAlign: TextAlign.center, style: AppText.caption.c(c.ink2)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, required this.size, required this.onRemove});

  final Uint8List bytes;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 300, gaplessPlayback: true),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: l.mfRemovePhoto,
                excludeSemantics: true,
                child: Pressable(
                  onTap: onRemove,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.barrier, shape: BoxShape.circle),
                    child: const AppIcon(AppIcons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaveSheet extends StatelessWidget {
  const _LeaveSheet();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.grabber,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l.mfLeaveTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700).c(context.colors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              l.mfLeaveBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.45).c(context.colors.ink2),
            ),
            const SizedBox(height: 22),
            DestructiveButton(label: l.mfLeave, onTap: () => Navigator.of(context).pop(true)),
            const SizedBox(height: 8),
            GhostButton(label: l.mfStay, onTap: () => Navigator.of(context).pop(false)),
          ],
        ),
      ),
    );
  }
}
