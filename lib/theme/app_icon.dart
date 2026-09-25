import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The design's 35 stroke icons. All are 24×24 with `stroke="currentColor"`,
/// so the colour is applied here, not in the file.
abstract final class AppIcons {
  static const fajr = 'prayer-fajr';
  static const sunrise = 'prayer-sunrise';
  static const dhuhr = 'prayer-dhuhr';
  static const asr = 'prayer-asr';
  static const maghrib = 'prayer-maghrib';
  static const isha = 'prayer-isha';
  static const mosque = 'mosque';
  static const calendar = 'calendar';
  static const person = 'person';
  static const bell = 'bell';
  static const announcement = 'announcement';
  static const clock = 'clock';
  static const pin = 'pin';
  static const users = 'users';
  static const share = 'share';
  static const navigate = 'navigate';
  static const phone = 'phone';
  static const mail = 'mail';
  static const globe = 'globe';
  static const info = 'info';
  static const lock = 'lock';
  static const check = 'check';
  static const trash = 'trash';
  static const signOut = 'sign-out';
  static const chevronRight = 'chevron-right';
  static const chevronLeft = 'chevron-left';

  // Marriage service (spec §8a).
  static const documentLock = 'document-lock';
  static const document = 'document';
  static const upload = 'upload';
  static const shieldCheck = 'shield-check';
  static const eye = 'eye';
  static const replace = 'replace';
  static const close = 'close';
  static const photo = 'photo';

  // Recurring events (spec §7.3).
  static const repeat = 'repeat';

  /// Prayer row icon for a prayer name from `prayer_cache`.
  static String forPrayer(String name) => switch (name) {
        'Fajr' => fajr,
        'Sunrise' => sunrise,
        'Dhuhr' => dhuhr,
        'Asr' => asr,
        'Maghrib' => maghrib,
        'Isha' => isha,
        _ => mosque,
      };

  /// Event-card icon for `youth_events.category` (case-insensitive).
  /// Unknown categories, including `community`, get the calendar.
  static String forEventCategory(String category) =>
      switch (category.trim().toLowerCase()) {
        'education' => document, // Qur'an lessons, classes, study circles
        'youth' => person,
        'family' => users,
        'worship' => mosque, // prayer nights, tarawih, khatm
        _ => calendar,
      };
}

/// One of [AppIcons], tinted and sized.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, required this.size, required this.color});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// One of the two placeholder illustrations. `mosque-silhouette.svg` uses
/// `currentColor` and takes [color]; `map-placeholder.svg` carries its own
/// palette, so it is rendered untinted (pass no colour).
class AppIllustration extends StatelessWidget {
  const AppIllustration(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  static const mosqueSilhouette = 'mosque-silhouette';
  static const mapPlaceholder = 'map-placeholder';

  final String name;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/illustrations/$name.svg',
      width: width,
      height: height,
      fit: fit,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
