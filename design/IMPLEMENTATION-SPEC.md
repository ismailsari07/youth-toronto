# Pape Mosque — Flutter implementation spec

Mosque community app for Pape Mosque (Canadian Turkish Islamic Trust), Toronto.
iOS-first, iPhone only, portrait only, light theme. System font (SF Pro).

This document is complete on its own. You do not need to see the design canvas.
Every value below is exact. Accompanying files:

- `app_tokens.dart` — all tokens as Dart constants, drop into `lib/theme/`
- `assets/icons/*.svg` — 34 icons, 24×24, stroke-based, `currentColor`
- `assets/illustrations/*.svg` — 2 placeholder illustrations
- `DESIGN-README.md` — the design rationale and the rules that must not be broken

---

## 0. Non-negotiable rules

These came out of real constraints. Breaking them breaks the design.

**No future prayer data exists.** The API serves today and past days only. Do not
build a monthly or yearly calendar — there is nothing to put in it. Today is the hero.
A weekly view may become possible later via a server change; design for that then.

**Events and announcements are often empty.** Every screen that lists them must look
finished at zero items. The home screen in particular must never show a hole — the
prayer content is sized so it fills the screen on its own and the community section
collapses away below the fold.

**Event photos are a layer, never the content.** Title, date, time and location always
come from text fields. If a photo exists it becomes a band on top of the card; if not,
the card starts at the date badge. Both variants are finished designs — no grey box, no
"no image" icon. Never accept a poster image as the only source of event information:
it kills TR/EN localisation, screen readers and search.

**No photos on announcements.** They are text notices. The absence of imagery is what
distinguishes them from events at a glance.

**Gold is reserved for Jumu'ah and Eid.** Nowhere else, ever.

**Hero cards only on tab roots.** The Prayer root carries the night-navy moon card
(section 6); Community and Profile roots carry the green gradient card. Either way the
hero always carries live content. Pushed screens get a plain nav bar
on the light ground. A green band holding only a back button and a title is decoration.

**No fake chrome.** Do not draw a status bar, home indicator or keyboard. The top
59 px is reserved padding.

