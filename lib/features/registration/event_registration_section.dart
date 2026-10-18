import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/event_schedule.dart';
import '../../core/registration/registration_form.dart';
import '../../core/registration/registration_state.dart';
import '../../l10n/l10n.dart';
import '../../shared/formatters.dart';
import '../../shared/providers/registration_provider.dart';
import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../ui/components/app_buttons.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_controls.dart';
import '../../ui/components/app_row.dart';
import '../../ui/components/app_scaffolding.dart';
import 'registration_text.dart';

/// The registration part of an event page with a form (pape-admin
/// CLAUDE.md §10.1 and §10.5): a status card or the member's registration,
/// the view count, and the bottom bar.

/// What the page knows about the event's registration.
sealed class RegistrationView {
  const RegistrationView();

  static RegistrationView of(AsyncValue<RegistrationState> value) => switch (value) {
        AsyncData(:final value) => RegistrationLoaded(value),
        AsyncError(:final error)
            when error is PostgrestException && error.code == 'P0002' =>
          const RegistrationGone(),
        AsyncError() => const RegistrationFailed(),
        _ => const RegistrationLoading(),
      };
}

class RegistrationLoading extends RegistrationView {
  const RegistrationLoading();
}

class RegistrationLoaded extends RegistrationView {
  const RegistrationLoaded(this.state);

  final RegistrationState state;
}

/// P0002: unpublished, deleted, or no form any more.
class RegistrationGone extends RegistrationView {
  const RegistrationGone();
}

class RegistrationFailed extends RegistrationView {
  const RegistrationFailed();
}

/// Under the event's info rows.
class EventRegistrationSection extends ConsumerWidget {
  const EventRegistrationSection({super.key, required this.upcoming});

  final UpcomingEvent upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = upcoming.event.id;
    final view = RegistrationView.of(ref.watch(registrationStateProvider(id)));
    final views = ref.watch(eventViewsProvider(id)).valueOrNull;
    final l = context.l10n;

    final Widget? body = switch (view) {
      RegistrationLoaded(:final state) when state.registered =>
        RegisteredSummary(state: state),
      // The kill switch hides the rest (D4: not a member's own registration).
      RegistrationLoaded(:final state) when !state.available => null,
      RegistrationLoaded(:final state) => _StatusCard(
          state: state,
          recurring: upcoming.event.repeats.isRecurring,
        ),
      RegistrationGone() => _Note(icon: AppIcons.info, text: l.regNotAccepting),
      RegistrationFailed() => _Note(icon: AppIcons.alert, text: l.regStateFailed),
      RegistrationLoading() => const _StatusShimmer(),
    };
    if (body == null && views == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (body != null) ...[const SizedBox(height: AppSpace.cardGap), body],
        if (views != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Row(
              children: [
                AppIcon(AppIcons.eye, size: 15, color: context.colors.ink3),
                const SizedBox(width: 6),
                Text(l.regViews(views), style: AppText.caption.c(context.colors.ink3)),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.recurring});

  final RegistrationState state;
  final bool recurring;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final deadline = state.deadline;
    final open = state.status == RegStatus.open;
    final (String title, List<String> lines) = switch (state.status) {
      RegStatus.full => (l.regFull, const <String>[]),
      RegStatus.deadlinePassed => (
          l.regDeadlinePassed,
          [if (deadline != null) l.regDeadlineWas(registrationWhen(l, deadline))],
        ),
      RegStatus.closed || RegStatus.registered => (l.regClosed, const <String>[]),
      RegStatus.open => (
          l.regOpen,
          [
            if (deadline != null) l.regDeadlineIs(registrationWhen(l, deadline)),
            if (recurring) l.regRecurringNote,
          ],
        ),
    };
    final places = state.placesLeft;
    return GroupedRows(
      rows: [
        AppListRow(
          icon: open ? AppIcons.document : AppIcons.lock,
          tone: open ? RowTone.green : RowTone.neutral,
          title: title,
          subtitle: lines.isEmpty ? null : lines.join('\n'),
          trailing: places == null || !open
              ? null
              : AppBadge(
                  label: l.regPlacesLeft(places),
                  fill: context.colors.amberTint,
                  textColor: context.colors.amber,
                  height: 26,
                  fontSize: 12,
                  letterSpacing: 0,
                  horizontalPadding: 10,
                ),
        ),
      ],
    );
  }
}

/// "Kayıtlısın", the date, and what the member sent.
class RegisteredSummary extends StatelessWidget {
  const RegisteredSummary({super.key, required this.state});

  final RegistrationState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final lang = formLanguage(context);
    final me = state.me;
    final reg = me?.registration;

