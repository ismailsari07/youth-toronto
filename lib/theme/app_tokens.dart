// ignore_for_file: unnecessary_import
// (kept verbatim from the designer's handoff; only this lint line is ours)
// Pape Mosque — design tokens.
// Generated from the approved design canvas. Do not hand-tune values here
// without updating IMPLEMENTATION-SPEC.md.

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------- COLOR

abstract final class AppColor {
  // Surfaces
  static const ground = Color(0xFFEEF1EF); // page background, every screen
  static const card = Color(0xFFFFFFFF);
  static const cardMuted = Color(0xFFFBFDFC); // last row of a grouped card

  // Brand green
  static const heroBase = Color(0xFF10412F); // solid fallback under the gradient
  static const green = Color(0xFF0E7550); // primary action, active tab, NOW badge
  static const greenDark = Color(0xFF0C5B3E); // pressed, icon on white
  static const greenDeep = Color(0xFF126148); // text on the active prayer row
  static const greenTint = Color(0xFFF1F8F4); // icon circle fill
  static const greenTintStrong = Color(0xFFDCEDE4); // active icon circle fill
  static const greenRowBg = Color(0xFFF3F9F5); // active prayer row background

  // Hero gradient stops — 148deg, three stops
  static const gradTop = Color(0xFF135442);
  static const gradMid = Color(0xFF0F4538);
  static const gradBottom = Color(0xFF072A26);

  // Night — Prayer root moon card
  static const night = Color(0xFF0E1A2B);
  static const nightPill = Color(0x24FFFFFF); // 14%
  static const nightChip = Color(0x1AFFFFFF); // 10%
  static const nightDivider = Color(0x1AFFFFFF); // 10%

  // Text
  static const ink = Color(0xFF0F1C17); // primary
  static const ink2 = Color(0xFF4E5F58); // secondary
  static const ink3 = Color(0xFF67766F); // caption — do not go lighter (4.83:1)
  static const ink4 = Color(0xFF8A9892); // IQAMAH label only, >= 10px bold
  static const chevron = Color(0xFF9AA8A2);
  static const tabInactive = Color(0xFF5F6E68);

  // Neutral fills and lines
  static const neutralTint = Color(0xFFF2F6F4); // inactive icon circle, ghost button
  static const hairline = Color(0xFFEFF3F1); // row divider inside a card
  static const border = Color(0xFFE2E9E5); // outlined button
  static const segmentTrack = Color(0xFFE3E8E5);

  // Secondary accent — sunrise, announcements
  static const blue = Color(0xFF3C6E96);
  static const blueTint = Color(0xFFEAF2F8);

  // Gold — Jumu'ah and Eid ONLY
  static const goldText = Color(0xFF6B4E0D);
  static const goldTextSoft = Color(0xFF7E5C12);
  static const goldBg = Color(0xFFF8F1DF);
  static const goldBorder = Color(0xFFEFE3C7);
  static const goldCircle = Color(0xFFF1E3C2);

  // Status
  static const danger = Color(0xFFA8332A);
  static const dangerTint = Color(0xFFFBEDEC);
  // Warning — the panel's "warning" banner tone only (gold stays Jumu'ah/Eid)
  static const amber = Color(0xFF9A4F00); // 5.4:1 on amberTint
  static const amberTint = Color(0xFFFFF1DE);
  static const success = green; // no separate success hue

  // Illustration placeholders
  static const photoBandBg = Color(0xFFE7F0EA);
  static const photoBandArt = Color(0xFFD5E6DC);

  // On-gradient overlays (white at alpha)
  static const onHero = Color(0xFFFFFFFF);
  static const onHeroSecondary = Color(0xC7FFFFFF); // 78%
  static const onHeroLabel = Color(0xCCFFFFFF); // 80%
  static const onHeroChipText = Color(0xD9FFFFFF); // 85%
  static const heroPillBg = Color(0x29FFFFFF); // 16%
  static const heroChipBg = Color(0x1FFFFFFF); // 12%
  static const heroCircleBg = Color(0x24FFFFFF); // 14%
  static const heroDivider = Color(0x29FFFFFF); // 16%
  static const heroArcTrack = Color(0x2EFFFFFF); // 18%
  static const heroKnobHalo = Color(0x38FFFFFF); // 22%
}

const heroGradient = LinearGradient(
  // CSS original: linear-gradient(148deg, #135442 0%, #0F4538 56%, #072A26 100%)
  begin: Alignment(-0.53, -0.85),
  end: Alignment(0.53, 0.85),
  colors: [AppColor.gradTop, AppColor.gradMid, AppColor.gradBottom],
  stops: [0.0, 0.56, 1.0],
);

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

abstract final class AppShadow {
  // CSS blur-radius maps ~1:1 to Flutter blurRadius; if it reads too soft,
  // scale blurRadius by 0.85 rather than changing opacity.
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0D0A3222), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
        color: Color(0x240A3222),
        offset: Offset(0, 12),
        blurRadius: 30,
        spreadRadius: -10),
  ];

  static const hero = <BoxShadow>[
    BoxShadow(color: Color(0x2E08281C), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(
        color: Color(0x7308281C),
        offset: Offset(0, 22),
        blurRadius: 46,
        spreadRadius: -14),
  ];

  static const island = <BoxShadow>[
    BoxShadow(color: Color(0x120A3222), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(
        color: Color(0x570A3222),
        offset: Offset(0, 18),
        blurRadius: 36,
        spreadRadius: -12),
  ];

  static const night = <BoxShadow>[
    BoxShadow(color: Color(0x38080E1A), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(
        color: Color(0x8C080E1A),
        offset: Offset(0, 22),
        blurRadius: 46,
        spreadRadius: -14),
  ];

  static const floatingButton = <BoxShadow>[
    BoxShadow(color: Color(0x0F0A3222), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
        color: Color(0x2E0A3222),
        offset: Offset(0, 8),
        blurRadius: 20,
        spreadRadius: -8),
  ];

  static const greenButton = <BoxShadow>[
    BoxShadow(
        color: Color(0x990E7550),
        offset: Offset(0, 6),
        blurRadius: 16,
        spreadRadius: -6),
  ];

  static const switchKnob = <BoxShadow>[
    BoxShadow(color: Color(0x4D0A3222), offset: Offset(0, 2), blurRadius: 6),
  ];

  static const segmentThumb = <BoxShadow>[
    BoxShadow(color: Color(0x290A3222), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const badgeOnPhoto = <BoxShadow>[
    BoxShadow(color: Color(0x2E0A3222), offset: Offset(0, 2), blurRadius: 8),
  ];
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