**Accessibility.** Minimum touch target 44×44. Minimum text contrast 4.5:1
(3:1 at 24 px+). `AppColor.ink3` (#67766F) is the lightest permitted body/caption
colour at 4.83:1 — do not go lighter. All times use tabular figures.

**Placeholders to fill with real data:** `[STREET ADDRESS]`, `[POSTAL CODE]`,
`[PHONE NUMBER]`, `[EMAIL ADDRESS]`, `[WEBSITE]`. Hijri dates were deliberately left
out rather than approximated — add them under the Gregorian date once you have a
trusted source.

---

## 1. Tab structure

Three tabs. Root screens only; everything else is pushed onto the active tab's stack.

| # | Label | Icon asset | Root screen | Holds |
|---|---|---|---|---|
| 1 | Prayer | `mosque.svg` | `PrayerHomeScreen` | Countdown, today's six times with athan + iqamah, Jumu'ah card, reminders, mosque address card |
| 2 | Community | `calendar.svg` | `CommunityScreen` | Events and Announcements behind one segmented control |
| 3 | Profile | `person.svg` | `ProfileScreen` | Account, settings, mosque & contact |

**Why three.** Prayer is where nine of ten opens land. Events and announcements are the
same object to a user ("what is the mosque telling me") and are both frequently empty —
splitting them would produce two empty tabs. Profile is never empty because settings
exist whether or not the user is signed in.

**Mosque info gets no tab.** It is a once-ever lookup. It lives as a compact card at the
bottom of the Prayer scroll and as a full screen reachable from Profile.

Pushed screens per tab:

```
Prayer     → (none; the root scroll is the whole tab)
Community  → EventDetailScreen → EventRegisterScreen → RegisterDoneScreen
           → AnnouncementDetailScreen
Profile    → SignInScreen, SignUpScreen, SettingsScreen,
             DeleteAccountScreen, MosqueInfoScreen
```

The app is fully usable signed out. Sign-in is required only to register for an event.

---

## 2. Design tokens

All of the following are in `app_tokens.dart`. Hex values here for reference.

### Colour

**Surfaces**

| Token | Hex | Use |
|---|---|---|
| ground | `#EEF1EF` | Page background, every screen |
| card | `#FFFFFF` | Every card |
| cardMuted | `#FBFDFC` | Last row of a grouped card (reminders row) |

**Brand green**

| Token | Hex | Use |
|---|---|---|
| heroBase | `#10412F` | Solid fallback under the hero gradient |
| green | `#0E7550` | Primary button, active tab, NOW badge, eyebrow text |
| greenDark | `#0C5B3E` | Pressed state, icon colour on white circles |
| greenDeep | `#126148` | Text on the active prayer row |
| greenTint | `#F1F8F4` | Icon circle fill (green family) |
| greenTintStrong | `#DCEDE4` | Active prayer row icon circle |
| greenRowBg | `#F3F9F5` | Active prayer row background |

**Hero gradient** — `linear-gradient(148deg, #135442 0%, #0F4538 56%, #072A26 100%)`

In Flutter: `LinearGradient(begin: Alignment(-0.53, -0.85), end: Alignment(0.53, 0.85),
colors: [#135442, #0F4538, #072A26], stops: [0.0, 0.56, 1.0])`.
Single hue, three tones. Never introduce a second colour into this gradient.

**Text**

| Token | Hex | Contrast on white | Use |
|---|---|---|---|
| ink | `#0F1C17` | 17.2:1 | Primary text |
| ink2 | `#4E5F58` | 7.3:1 | Secondary text, body paragraphs |
| ink3 | `#67766F` | 4.83:1 | Captions. **Lightest permitted.** |
| ink4 | `#8A9892` | 3.1:1 | `IQAMAH` label only — 10 px bold, decorative pairing |
| chevron | `#9AA8A2` | — | Disclosure chevrons (non-text) |
| tabInactive | `#5F6E68` | 5.3:1 | Inactive tab label and icon |

**Lines and neutral fills**

| Token | Hex | Use |
|---|---|---|
| neutralTint | `#F2F6F4` | Inactive icon circle, ghost button fill |
| hairline | `#EFF3F1` | 1 px divider between rows inside a card |
| border | `#E2E9E5` | 1 px border on outlined circular buttons |
| segmentTrack | `#E3E8E5` | Segmented control track |

**Secondary accent** — used sparingly, for things that are not prayers

| Token | Hex | Use |
|---|---|---|
| blue | `#3C6E96` | Sunrise icon, announcement icon |
| blueTint | `#EAF2F8` | Their icon circle / tile fill |

**Gold — Jumu'ah and Eid only**

| Token | Hex | Use |
|---|---|---|
| goldText | `#6B4E0D` | Card title |
| goldTextSoft | `#7E5C12` | Card subtitle, icon |
| goldBg | `#F8F1DF` | Card fill |
| goldBorder | `#EFE3C7` | 1 px card border |
| goldCircle | `#F1E3C2` | Icon circle fill |

**Status**

| Token | Hex | Use |
|---|---|---|
| danger | `#A8332A` | Delete account text and button |
| dangerTint | `#FBEDEC` | Delete icon circle |
| amber | `#9A4F00` | Emergency banner, "warning" tone: text and icon (5.4:1 on amberTint) |
| amberTint | `#FFF1DE` | Emergency banner, "warning" tone: fill |
| success | `#0E7550` | Same as green — there is no separate success hue |

**On-gradient overlays** — white at alpha, never a solid colour

| Alpha | Use |
|---|---|
| 100% | Countdown digits, card title, prayer names |
| 85% | Location chip text |
| 80% | Countdown prayer label (`ASR`) |
| 78% | All secondary text on the gradient |
| 22% | Countdown knob halo |
| 18% | Arc track, "3 days" badge fill |
| 16% | `NEXT PRAYER` pill fill, hero internal divider |
| 14% | Icon circle fill |
| 12% | Location chip fill |

### Corner radius

| Element | Radius |
|---|---|
| Hero / gradient card | 28 |
| Standard card, event card | 26 |
| List card, announcement card, simple card | 24 |
| Inner tile, date badge (list) | 16 |
| Date badge over a photo | 14 |
| Segmented control track / thumb | 11 / 9 |
| Tab bar island | 32 |
| Pills, buttons, icon circles, switch | fully rounded (999) |

### Shadow

CSS notation is `offsetX offsetY blur spread colour`. Flutter `BoxShadow` equivalents
are in `app_tokens.dart`. Every shadow is two layers — a tight contact shadow plus a
wide soft one. Never use a single hard shadow.

| Name | Layers |
|---|---|
| card | `0 1px 2px rgba(10,50,34,.05)` + `0 12px 30px -10px rgba(10,50,34,.14)` |
| hero | `0 2px 6px rgba(8,40,28,.18)` + `0 22px 46px -14px rgba(8,40,28,.45)` |
| island | `0 2px 6px rgba(10,50,34,.07)` + `0 18px 36px -12px rgba(10,50,34,.34)` |
| floatingButton | `0 1px 2px rgba(10,50,34,.06)` + `0 8px 20px -8px rgba(10,50,34,.18)` |
| greenButton | `0 6px 16px -6px rgba(14,117,80,.6)` |
| switchKnob | `0 2px 6px rgba(10,50,34,.3)` |
| segmentThumb | `0 1px 3px rgba(10,50,34,.16)` |
| badgeOnPhoto | `0 2px 8px rgba(10,50,34,.18)` |

### Spacing

| Token | Value | Use |
|---|---|---|
| safeTop | 59 | Reserved top inset. Content starts here. Paint nothing above it. |
| pageGutter | 20 | Left and right page padding, every screen |
| cardGap | 14 | Between stacked cards in a tight list |
| cardGapWide | 18 | Between sections |
| cardPadding | 18 | Inside a standard card |
| heroPadding | 20 | Inside the gradient card (bottom 16–18) |
| rowPaddingV / H | 13 / 18 | Inside a list row |
| rowGap | 13 | Between a row's icon, text block and trailing element |
| sectionHeaderGap | 10 | Between a section header and its card |
| islandInset | 16 | Tab bar island left/right margin |
| islandBottom | 30 | Island distance from screen bottom |
| islandHeight | 64 | |
| scrollBottomInset | 96 | Bottom padding on every scroll view so the last card clears the island |

---

## 3. Typography

iOS system font. In Flutter, leave `fontFamily` null and it resolves to SF Pro.
All values in logical pixels. `tnum` means `FontFeature.tabularFigures()` — mandatory on
every clock time, or the countdown jitters every second.

| Style | Size | Weight | Letter-spacing | Line-height | Colour | Used for |
|---|---|---|---|---|---|---|
| heroTitle | 24 | 700 | −0.5 | 1.2 | white | "Community", "Profile" inside the gradient card |
| screenTitle | 27 | 700 | −0.7 | 1.2 | ink | Pushed-screen large title |
| dateTitle | 20 | 700 | −0.4 | — | ink | "Wednesday, 23 September" on home |
| eyebrow | 11 | 700 | +1.2 | — | green | `PAPE MOSQUE`, `ACCOUNT`, `EVENT`, `ANNOUNCEMENT` |
| countdown | 43 | 700 | −1.4 | 1.06 | white, tnum | The countdown digits |
| countdownLabel | 12 | 700 | +1.6 | — | white 80% | `ASR` above the digits |
| countdownSub | 12.5 | 500 | — | — | white 78% | "Athan 4:42 PM · Iqamah 5:00 PM" |
| sectionHeader | 16.5 | 700 | −0.2 | — | ink | "Today at the mosque", "Your details" |
| cardTitle | 17 | 700 | −0.3 | 1.25 | ink | Event title, announcement detail title |
| rowTitle | 15.5 | 600 | — | — | ink | List row primary text |
| prayerName | 16 | 600 | — | — | ink / greenDeep | Prayer names in the times list |
| caption | 12.5 | 400 | — | — | ink3 | Row subtitles, "Posted 2 days ago" |
| body | 14.5 | 400 | — | 1.6 | ink2 | Event description |
| bodyLarge | 15 | 400 | — | 1.65 | ink2 | Announcement detail body |
| iqamahLabel | 10 | 700 | +0.8 | — | ink4 / `#5C7E6D` on active row | The word `IQAMAH` |
| iqamahValue | 15 | 600 (700 active) | — | — | ink / greenDeep, tnum | The iqamah time |
| buttonLarge | 15 | 600 | — | — | white | 50 px pill buttons |
| buttonSmall | 14 | 600 | — | — | greenDark | 46 px ghost buttons |
| tabLabel | 10 | 600 active / 500 idle | +0.1 | — | green / tabInactive | Tab bar |
| badge | 10 | 700 | +1.1 | — | white | `NEXT PRAYER`, `NOW` (9 px here) |
| segment | 13.5 | 600 active / 500 idle | — | — | ink / ink2 | Segmented control |
| dateBadge | 9.5 / 23 / 9.5 | 700 / 700 / 600 | +1 / −0.7 / +0.6 | — | green / greenDark / ink2 | Day-of-week / day / month stack |

---

## 4. Shared components

Build these once. Every screen is assembled from them.

### 4.1 Card

`Container(decoration: BoxDecoration(color: card, borderRadius: 26, boxShadow: AppShadow.card))`.
Grouped cards clip their children (`clipBehavior: Clip.antiAlias`) so row backgrounds
follow the corner radius.

### 4.2 List row

Height 64 (13 px vertical padding + 38 px content). Horizontal padding 18. Gap 13.

```
[ icon circle 38×38, radius 999 ] [ title 15.5/600 + caption 12.5/400 ] [ trailing ]
```

Icon circle fill is `greenTint` with a `green` glyph by default; `neutralTint` +
`ink3` for a muted row; `blueTint` + `blue` for sunrise and announcements.
Icon renders at 19×19 inside the circle.
Trailing is a chevron (17 px, `chevron`), a value, a switch, or nothing.
Rows after the first carry a 1 px `hairline` top border.

### 4.3 Buttons

| Variant | Height | Fill | Text | Shadow |
|---|---|---|---|---|
| Primary | 50 | green | white 15/600 | greenButton |
| Primary on gradient | 50 | white | greenDark 15/600 | `0 4px 14px -4px rgba(0,0,0,.3)` |
| Ghost | 44–46 | neutralTint | greenDark 14/600 | none |
| Outlined circular | 46–50 | white, 1 px border | greenDark icon 19 | none |
| Destructive | 50 | danger | white 15/600 | none |
| Outlined on gradient | 46 | transparent, 1 px white 30% | white 14.5/600 | none |

All pill-shaped.

### 4.4 Switch

iOS geometry: track 51×31 radius 999, knob 27×27 inset 2, knob offset 22 when on.
Track `green` when on, `#D6DCD9` when off. Knob white with `switchKnob` shadow.
Wrap in a 51×44 transparent hit area to meet the 44 px minimum.

### 4.5 Segmented control

Track: full width, height 40, radius 11, fill `segmentTrack`, padding 2.
Thumb: equal-width, radius 9, white, `segmentThumb` shadow.
Labels 13.5 — `ink` at 600 when selected, `ink2` at 500 when not.

### 4.6 Date badge

Two variants of the same idea.

*In a list card:* 58×64, radius 16, fill `greenTint`. Three stacked lines centred:
weekday 9.5/700/+1 `green`, day 23/700/−0.7 `greenDark`, month 9.5/600/+0.6 `ink2`.

*Over a photo:* white fill, radius 14, padding 7×12, `badgeOnPhoto` shadow, positioned
16 from the photo band's top-left. Day renders at 20/700.

### 4.7 Gradient tab header

Only on the three tab roots.

```
Container(gradient: heroGradient, radius: 28, padding: 20/20/18, shadow: hero)
  Title 24/700/−0.5 white
  14 px gap
  1 px divider, white 16%
  14 px gap
  Row: [42×42 circle, white 14%, icon 21 white] [title 15.5/700 white + sub 12.5 white 78%] [badge]
```

The row must always carry live content. On Community it is the next event; when there
is no event it falls back to Jumu'ah, which is never empty. On Profile it is the
identity card or the sign-in call to action.

### 4.8 Plain nav bar

Every pushed screen. On the light ground, no gradient.

```
padding: 59 top, 20 sides
  44×44 circular white back button, margin-left −4, shadow floatingButton,
    chevron-left 20 px in greenDark
  16 px gap
  eyebrow 11/700/+1.2 green
  4 px gap
  title 27/700/−0.7 ink
  4 px gap
  subtitle 13.5/500 ink2
```

### 4.9 Empty state card

Not an apology — a card that still does something.

```
Card, padding 30/22/6
  72×72 circle, greenTint fill, 32 px icon in green
  14 px gap
  Title 17/700/−0.2 ink
  6 px gap
  Body 13.5/400/1.45 ink2, centred, max-width 258
  22 px gap, 1 px hairline, 14 px gap
  A working list row: bell icon, "Tell me when something is posted", switch (on)
```

---

## 5. Tab bar — floating island

Not a full-width bar. A detached pill.

```
position: bottom, left 16, right 16, bottom 30
height 64, radius 32, horizontal padding 6
fill: white at 82% opacity
backdrop blur: sigma 24 (CSS: saturate(180%) blur(24px))
border: 1 px, white at 75%
shadow: island
```

Three equal-flex items, each 64 tall (full-height hit target).
Item content is a centred column: icon 23 px, 3 px gap, label 10 px.

| State | Icon + label colour | Label weight |
|---|---|---|
| Active | `green` `#0E7550` | 600 |
| Idle | `tabInactive` `#5F6E68` | 500 |

An unread announcement shows a 9×9 dot, `#C2453B`, with a 2 px white ring, at the
top-right of the Profile icon.

Flutter:

```dart
Scaffold(
  extendBody: true,                       // required: content must flow under the island
  bottomNavigationBar: SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(height: 64, /* fill, border, shadow */),
        ),
      ),
    ),
  ),
)
```

Every scroll view needs `padding: EdgeInsets.only(bottom: 96)` or the last card hides
under the island.

An alternative "indicator" treatment exists in the design (active item sits inside a
solid `green` pill, 50 tall, radius 25, horizontal padding 16, white icon and label,
shadow `0 4px 12px -4px rgba(14,117,80,.7)`). Ship the plain version; the indicator is
a one-widget swap if it is ever wanted.

---

## 6. Signature element — the moon countdown card

The Prayer root's hero is a night-navy card holding an animated moon that fills with
glowing white liquid as the next prayer approaches. **The moon widget and all of its
animation (fill level, surface ripple, glow) are built in code and are out of scope for
this spec.** This section fixes the card, the layout around the moon, and the exact
square the moon widget must occupy.

### Card

| Property | Value |
|---|---|
| Position | Prayer root, first element after the date header, 14 below it (y 119 on a 390×844 screen) |
| Width | Full content width: screen − 2 × 20 (350 on a 390 screen) |
| Height | Content-driven, ≈ 407. **Do not hard-code** — it follows from the children below |
| Fill | `#0E1A2B` (night navy), solid. No gradient |
| Radius | 28 |
| Padding | 20 top, 20 left/right, 18 bottom |
| Shadow | `0 2px 6px rgba(8,14,26,.22)` + `0 22px 46px -14px rgba(8,14,26,.55)` |
| Clip | Clip children to the 28 radius (the glow must not leak past the card edge) |

### Vertical layout, top to bottom

```
20   padding
26   top row: NEXT PRAYER pill (left) · location chip (right)
12   gap
176  MOON AREA — 176 × 176 square, horizontally centred
14   gap
15   prayer label        ASR
2    gap
46   countdown           1:22:41
2    gap
15   sub line            Athan 4:42 PM · Iqamah 5:00 PM
16   gap
1    divider, white 10%
14   gap
30   bottom row: current prayer (left) · next prayer (right)
18   padding
───
≈407
```

### Moon area — the one number that matters

- Reserve a **176 × 176** square, centred horizontally in the card.
- Its top edge is **58** below the card's top edge (20 + 26 + 12). Its centre is at card
  y **146**.
- Inside it, the moon **disc is Ø 144**, centred. The remaining **16 px ring on every
  side is for the glow** — the widget may paint into it freely; nothing else overlaps it.
- Give the moon widget a fixed `SizedBox(width: 176, height: 176)`; never let it size
  itself from content.
- Accessibility: wrap the moon in `ExcludeSemantics`. The countdown text carries the
  meaning. When iOS **Reduce Motion** is on (`MediaQuery.disableAnimations`), stop the
  ripple; keep updating the fill level in steps.

### Elements

| Element | Spec |
|---|---|
| NEXT PRAYER pill | Height 26, radius 999, fill white 14%, padding 0/11. Text 10 / 700 / +1.1, white |
| Location chip | Height 26, radius 999, fill white 10%, padding 0 11 0 8, gap 5. `pin.svg` 13 + "Toronto" 11.5 / 600, white 85% |
| Prayer label | Upper-case prayer name. 12 / 700 / +1.6, white 80%, centred |
| Countdown | `H:MM:SS`. 43 / 700 / −1.4, line-height 1.06, white, **tabular figures**, centred |
| Sub line | "Athan 4:42 PM · Iqamah 5:00 PM". 12.5 / 500, white 78%, centred |
| Divider | 1 px, white 10%, full inner width |
| Bottom row | Space-between. Each side: 28×28 circle, white 10%, prayer icon 16 white, gap 9, then name 12.5 / 600 white over time 11.5 white 78%. Left = current prayer with " · now"; right = next prayer, right-aligned, circle on the outside |

All text on the navy card follows the same opacity ladder as the green hero:
100 / 85 / 80 / 78%. No coloured text on the card.

### Behaviour of the text (the moon is yours)

The digits tick every second (`Timer.periodic`). The fill fraction you feed the moon is
the elapsed share of the current prayer window:
`(now − currentAthan) / (nextAthan − currentAthan)`, clamped 0..1. At zero, advance to the
next prayer and let the moon drain to empty over 600 ms.

The old semicircle arc is retired. Its exploration artboards remain on the canvas for
history only.

---

## 7. Screens

Every screen: `ground` background, `pageGutter` 20, top inset 59, bottom scroll
inset 96.

### 7.1 Prayer — home (tab root)

Scrolls as one column.

0. **Emergency banner** (only while the panel has one active): full-width card, radius
   listCard, padding 14/16, icon 20 + text 14/600, then a 14 px gap. Tone from the
   panel: info = blueTint/blue + `info`, warning = amberTint/amber + `alert`,
   urgent = dangerTint/danger + `alert`. No dismiss; it ends at its `ends_at`.

1. **Header row**, height 46, bottom-aligned, space-between.
   Left: eyebrow "PAPE MOSQUE" 11.5/700/+0.9 green, then date 20/700/−0.4 ink.
   Right: 44×44 circular white button, `floatingButton` shadow, bell icon 21 greenDark.
2. 14 px gap. **Hero countdown card** — section 6.
3. 18 px gap. **Section header row**: "Today at the mosque" `sectionHeader`,
   right-aligned "Athan · Iqamah" 12/600 ink3.
4. 10 px gap. **Prayer times card** — grouped card, radius 26. Seven rows:

   | Row | Leading | Title | Subtitle | Trailing |
   |---|---|---|---|---|
   | Fajr | `prayer-fajr`, neutralTint/ink3 | Fajr 16/600 ink2 | Athan 5:42 AM | `IQAMAH` / 6:00 AM |
   | Sunrise | `prayer-sunrise`, blueTint/blue | Sunrise | Fajr window closes | 7:08 AM (no label) |
   | Dhuhr *(active)* | `prayer-dhuhr`, greenTintStrong/greenDark | Dhuhr 16/700 greenDeep + `NOW` badge | Athan 1:05 PM, ink2 | `IQAMAH` `#5C7E6D` / 1:30 PM 700 greenDeep |
   | Asr | `prayer-asr`, neutralTint/green | Asr | Athan 4:42 PM | `IQAMAH` / 5:00 PM |
   | Maghrib | `prayer-maghrib` | Maghrib | Athan 7:10 PM | `IQAMAH` / 7:15 PM |
   | Isha | `prayer-isha` | Isha | Athan 8:30 PM | `IQAMAH` / 8:45 PM |
   | Reminders | `bell`, greenTint/green, row bg `cardMuted` | Prayer reminders 15/600 | 5 minutes before each iqamah | switch |

   Active row background `greenRowBg`. The `NOW` badge: height 17, radius 999,
   padding 0/7, fill `green`, text 9/700/+0.7 white.
   Past prayers use `ink2` for name and time instead of `ink` — dimmer, still legible.

5. 18 px gap. **Jumu'ah card** (gold — the only gold in the app).
   Fill `goldBg`, 1 px `goldBorder`, radius 24, padding 16/18,
   shadow `0 1px 2px rgba(80,60,10,.05)` + `0 10px 26px -12px rgba(80,60,10,.22)`.
   Row: 42×42 circle `goldCircle` with `mosque` icon 22 in `goldTextSoft`;
   "Jumu'ah · this Friday" 15.5/700 `goldText`;
   "Khutbah 1:15 PM · Salah 1:35 PM" 13/500 `goldTextSoft`; chevron 18 `#8A6516`.
   Shown every day. Replaced by an Eid card, same treatment, when Eid times exist.
6. 20 px gap. **"From the community"** section header with a "See all" link
   (13/600 green) on the right.
7. 10 px gap. **Event card** (section 7.3) and **announcement card** (section 7.4),
   at most one of each. → *When both are empty, see 7.1a.*
8. 18 px gap. **Mosque card**: grouped card radius 24. One row —
   pin icon greenTint/green, "Canadian Turkish Islamic Trust" 15/600,
   "[STREET ADDRESS], Toronto" caption. Then a row of two ghost buttons,
   height 44, gap 10: "Directions" (navigate icon), "Call office" (phone icon).

**7.1a Home, nothing published.** Steps 6–7 are replaced by the empty state card
(4.9), headline "Nothing new this week", body "Events and announcements from Pape
Mosque will show up here. Prayer times keep running as usual."
Everything above is unchanged — that is what keeps the screen full. The section header
loses its "See all" link.

**7.1b Loading.** Prayer times arrive from cache almost always, so the common case is
no spinner. On a cold start with no cache: keep the layout, render the navy moon card
with an empty moon and a 43 px shimmer block where the digits go, and six shimmer rows in the
times card (shimmer: `#E8EDEB` → `#F4F7F6`, 1.2 s). Never show a full-screen spinner —
the chrome is known before the data is.

**7.1c Error.** If prayer times cannot be loaded at all, the hero card shows
"Times unavailable" 20/600 white, "Pull to refresh" 12.5 white 78%, and the moon renders
empty with no ripple. The rest of the screen renders normally.

### 7.2 Full daily prayer times

There is no separate screen. The home scroll *is* the daily list. This is deliberate —
it is honest about the data and it is what makes the home screen feel full. Do not add
a "see all times" destination.

### 7.3 Community — Events (tab root)

1. **Gradient tab header** (4.7). Title "Community". Row: calendar icon;
   next event title 15.5/700; "Saturday 26 September · 6:30 PM" 12.5 white 78%;
   trailing badge "3 days" — height 24, radius 999, padding 0/10, fill white 18%,
   text 11/700 white.
   *No upcoming event →* the row shows Jumu'ah instead: mosque icon,
   "Jumu'ah · this Friday", "Khutbah 1:15 PM · Salah 1:35 PM", no badge.
2. 16 px gap. **Segmented control** — Events | Announcements.
3. 16 px gap. **Event cards**, 14 px apart.

**Event card, with photo.** Card radius 26, clipped.
Photo band: height 160, fill `photoBandBg`, image cover-cropped centre.
Date badge over the photo at top-left (4.6). While there is no real image, render
`assets/illustrations/mosque-silhouette.svg` in `photoBandArt` bottom-aligned, plus a
small chip bottom-right — height 22, radius 999, fill white 82%, text 10/700/+0.7 ink2.
Body padding 16/18/18: title `cardTitle`; "Saturday · 6:30 PM – 9:00 PM" 13/500 ink2;
location row — pin icon 13 + text 12.5 ink3.
Then 14 px gap, 1 px hairline, 14 px gap, action row: primary "Register" button
(flex) + 50×50 outlined circular share button, gap 10.

**Event card, no photo.** Same card, padding 18, no band. Top row is the 58×64 date
badge + a text column (title, time, location) with 14 px gap and 5 px internal gaps.
Same divider and action row. A past or non-registerable event omits the action row.

**7.3a Events empty.** Gradient header falls back to Jumu'ah. Below the segmented
control: empty state card (4.9), mosque icon, "No events scheduled", body "When the
mosque publishes an event it will appear here. Jumu'ah runs every Friday as usual."
Then the mosque address card. The tab never looks broken.

**7.3b Loading.** Three shimmer cards at 176 px tall with the real card radius.

### 7.4 Community — Announcements

Same gradient header (row shows the newest announcement, `announcement` icon, badge
reads "New") and same segmented control, second segment selected.

**Announcement card.** Card radius 24, padding 16/18, row gap 13.
Leading: 38×38 rounded square, radius 12, `blueTint` fill, `announcement` icon 19 in
`blue`. Note this is a **square**, not a circle — it is how announcements read as a
different species from events.
Text column, 4 px gaps: title 15.5/700/−0.2 ink (with an 8×8 `green` unread dot,
4 px gap, top margin 6, when unread); excerpt 13/400/1.45 ink2, max two lines,
ellipsised; "Posted 2 days ago" 12 ink3.

**7.4a Announcements empty.** Empty state card, `announcement` icon,
"No announcements", body "Notices from the mosque office will appear here."

**7.5 Announcement detail.** Plain nav bar, eyebrow `ANNOUNCEMENT`, title = the
announcement title, subtitle "Posted 2 days ago · Mosque office".
18 px gap, then a card radius 26 padding 22/20 holding the body as paragraphs
(`bodyLarge`, 14 px between paragraphs), then 20 px gap, 1 px hairline, 16 px gap,
and an author row: 34×34 `greenTint` circle with `mosque` icon 17,
"Mosque office" 13/600, "Posted 2 days ago" 12 ink3.
Below: a grouped card with "Share this announcement" and "Call the mosque office",
then a "More announcements" section with one more card.

**7.6 Event detail.** Plain nav bar, eyebrow `EVENT`, title = event title,
subtitle "Saturday 26 September · 6:30 PM".
18 px gap: photo card (band height 180, no date badge — the nav bar already carries
the date). 14 px gap: grouped card of three rows — clock / "Saturday 26 September" /
"6:30 PM – 9:00 PM"; pin / venue / address with a trailing "Map" link 13/600 green;
users / "Open to everyone" / "Families welcome · 42 registered".
Section "About this event" then a card, padding 18, body paragraphs.
Grouped card: "Questions? / Call the mosque office" and "Share this event".
**Sticky bottom bar:** padding 12/20/30, fill white 82% with backdrop blur 22,
1 px top border `rgba(10,50,34,.07)`, one full-width primary button
"Register · free". It floats above the island (this screen is pushed, so the island
is not shown).

**7.7 Event register.** Plain nav bar, eyebrow `REGISTER`.
Section "Your details" → grouped card with three text fields.
Field row: padding 12/18, optional 34×34 radius-10 `neutralTint` icon tile,
label 11/600/+0.4 ink3 above the input 15.5/500 ink. Placeholder colour `#A4B0AA`.
Section "How many are coming?" → card with two stepper rows (Adults / Children).
Stepper: 44×44 circular outlined −/+ buttons, value 17/700 tabular with 30 px min width.
Disabled − at zero uses `#A4B0AA`.
Grouped card: "Remind me the day before" with a switch.
Sticky bottom bar: primary "Confirm registration" + 11.5 ink3 centred caption
"Your details are shared only with the mosque office."

**7.8 Register done.** No nav bar. Centred column, top padding 150.
96×96 circle with the hero gradient and `hero` shadow, `check` icon 44 white.
26 px gap, "You're registered" 26/700/−0.6 centred.
10 px gap, body 14.5/1.55 ink2 centred, max-width 280.
30 px gap: the event card in its no-photo form, with an action row of a ghost
"Add to calendar" button and an outlined circular share button.
18 px gap: "Cancel my registration" text link 14/600 green.
Sticky bottom: primary "Done" returning to the Community root.

### 7.9 Profile (tab root)

**Signed in.** Gradient tab header, title "Profile", then an identity row:
54×54 circle white 16% with initials 19/700/+0.5 white; name 18/700/−0.3 white;
"Member since March 2024" 12.5 white 78%; trailing 44×44 circular white-14% button
with a chevron.
Section "Your details" → grouped card, four rows (name, email, phone, date of birth),
each with the value as the row title and the field name as the caption, chevron trailing.
Section "Your events" → grouped card listing registrations
(check icon, event title, "Saturday 26 September · 2 places", chevron).
Grouped card: "Settings" (bell icon, "Reminders, language, about") and
"Mosque & contact" (pin icon).

**Signed out.** Same gradient card, but the row is: 46×46 circle, `person` icon,
"You're not signed in" 16/700 white, "Sign in to register for events and keep your
reminders across devices." 12.5/1.4 white 78%. Below it, 14 px gap, a column of two
buttons 8 px apart: primary-on-gradient "Sign in" (white fill) and
outlined-on-gradient "Create an account".
Then section "Settings" → grouped card with the reminders switch and the language row
(trailing "EN" 13.5 ink3 + chevron). Then a grouped card with "Mosque & contact" and
"About this app · Version 1.0".
Closing caption, centred, 12/1.5 ink3: "Prayer times, events and announcements work
without an account."

**7.10 Settings.** Plain nav bar, eyebrow `ACCOUNT`, title "Settings",
subtitle "Signed in as ismail@example.com".
Section "Notifications" → three switch rows: Prayer reminders (on),
Jumu'ah reminder (on), Events and announcements (off by default).
Section "App" → Language (trailing "EN" + chevron), Mosque & contact, About.
Section "Account" → "Sign out" row.
Then, 14 px below and visually separated, the destructive row: card radius 24,
padding 13/18, 38×38 `dangerTint` circle with `trash` icon 19 in `danger`,
label 15.5/600 `danger`, chevron `#C99A95`.

**7.11 Delete account.** Plain nav bar, eyebrow `ACCOUNT`, title "Delete account".
Card: 44×44 `dangerTint` circle with trash icon, "This cannot be undone" 17/700,
then two body paragraphs — what is removed, and that the app keeps working without an
account.
Section "What stays" → two rows (prayer reminders stay on-device; attendance already
recorded is kept as a count without a name).
Section "Confirm" → a single text field, "Type DELETE to confirm".
Sticky bottom: destructive "Delete my account" (fill `danger`) above a ghost
"Keep my account". Equal weight, destructive first — the user came here on purpose,
but the way out is just as visible.

**7.12 Sign in.** Plain nav bar, eyebrow `ACCOUNT`, title "Welcome back",
subtitle "Sign in to register for events".
Grouped card with two fields (email with `mail` icon tile, password with `lock`).
12 px gap, right-aligned "Forgot your password?" 13.5/600 green.
18 px gap, primary "Sign in".
24 px gap, a centred divider — hairline / "New to Pape Mosque?" 12 ink3 / hairline.
16 px gap, a white card-styled "Create an account" button (fill white, `card` shadow,
greenDark text).
24 px gap, centred caption 12.5/1.5 ink3 explaining the account is optional.

**7.13 Sign up.** Plain nav bar, title "Create an account", subtitle "So the office
knows who's coming". Grouped card with five fields: full name, email,
phone (optional), date of birth, password. Then a 12.5 ink3 privacy paragraph,
primary "Create account", and a centred "Already have an account? Sign in" row.

**7.14 Mosque & contact.** Plain nav bar, eyebrow `THE MOSQUE`.
Card radius 26: a 170 px map band (use the real map SDK; until then
`assets/illustrations/map-placeholder.svg`) with a 44×44 gradient-filled circular
pin marker centred, `mosque` icon 22 white, shadow
`0 6px 16px -4px rgba(8,40,28,.5)`. Below it, padding 16/18/18: name 17/700,
address 13.5/1.45 ink2 over two lines, then two buttons height 46 gap 10 —
primary "Directions", ghost "Call".
Section "Opening hours" → three rows (Daily, Jumu'ah, Office).
Section "Get in touch" → three rows (phone, email, website), each with a chevron.

### 7.15 Loading and error, generally

Shimmer, never spinners, for anything with a known shape. Shimmer gradient
`#E8EDEB` → `#F4F7F6`, 1.2 s, with the destination's real radius.
Network failure inside a tab: keep the gradient header (it can render from cache) and
put an inline card with the failure and a "Try again" ghost button where the list
would be. Never blank the whole screen.
Pull-to-refresh on all three tab roots, `CupertinoSliverRefreshControl`.

---

## 8. Assets

All icons are 24×24, stroke-based, `stroke-width: 1.8`, round caps and joins,
`stroke="currentColor"` — tint them in code. Render at 19 px inside 38 px circles,
21 px inside 42 px circles, 23 px in the tab bar, 13 px inline with text.

`assets/icons/`

| File | Used in |
|---|---|
| `prayer-fajr.svg` | Fajr row |
| `prayer-sunrise.svg` | Sunrise row |
| `prayer-dhuhr.svg` | Dhuhr row |
| `prayer-asr.svg` | Asr row |
| `prayer-maghrib.svg` | Maghrib row |
| `prayer-isha.svg` | Isha row |
| `mosque.svg` | Prayer tab, Jumu'ah card, empty states, map pin |
| `calendar.svg` | Community tab, event rows, date of birth |
| `person.svg` | Profile tab, name field |
| `bell.svg` | Reminders, home header button |
| `announcement.svg` | Announcement cards and header |
| `clock.svg` | Event detail time row, opening hours |
| `pin.svg` | Location rows, mosque card |
| `users.svg` | Event attendance row |
| `share.svg` | Share buttons |
| `navigate.svg` | Directions button |
| `phone.svg` | Call buttons, phone field |
| `mail.svg` | Email rows and field |
| `globe.svg` | Language row, website row |
| `info.svg` | About row |
| `lock.svg` | Password field |
| `check.svg` | Confirmation screen, registered events |
| `trash.svg` | Delete account |
| `sign-out.svg` | Sign out row |
| `chevron-right.svg` | Disclosure indicator |
| `chevron-left.svg` | Back button |

`assets/illustrations/`

| File | Size | Used in |
|---|---|---|
| `mosque-silhouette.svg` | 350×120 | Placeholder inside an event photo band while no real image exists. Uses `currentColor`; tint `#D5E6DC` on a `#E7F0EA` ground. |
| `map-placeholder.svg` | 350×170 | Stands in for the map on Mosque & contact until the map SDK is wired up. |

**Not exported, because they do not exist yet:** the app icon (green dome + two
minarets + crescent on cream), and any real event photography. Both come from the
mosque.

Register in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/illustrations/
```

Use `flutter_svg`. For the tab bar and list rows, wrap in
`SvgPicture.asset(path, colorFilter: ColorFilter.mode(colour, BlendMode.srcIn))`.

---

## 8a. Marriage service (added after v1 approval)

A confidential, traditional introduction service run by the mosque. A signed-in member
uploads **one document** about themselves; the mosque's marriage coordinator reads it and
contacts them privately if there is a suitable match. There are no form fields and there
is no directory. Matching is done off-app by the admin (dashboard to follow).

### Placement

A row under a new **"Mosque services"** section on the Profile tab root — the first
section after the gradient identity card. Not in Community: Community is a public feed,
and putting a private service next to events signals the opposite of what it is. Not a
fourth tab: a rarely used, personal service does not earn permanent navigation weight.
Profile is already the home of everything account-gated and personal.

Discovery: the mosque announces the service through a normal Announcement, and that
announcement deep-links to the service. The app itself never advertises it on the Prayer
or Community tabs.

| Profile state | Row title | Row subtitle | Trailing | Opens |
|---|---|---|---|---|
| Signed out | Marriage service | Confidential introductions through the mosque | chevron | Gate |
| Signed in, nothing submitted | Marriage service | Confidential introductions through the mosque | chevron | Upload |
| Signed in, submitted | Marriage service | Submitted 12 September | "Under review" pill (24 h, greenTint fill, greenDark 11/700) + chevron | Status |

Row icon: `document-lock.svg` in a greenTint circle.

### Screens

All pushed screens: plain nav bar, eyebrow `MARRIAGE SERVICE`. The island is hidden.

**1. Gate (signed out).** Title "Confidential introductions", subtitle "A service of Pape
Mosque". A card with one paragraph explaining the service. Section "Your privacy" → a
grouped card of three rows, all greenTint circles:
`shield-check` "Only you and the coordinator / Your document is never shown to other
members"; `close` "No profiles, no browsing / There is no listing or directory of
applicants"; `trash` "Withdraw at any time / Your document is deleted when you withdraw".
Caption 12.5 ink3 "Open to members aged 18 and over." Sticky bar: primary "Sign in to
continue", ghost "Create an account", caption "An account lets the coordinator reach
you privately." After sign-in, return here and continue straight to Upload.

**2. Upload — choose.** Title "Share your document", subtitle "One file, read only by
the coordinator". Drop-zone card: radius 26, white, **1.5 px dashed `#BFD3C8`** border,
`card` shadow, padding 26/20/20, centred: 60×60 greenTint circle with `upload` icon 26,
"Choose one file" 17/700, "PDF, JPG or PNG · up to 4 MB" 13 ink3, then two ghost
buttons side by side — "Files" (`document` icon → document picker) and "Photos"
(`photo` icon → photo library). Section "What to include" → card with two paragraphs of
gentle guidance (no template, Turkish or English fine, only share what you're
comfortable with). Privacy strip: greenTint rounded rect radius 18, padding 12/16,
`shield-check` 18 green + "Private to you and the mosque's marriage coordinator. Never
shown to other members." 12.5 greenDark. Sticky bar: disabled "Submit"
(fill `#E3E8E5`, text `#7C8A84`) + caption "Choose a file to continue."

Picking a file uploads immediately — there is no separate confirm step, because there is
nothing else to fill in.

**3. Uploading.** Drop zone is replaced by a file card: 46×54 radius-12 greenTint tile
with `document` icon and the extension (9/700), file name 15.5/600, "1.8 MB · PDF"
caption, 44×44 outlined cancel button (`close`). Progress track 6 px `#E3E8E5`, fill
`green`, radius 999. Below: "Uploading privately…" 12.5/600 greenDark left,
percentage tabular right. Sticky: primary at 55% opacity "Uploading…", caption "Keep
the app open until the upload finishes."

**4. Rejected file.** Same card with a 1.5 px `#E9C3BF` border, dangerTint tile,
"5.6 MB · too large" 12.5/600 danger, explanation 13.5 ink2 ("Files must be under 4 MB.
Try exporting the PDF at a smaller size, or choose a single photo instead of several."),
and the Files / Photos buttons again. Same pattern for an unsupported type:
"Only PDF, JPG or PNG files can be shared." Validate size and type **on device before
uploading**.

**5. Received.** No nav bar. Centred: 88×88 gradient circle, `check` 40 white, `hero`
shadow. "Received, thank you" 26/700. Body 14.5 ink2. Section "What happens next" →
grouped card of three numbered rows (28×28 greenTint circle with 13/700 number):
"The coordinator reads it", "You're contacted privately", "You decide". Privacy strip.
Sticky primary "Done" → Status.

**6. Your application (status).** Title "Your application", subtitle "Submitted 12
September". Status card: pill "● Under review" (26 h, greenTint, greenDark 12/700,
7 px green dot) + one reassuring paragraph ("there's nothing more you need to do").
Section "Your document" → file card with two ghost buttons: "View" (`eye`, opens the
file with a short-lived signed URL in an in-app viewer) and "Replace" (`replace`, goes
to Upload; the new file overwrites the old one only after the new upload succeeds).
Privacy strip. Then a destructive row card: dangerTint circle, `trash`, "Withdraw my
application" 15.5/600 danger, "Deletes your document from the mosque's records"
caption, chevron `#C99A95`.

**7. Withdraw sheet.** Bottom sheet over the status screen, scrim
`rgba(15,28,23,.42)`. Sheet: white, top radius 28, padding 10/20/34, grabber 40×5
`#DDE3E0`. 56×56 dangerTint circle with `trash` 24, "Withdraw your application?"
20/700 centred, body 14.5 ink2 centred ("permanently deleted… You can apply again at
any time"). Buttons stacked 10 apart: destructive "Withdraw and delete", ghost "Keep my
application". On success → Upload screen in its empty state.

v1 states are only: none → uploading → under review → (withdrawn = none). Further
states ("contacted", "closed") are the admin's concern and are **not** shown in the app
in v1 — the coordinator contacts people directly.

### Tone rules

Serious, modest, discreet. Say "marriage service", "introduction", "coordinator",
"suitable match". Never "dating", "profile", "matches" as a noun list, "swipe", "like".
No hearts, rings, couples, pink or gold. The only iconography is documents, a shield and
a lock. The word "private" appears on every screen of the flow.

### Privacy requirements — enforce on the server, not in the UI

The design promises the document is visible only to its owner and the coordinator. That
promise is only true if the backend makes it true.

1. Store files in a **private** Supabase Storage bucket. No public URLs, ever.
2. RLS on both the storage objects and the `marriage_applications` row: `select` /
   `insert` / `update` / `delete` for `auth.uid() = user_id`; `select` for the admin
   role only. No other role, no service key in the client.
3. Viewing uses `createSignedUrl` with a 60-second expiry, generated per tap.
4. Strip EXIF (including GPS) from photos **before** upload. Convert HEIC to JPG on
   device.
5. Never put the file name, the fact of application, or any content into push
   notifications, analytics events, crash reports or logs.
6. Withdrawal and account deletion **hard-delete** the object and the row. The Delete
   account screen copy already says so.
7. Enforce 18+ on the server from the profile's date of birth, not only in the UI.
8. One active document per user (unique constraint on `user_id`).

New icons for this feature (in `assets/icons/`): `document-lock.svg`, `document.svg`,
`upload.svg`, `shield-check.svg`, `eye.svg`, `replace.svg`, `close.svg`, `photo.svg`.

---

## 9. Build order

1. Tokens (`app_tokens.dart`), then the shared components in section 4.
2. The moon card shell (section 6) with a placeholder 176×176 box, then drop the moon
   widget in. Build it on a demo page with a slider driving the fill fraction.
3. Prayer tab: home, all three states (data, empty community, loading).
4. Tab scaffold and the island.
5. Community tab and its four pushed screens.
6. Profile tab and its six pushed screens.
7. Localisation pass — every string through ARB, no text baked into images.