    String answer(Question q) {
      final v = reg?.answers[q.id];
      if (v == null) return '—';
      String option(Object? id) =>
          pickLabel(q.options.where((o) => o.id == id).firstOrNull?.label, lang);
      return switch (q.type) {
        QuestionType.singleChoice => option(v),
        QuestionType.multipleChoice when v is List => v.map(option).join(', '),
        QuestionType.yesNo => v == true ? l.regYes : l.regNo,
        QuestionType.date when v is String && DateTime.tryParse(v) != null =>
          dayMonthYear(l, DateTime.parse(v)),
        _ => '$v',
      };
    }

    final rows = <(String, String)>[
      if (reg != null) (l.regFullName, reg.fullName),
      if (me != null && me.email.isNotEmpty) (l.regEmail, me.email),
      if (reg?.phone case final phone?) (l.regPhone, phone),
      for (final q in state.questions)
        if (q.type != QuestionType.unknown) (pickLabel(q.label, lang), answer(q)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          radius: AppRadius.listCard,
          color: c.greenRowBg,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Row(
            children: [
              IconBubble(
                icon: AppIcons.check,
                size: 42,
                iconSize: 22,
                fill: c.iconCircleActive,
                glyphColor: c.selectedDark,
              ),
              const SizedBox(width: AppSpace.rowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.regRegistered,
                      style: AppText.rowTitle
                          .copyWith(fontWeight: FontWeight.w700)
                          .c(c.selectedDeep),
                    ),
                    if (reg != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l.regRegisteredOn(dayMonthYear(l, reg.createdAt.toLocal())),
                        style: AppText.caption.c(c.selectedCaption),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: AppSpace.cardGapWide),
          SectionHeader(title: l.regSubmitted),
          const SizedBox(height: AppSpace.sectionHeaderGap),
          AppCard(
            radius: AppRadius.listCard,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: Column(
              children: [
                for (final (i, (label, value)) in rows.indexed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(top: BorderSide(color: c.hairline)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppText.caption.c(c.ink3)),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)
                              .c(c.ink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => GroupedRows(
        rows: [AppListRow(icon: icon, tone: RowTone.neutral, title: text)],
      );
}

class _StatusShimmer extends StatelessWidget {
  const _StatusShimmer();

  @override
  Widget build(BuildContext context) => const GroupedRows(
        rows: [
          AppListRow(
            title: '',
            leading: Shimmer(width: 38, height: 38, radius: 19),
            trailing: Shimmer(width: 80, height: 18),
          ),
        ],
      );
}

/// A button that can't be pressed, its reason as the label.
class DisabledButton extends StatelessWidget {
  const DisabledButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: false,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: context.colors.neutralTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.buttonLarge.c(context.colors.inkDisabled),
          ),
        ),
      );
}

/// The event page's bottom bar for an event with a form, or null.
class RegistrationBar extends ConsumerWidget {
  const RegistrationBar({super.key, required this.upcoming});

  final UpcomingEvent upcoming;

  /// Whether the page shows a bar for [value] (to size its list's padding).
  static bool shown(AsyncValue<RegistrationState> value) =>
      switch (RegistrationView.of(value)) {
        RegistrationGone() => false,
        RegistrationLoaded(:final state) => state.available && !state.registered,
        _ => true,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final id = upcoming.event.id;
    final value = ref.watch(registrationStateProvider(id));

    Widget bar(Widget button, [String? note]) => StickyBottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              button,
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: AppText.caption.c(context.colors.ink3),
                ),
              ],
            ],
          ),
        );

    Future<void> register() async {
      final messenger = ScaffoldMessenger.of(context);
      final done = await context.push<bool>('/community/event/register', extra: upcoming);
      if (done == true) {
        messenger.showSnackBar(SnackBar(content: Text(l.regDone)));
      }
    }

    if (!shown(value)) return const SizedBox.shrink();
    return switch (RegistrationView.of(value)) {
      RegistrationFailed() => bar(
          GhostButton(
            label: l.tryAgain,
            onTap: () => ref.invalidate(registrationStateProvider(id)),
          ),
        ),
      RegistrationLoaded(:final state) => switch (state.status) {
          RegStatus.full => bar(DisabledButton(label: l.regFull)),
          RegStatus.deadlinePassed => bar(DisabledButton(label: l.regDeadlinePassed)),
          RegStatus.closed || RegStatus.registered => bar(DisabledButton(label: l.regClosed)),
          RegStatus.open when state.me == null => bar(
              PrimaryButton(
                label: l.regSignInToRegister,
                // Back here after signing in; the state refetches itself.
                onTap: () => context.push('/profile/sign-in'),
              ),
              l.regSignInNote,
            ),
          RegStatus.open when !state.me!.hasProfile =>
            bar(DisabledButton(label: l.register), l.regNoProfile),
          RegStatus.open => bar(PrimaryButton(label: l.register, onTap: register)),
        },
      _ => bar(DisabledButton(label: l.register)),
    };
  }
}
