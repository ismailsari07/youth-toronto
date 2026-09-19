/// Localisation groundwork (spec §9 step 7).
///
/// Every user-facing string belongs here rather than inline in a widget, so
/// that Turkish can be added without touching layout code. This is the
/// structure only — the strings are English and there is no translation yet.
///
/// When TR lands, the intended path is Flutter's own tooling:
///   1. `flutter pub add flutter_localizations --sdk` and `intl`
///   2. move these values into `lib/l10n/app_en.arb` and `app_tr.arb`
///   3. add `l10n.yaml`, run `flutter gen-l10n`
///   4. replace `AppStrings.x` with `AppLocalizations.of(context).x`
///      — call sites keep the same shape, so the swap is mechanical.
///
/// Dates and times must stay localisable too: they are formatted in
/// `lib/shared/formatters.dart`, not baked into these strings.
abstract final class AppStrings {
  // ── Tabs ──────────────────────────────────────────────────────────────────
  static const tabPrayer = 'Prayer';
  static const tabCommunity = 'Community';
  static const tabProfile = 'Profile';

  // ── Prayer root ───────────────────────────────────────────────────────────
  static const mosqueEyebrow = 'PAPE MOSQUE';
  static const nextPrayer = 'NEXT PRAYER';
  static const city = 'Toronto';
  static const todayAtTheMosque = 'Today at the mosque';
  static const athanIqamah = 'Athan · Iqamah';
  static const iqamah = 'IQAMAH';
  static const fajrWindowCloses = 'Fajr window closes';
  static const prayerReminders = 'Prayer reminders';
  static const prayerRemindersDetail = '5 minutes before each iqamah';
  static const timesUnavailable = 'Times unavailable';
  static const pullToRefresh = 'Pull to refresh';
  static const timesUnavailableTitle = "Today's times aren't available";
  static const timesUnavailableBody =
      'The mosque calendar could not be reached. Reminders already scheduled '
      'on this device still run.';
  static const tryAgain = 'Try again';
  static const jumuahThisFriday = "Jumu'ah · this Friday";
  static const jumuahEveryFriday = 'Every Friday at the mosque';

  // ── Community ─────────────────────────────────────────────────────────────
  static const events = 'Events';
  static const announcements = 'Announcements';
  static const noEventsTitle = 'No events scheduled';
  static const noEventsBody =
      'When the mosque publishes an event it will appear here. '
      "Jumu'ah runs every Friday as usual.";
  static const noAnnouncementsTitle = 'No announcements';
  static const noAnnouncementsBody =
      'Notices from the mosque office will appear here.';
  static const notifyMe = 'Tell me when something is posted';
  static const register = 'Register';
  static const registerFree = 'Register · free';
  static const aboutThisEvent = 'About this event';
  static const shareThisEvent = 'Share this event';
  static const shareThisAnnouncement = 'Share this announcement';
  static const questions = 'Questions?';
  static const callTheOffice = 'Call the mosque office';
  static const mosqueOffice = 'Mosque office';
  static const everyoneWelcome = 'Everyone is welcome';
  static const freeToAttend = 'Free to attend';
  static const map = 'Map';

  // ── Profile and account ───────────────────────────────────────────────────
  static const notSignedIn = "You're not signed in";
  static const notSignedInBody =
      'Sign in to register for events and keep your reminders across devices.';
  static const signIn = 'Sign in';
  static const createAccount = 'Create an account';
  static const signOut = 'Sign out';
  static const settings = 'Settings';
  static const yourDetails = 'Your details';
  static const notifications = 'Notifications';
  static const app = 'App';
  static const account = 'Account';
  static const language = 'Language';
  static const mosqueAndContact = 'Mosque & contact';
  static const aboutThisApp = 'About this app';
  static const worksWithoutAccount =
      'Prayer times, events and announcements work without an account.';
  static const deleteAccount = 'Delete account';
  static const deleteMyAccount = 'Delete my account';
  static const keepMyAccount = 'Keep my account';
  static const cannotBeUndone = 'This cannot be undone';
  static const typeDeleteToConfirm = 'Type DELETE to confirm';
  static const accountDeleted = 'Your account has been deleted.';

  // ── The mosque ────────────────────────────────────────────────────────────
  static const theMosque = 'THE MOSQUE';
  static const openingHours = 'Opening hours';
  static const getInTouch = 'Get in touch';
  static const directions = 'Directions';
  static const call = 'Call';
}
