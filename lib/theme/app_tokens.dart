// ignore_for_file: unnecessary_import
// (kept verbatim from the designer's handoff; only this lint line is ours)
// Pape Mosque — design tokens.
// Generated from the approved design canvas. Do not hand-tune values here
// without updating IMPLEMENTATION-SPEC.md.

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------- COLOR

/// Every colour the app paints, in a light and a dark set. Widgets read the
/// active set with `context.colors` — never a literal — so both modes follow
/// the theme. Dark values come from the dark Prayer home design ("Dark —
/// home (tam kaydırma)"); a token the design doesn't show is derived from
/// its neighbours and checked for WCAG AA on its surface.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.ground,
    required this.card,
    required this.cardMuted,
    required this.raised,
    required this.heroBase,
    required this.green,
    required this.onGreen,
    required this.greenDark,
    required this.greenDeep,
    required this.greenLabel,
    required this.greenTint,
    required this.greenTintStrong,
    required this.greenRowBg,
    required this.brandTile,
    required this.gradTop,
    required this.gradMid,
    required this.gradBottom,
    required this.night,
    required this.nightPill,
    required this.nightChip,
    required this.nightDivider,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.inkDisabled,
    required this.placeholder,
    required this.chevron,
    required this.tabInactive,
    required this.neutralTint,
    required this.hairline,
    required this.border,
    required this.dashedBorder,
    required this.segmentTrack,
    required this.segmentThumb,
    required this.switchTrackOff,
    required this.switchKnob,
    required this.switchKnobOn,
    required this.grabber,
    required this.pressWash,
    required this.shimmerFrom,
    required this.shimmerTo,
    required this.islandBg,
    required this.islandBorder,
    required this.barBg,
    required this.barBorder,
    required this.barrier,
    required this.unreadDot,
    required this.snackBg,
    required this.snackText,
    required this.blue,
    required this.blueTint,
    required this.goldText,
    required this.goldTextSoft,
    required this.goldBg,
    required this.goldBorder,
    required this.goldCircle,
    required this.goldChevron,
    required this.danger,
    required this.onDanger,
    required this.dangerTint,
    required this.dangerBorder,
    required this.dangerChevron,
    required this.amber,
    required this.amberTint,
    required this.photoBandBg,
    required this.photoBandArt,
    required this.onHero,
    required this.onHeroSecondary,
    required this.onHeroLabel,
    required this.onHeroChipText,
    required this.heroPillBg,
    required this.heroChipBg,
    required this.heroCircleBg,
    required this.heroDivider,
    required this.heroArcTrack,
    required this.heroKnobHalo,
    required this.onGradientButtonText,
    required this.heroShimmerTo,
    required this.heroShimmerFrom,
    required this.heroOutline,
  });


  /// Which set this is.
  final Brightness brightness;

  // Surfaces
  final Color ground; // page background, every screen
  final Color card;
  final Color cardMuted; // last row of a grouped card
  final Color raised; // white chips over photos, the segment thumb

  // Brand green
  final Color heroBase; // solid fallback under the gradient
  final Color green; // primary action, active tab, NOW badge
  final Color onGreen; // text and icons on [green]
  final Color greenDark; // pressed, icon on white
  final Color greenDeep; // text on the active prayer row
  final Color greenLabel; // IQAMAH label on the active prayer row
  final Color greenTint; // icon circle fill
  final Color greenTintStrong; // active icon circle fill
  final Color greenRowBg; // active prayer row background
  final Color brandTile; // the app icon's green behind the mosque mark

  // Hero gradient stops — 148deg, three stops
  final Color gradTop;
  final Color gradMid;
  final Color gradBottom;

  // Night — the Prayer home's moon hero (dark mode paints it with the gradient)
  final Color night;
  final Color nightPill; // 14% / 16%
  final Color nightChip; // 10% / 12%
  final Color nightDivider; // 10% / 14%

  // Text
  final Color ink; // primary
  final Color ink2; // secondary
  final Color ink3; // caption — do not go lighter (4.83:1 / 5.09:1)
  final Color ink4; // IQAMAH label only, >= 10px bold
  final Color inkDisabled; // disabled button label
  final Color placeholder; // text field hint
  final Color chevron;
  final Color tabInactive;

  // Neutral fills and lines
  final Color neutralTint; // inactive icon circle, ghost button
  final Color hairline; // row divider inside a card
  final Color border; // outlined button
  final Color dashedBorder; // the upload drop zone
  final Color segmentTrack;
  final Color segmentThumb;
  final Color switchTrackOff;
  final Color switchKnob;
  final Color switchKnobOn;
  final Color grabber; // sheet handle
  final Color pressWash; // table-cell highlight while pressed
  final Color shimmerFrom;
  final Color shimmerTo;

  // Frosted bars and overlays
  final Color islandBg; // 82%
  final Color islandBorder;
  final Color barBg; // sticky bottom bar
  final Color barBorder;
  final Color barrier; // behind sheets
  final Color unreadDot;
  final Color snackBg;
  final Color snackText;

  // Secondary accent — sunrise, announcements
  final Color blue;
  final Color blueTint;

  // Gold — Jumu'ah and Eid ONLY
  final Color goldText;
  final Color goldTextSoft;
  final Color goldBg;
  final Color goldBorder;
  final Color goldCircle;
  final Color goldChevron;

  // Status
  final Color danger;
  final Color onDanger; // label on a [danger] button
  final Color dangerTint;
  final Color dangerBorder;
  final Color dangerChevron;

  // Warning — the panel's "warning" banner tone only (gold stays Jumu'ah/Eid)
  final Color amber; // 5.4:1 / 7.9:1 on amberTint
  final Color amberTint;

  // Illustration placeholders
  final Color photoBandBg;
  final Color photoBandArt;

  // On-gradient overlays (white at alpha) — the same in both modes
  final Color onHero;
  final Color onHeroSecondary; // 78%
  final Color onHeroLabel; // 80%
  final Color onHeroChipText; // 85%
  final Color heroPillBg; // 16%
  final Color heroChipBg; // 12%
  final Color heroCircleBg; // 14%
  final Color heroDivider; // 16%
  final Color heroArcTrack; // 18%
  final Color heroKnobHalo; // 22%
  final Color onGradientButtonText; // the white button on a gradient
  final Color heroOutline; // 30% — outlined button on a gradient
  final Color heroShimmerFrom; // shimmer on the hero
  final Color heroShimmerTo;

  Color get success => green; // no separate success hue

  /// The tab-root gradient: linear-gradient(148deg, top 0%, mid 56%,
  /// bottom 100%).
  LinearGradient get heroGradient => LinearGradient(
        begin: const Alignment(-0.53, -0.85),
        end: const Alignment(0.53, 0.85),
        colors: [gradTop, gradMid, gradBottom],
        stops: const [0.0, 0.56, 1.0],
      );

  /// The Prayer home's moon hero: solid night navy in light mode, the green
  /// gradient in dark mode (as the dark design draws it).
  Gradient? get nightGradient =>
      brightness == Brightness.dark ? heroGradient : null;

  /// The original handoff palette.
  static const light = AppColors(
    brightness: Brightness.light,
    ground: Color(0xFFEEF1EF),
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFFBFDFC),
    raised: Color(0xFFFFFFFF),
    heroBase: Color(0xFF10412F),
    green: Color(0xFF0E7550),
    onGreen: Color(0xFFFFFFFF),
    greenDark: Color(0xFF0C5B3E),
    greenDeep: Color(0xFF126148),
    greenLabel: Color(0xFF5C7E6D),
    greenTint: Color(0xFFF1F8F4),
    greenTintStrong: Color(0xFFDCEDE4),
    greenRowBg: Color(0xFFF3F9F5),
    brandTile: Color(0xFF0F4D3A),
    gradTop: Color(0xFF135442),
    gradMid: Color(0xFF0F4538),
    gradBottom: Color(0xFF072A26),
    night: Color(0xFF0E1A2B),
    nightPill: Color(0x24FFFFFF),
    nightChip: Color(0x1AFFFFFF),
    nightDivider: Color(0x1AFFFFFF),
    ink: Color(0xFF0F1C17),
    ink2: Color(0xFF4E5F58),
    ink3: Color(0xFF67766F),
    ink4: Color(0xFF8A9892),
    inkDisabled: Color(0xFF7C8A84),
    placeholder: Color(0xFFA4B0AA),
    chevron: Color(0xFF9AA8A2),
    tabInactive: Color(0xFF5F6E68),
    neutralTint: Color(0xFFF2F6F4),
    hairline: Color(0xFFEFF3F1),
    border: Color(0xFFE2E9E5),
    dashedBorder: Color(0xFFBFD3C8),
    segmentTrack: Color(0xFFE3E8E5),
    segmentThumb: Color(0xFFFFFFFF),
    switchTrackOff: Color(0xFFD6DCD9),
    switchKnob: Color(0xFFFFFFFF),
    switchKnobOn: Color(0xFFFFFFFF),
    grabber: Color(0xFFDDE3E0),
    pressWash: Color(0x0F0F1C17),
    shimmerFrom: Color(0xFFE8EDEB),
    shimmerTo: Color(0xFFF4F7F6),
    islandBg: Color(0xD1FFFFFF),
    islandBorder: Color(0xBFFFFFFF),
    barBg: Color(0xD1FFFFFF),
    barBorder: Color(0x120A3222),
    barrier: Color(0x6B0F1C17),
    unreadDot: Color(0xFFC2453B),
    snackBg: Color(0xFF0F1C17),
    snackText: Color(0xFFFFFFFF),
    blue: Color(0xFF3C6E96),
    blueTint: Color(0xFFEAF2F8),
    goldText: Color(0xFF6B4E0D),
    goldTextSoft: Color(0xFF7E5C12),
    goldBg: Color(0xFFF8F1DF),
    goldBorder: Color(0xFFEFE3C7),
    goldCircle: Color(0xFFF1E3C2),
    goldChevron: Color(0xFF8A6516),
    danger: Color(0xFFA8332A),
    onDanger: Color(0xFFFFFFFF),
    dangerTint: Color(0xFFFBEDEC),
    dangerBorder: Color(0xFFE9C3BF),
    dangerChevron: Color(0xFFC99A95),
    amber: Color(0xFF9A4F00),
    amberTint: Color(0xFFFFF1DE),
    photoBandBg: Color(0xFFE7F0EA),
    photoBandArt: Color(0xFFD5E6DC),
    onHero: Color(0xFFFFFFFF),
    onHeroSecondary: Color(0xC7FFFFFF),
    onHeroLabel: Color(0xCCFFFFFF),
    onHeroChipText: Color(0xD9FFFFFF),
    heroPillBg: Color(0x29FFFFFF),
    heroChipBg: Color(0x1FFFFFFF),
    heroCircleBg: Color(0x24FFFFFF),
    heroDivider: Color(0x29FFFFFF),
    heroArcTrack: Color(0x2EFFFFFF),
    heroKnobHalo: Color(0x38FFFFFF),
    onGradientButtonText: Color(0xFF0C5B3E),
    heroOutline: Color(0x4DFFFFFF),
    heroShimmerFrom: Color(0x14FFFFFF),
    heroShimmerTo: Color(0x2EFFFFFF),
  );

  /// Matched to the dark design.
  static const dark = AppColors(
    brightness: Brightness.dark,
    ground: Color(0xFF0A1310),
    card: Color(0xFF141F1B),
    cardMuted: Color(0xFF19231F),
    raised: Color(0xFF1F2C27),
    heroBase: Color(0xFF10412F),
    green: Color(0xFF4ECFA0),
    onGreen: Color(0xFF06251A),
    greenDark: Color(0xFF4ECFA0),
    greenDeep: Color(0xFF4ECFA0),
    greenLabel: Color(0xFF45B088),
    greenTint: Color(0x1F4ECFA0),
    greenTintStrong: Color(0x294ECFA0),
    greenRowBg: Color(0x144ECFA0),
    brandTile: Color(0xFF0F4D3A),
    gradTop: Color(0xFF17604A),
    gradMid: Color(0xFF114A39),
    gradBottom: Color(0xFF0A2E24),
    night: Color(0xFF10412F),
    nightPill: Color(0x29FFFFFF),
    nightChip: Color(0x1FFFFFFF),
    nightDivider: Color(0x24FFFFFF),
    ink: Color(0xFFEDF3F0),
    ink2: Color(0xFFA7B8B0),
    ink3: Color(0xFF7F918A),
    ink4: Color(0xFF7F918A),
    inkDisabled: Color(0xFF5E6E68),
    placeholder: Color(0xFF7F918A),
    chevron: Color(0xFF5E6E68),
    tabInactive: Color(0xFF8A9B94),
    neutralTint: Color(0x0FFFFFFF),
    hairline: Color(0x12FFFFFF),
    border: Color(0x1FFFFFFF),
    dashedBorder: Color(0x33FFFFFF),
    segmentTrack: Color(0x14FFFFFF),
    segmentThumb: Color(0xFF2A3833),
    switchTrackOff: Color(0x29FFFFFF),
    switchKnob: Color(0xFFEDF3F0),
    switchKnobOn: Color(0xFF06251A),
    grabber: Color(0x33FFFFFF),
    pressWash: Color(0x0FFFFFFF),
    shimmerFrom: Color(0x0FFFFFFF),
    shimmerTo: Color(0x1FFFFFFF),
    islandBg: Color(0xD1141F1B),
    islandBorder: Color(0x1AFFFFFF),
    barBg: Color(0xD1141F1B),
    barBorder: Color(0x1AFFFFFF),
    barrier: Color(0x99000000),
    unreadDot: Color(0xFFF07A70),
    snackBg: Color(0xFF2A3833),
    snackText: Color(0xFFEDF3F0),
    blue: Color(0xFF8AB8E0),
    blueTint: Color(0x1F8AB8E0),
    goldText: Color(0xFFE3B964),
    goldTextSoft: Color(0xC7E3B964),
    goldBg: Color(0xFF241D11),
    goldBorder: Color(0x38E3B964),
    goldCircle: Color(0x24E3B964),
    goldChevron: Color(0x99E3B964),
    danger: Color(0xFFF08A80),
    onDanger: Color(0xFF2A0B08),
    dangerTint: Color(0x1FF08A80),
    dangerBorder: Color(0x4DF08A80),
    dangerChevron: Color(0x99F08A80),
    amber: Color(0xFFF2B45A),
    amberTint: Color(0x24F2B45A),
    photoBandBg: Color(0xFF17251F),
    photoBandArt: Color(0xFF22362D),
    onHero: Color(0xFFFFFFFF),
    onHeroSecondary: Color(0xC7FFFFFF),
    onHeroLabel: Color(0xCCFFFFFF),
    onHeroChipText: Color(0xD9FFFFFF),
    heroPillBg: Color(0x29FFFFFF),
    heroChipBg: Color(0x1FFFFFFF),
    heroCircleBg: Color(0x24FFFFFF),
    heroDivider: Color(0x29FFFFFF),
    heroArcTrack: Color(0x2EFFFFFF),
    heroKnobHalo: Color(0x38FFFFFF),
    onGradientButtonText: Color(0xFF0C5B3E),
    heroOutline: Color(0x4DFFFFFF),
    heroShimmerFrom: Color(0x14FFFFFF),
    heroShimmerTo: Color(0x2EFFFFFF),
  );

  @override
  AppColors copyWith() => this;

  /// Colours snap rather than blend: a mode change repaints at once.
  @override
  AppColors lerp(AppColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppColorsContext on BuildContext {
  /// The active palette (light or dark).
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// The active shadow set (light or dark).
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;
}

// --------------------------------------------------------------- RADIUS

abstract final class AppRadius {
  static const hero = 28.0;
  static const card = 26.0;
  static const listCard = 24.0;
  static const tile = 16.0;
  static const dateBadgeOnPhoto = 14.0;
  static const segmentOuter = 11.0;
  static const segmentThumb = 9.0;
  static const island = 32.0;
  static const pill = 999.0;
}

// ----------------------------------------------------------------- MOON

abstract final class AppMoon {
  static const box = 176.0; // reserved square for the moon widget
  static const disc = 144.0; // moon diameter inside it; 16 px glow ring each side
  static const topInCard = 58.0; // 20 padding + 26 top row + 12 gap
}

// -------------------------------------------------------------- SPACING

abstract final class AppSpace {
  static const pageGutter = 20.0;
  static const safeTop = 59.0; // status-bar inset; never paint here
  static const cardGap = 14.0; // tight stacks
  static const cardGapWide = 18.0; // between sections
  static const cardPadding = 18.0;
  static const heroPadding = 20.0;
  static const rowPaddingV = 13.0;
  static const rowPaddingH = 18.0;
  static const rowGap = 13.0;
  // Present in IMPLEMENTATION-SPEC.md §2 (spacing table) but absent from the
  // handoff file; added here so screens don't hardcode it.
  static const sectionHeaderGap = 10.0;
  static const islandInset = 16.0; // left/right
  static const islandBottom = 30.0;
  static const islandHeight = 64.0;
  static const scrollBottomInset = 96.0; // so the last card clears the island
}

// --------------------------------------------------------------- SHADOW

/// The elevation set for each mode. Light shadows are tinted with the brand
/// green; on the dark ground they are plain black, deeper and softer, as the
/// dark design draws them. Read with `context.shadows`.
// CSS blur-radius maps ~1:1 to Flutter blurRadius; if it reads too soft,
// scale blurRadius by 0.85 rather than changing opacity.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.card,
    required this.hero,
    required this.island,
    required this.night,
    required this.floatingButton,
    required this.greenButton,
    required this.switchKnob,
    required this.segmentThumb,
    required this.badgeOnPhoto,
    required this.gold,
    required this.onGradientButton,
    required this.heroBadge,
  });

  final List<BoxShadow> card;
  final List<BoxShadow> hero;
  final List<BoxShadow> island;
  final List<BoxShadow> night;
  final List<BoxShadow> floatingButton;
  final List<BoxShadow> greenButton;
  final List<BoxShadow> switchKnob;
  final List<BoxShadow> segmentThumb;
  final List<BoxShadow> badgeOnPhoto;
  final List<BoxShadow> gold; // the Jumu'ah / Eid card
  final List<BoxShadow> onGradientButton; // the white button on a gradient
  final List<BoxShadow> heroBadge; // a gradient circle on a photo

  static const light = AppShadows(
    card: [
      BoxShadow(color: Color(0x0D0A3222), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
          color: Color(0x240A3222),
          offset: Offset(0, 12),
          blurRadius: 30,
          spreadRadius: -10),
    ],
    hero: [
      BoxShadow(color: Color(0x2E08281C), offset: Offset(0, 2), blurRadius: 6),
      BoxShadow(
          color: Color(0x7308281C),
          offset: Offset(0, 22),
          blurRadius: 46,
          spreadRadius: -14),
    ],
    island: [
      BoxShadow(color: Color(0x120A3222), offset: Offset(0, 2), blurRadius: 6),
      BoxShadow(
          color: Color(0x570A3222),
          offset: Offset(0, 18),
          blurRadius: 36,
          spreadRadius: -12),
    ],
    night: [
      BoxShadow(color: Color(0x38080E1A), offset: Offset(0, 2), blurRadius: 6),
      BoxShadow(
          color: Color(0x8C080E1A),
          offset: Offset(0, 22),
          blurRadius: 46,
          spreadRadius: -14),
    ],
    floatingButton: [
      BoxShadow(color: Color(0x0F0A3222), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
          color: Color(0x2E0A3222),
          offset: Offset(0, 8),
          blurRadius: 20,
          spreadRadius: -8),
    ],
    greenButton: [
      BoxShadow(
          color: Color(0x990E7550),
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -6),
    ],
    switchKnob: [
      BoxShadow(color: Color(0x4D0A3222), offset: Offset(0, 2), blurRadius: 6),
    ],
    segmentThumb: [
      BoxShadow(color: Color(0x290A3222), offset: Offset(0, 1), blurRadius: 3),
    ],
    badgeOnPhoto: [
      BoxShadow(color: Color(0x2E0A3222), offset: Offset(0, 2), blurRadius: 8),
    ],
    gold: [
      BoxShadow(color: Color(0x0D503C0A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
          color: Color(0x38503C0A),
          offset: Offset(0, 10),
          blurRadius: 26,
          spreadRadius: -12),
    ],
    onGradientButton: [
      BoxShadow(
          color: Color(0x4D000000),
          offset: Offset(0, 4),
          blurRadius: 14,
          spreadRadius: -4),
    ],
    heroBadge: [
      BoxShadow(
          color: Color(0x8008281C),
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -4),
    ],
  );

  static const _darkCard = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, 14),
        blurRadius: 30,
        spreadRadius: -16),
  ];

  static const dark = AppShadows(
    card: _darkCard,
    hero: [
      BoxShadow(
          color: Color(0xBF000000),
          offset: Offset(0, 18),
          blurRadius: 40,
          spreadRadius: -18),
    ],
    island: [
      BoxShadow(
          color: Color(0xB3000000),
          offset: Offset(0, 18),
          blurRadius: 36,
          spreadRadius: -12),
    ],
    night: [
      BoxShadow(
          color: Color(0xBF000000),
          offset: Offset(0, 18),
          blurRadius: 40,
          spreadRadius: -18),
    ],
    floatingButton: _darkCard,
    greenButton: [
      BoxShadow(
          color: Color(0x664ECFA0),
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -8),
    ],
    switchKnob: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 6),
    ],
    segmentThumb: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 3),
    ],
    badgeOnPhoto: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
    ],
    gold: _darkCard,
    onGradientButton: [
      BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 4),
          blurRadius: 14,
          spreadRadius: -4),
    ],
    heroBadge: [
      BoxShadow(
          color: Color(0x99000000),
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -4),
    ],
  );

  @override
  AppShadows copyWith() => this;

  @override
  AppShadows lerp(AppShadows? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

// ------------------------------------------------------------ TYPOGRAPHY
// Leave fontFamily null on iOS: Flutter resolves to SF Pro.

const _tnum = <FontFeature>[FontFeature.tabularFigures()];

abstract final class AppText {
  static const heroTitle = TextStyle(
      fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);
  static const screenTitle = TextStyle(
      fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -0.7, height: 1.2);
  static const dateTitle = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4);
  static const eyebrow = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2);

  static const countdown = TextStyle(
      fontSize: 43,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.4,
      height: 1.06,
      fontFeatures: _tnum);
  static const countdownLabel = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.6);
  static const countdownSub =
      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500);

  static const sectionHeader = TextStyle(
      fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const cardTitle = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);
  static const rowTitle = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600);
  static const prayerName = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const caption = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400);
  static const body =
      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.6);
  static const bodyLarge =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.65);

  static const iqamahLabel = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8);
  static const iqamahValue = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600, fontFeatures: _tnum);

  static const buttonLarge = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const buttonSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const tabLabelActive = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const tabLabelIdle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static const badge = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1);
  static const segment = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600);
}
