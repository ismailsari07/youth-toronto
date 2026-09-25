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

  // ── Marriage service (spec §8a) ───────────────────────────────────────────
  // Tone: serious, modest, discreet. "Imam", never "coordinator". The word
  // "private" appears on every screen of the flow.
  static const mosqueServices = 'Mosque services';
  static const marriageService = 'Marriage service';
  // Shortened from the spec's "…through the mosque" so it fits one line at
  // 393 px; the "Mosque services" header already says where it comes from.
  static const marriageServiceRow = 'Confidential introductions';
  static const marriageEyebrow = 'MARRIAGE SERVICE';
  static const underReview = 'Under review';
  static String submittedOn(String date) => 'Submitted $date';

  // Gate (signed out)
  static const marriageGateTitle = 'Confidential introductions';
  static const marriageGateSubtitle = 'A service of Pape Mosque';
  static const marriageGateBody =
      'If you are looking to marry, you can share one document about yourself '
      "with the mosque's Imam. The Imam reads it in private and, if there is "
      'a suitable match, contacts you directly. Nothing is published and no '
      'one else sees it.';
  static const yourPrivacy = 'Your privacy';
  static const privacyOnlyImam = 'Only you and the Imam';
  static const privacyOnlyImamBody =
      'Your document is never shown to other members';
  static const privacyNoProfiles = 'No profiles, no browsing';
  static const privacyNoProfilesBody =
      'There is no listing or directory of applicants';
  static const privacyWithdraw = 'Withdraw at any time';
  static const privacyWithdrawBody =
      'Your document is deleted when you withdraw';
  static const marriageAgeNote = 'Open to members aged 18 and over.';
  static const signInToContinue = 'Sign in to continue';
  static const marriageGateCaption =
      'An account lets the Imam reach you privately.';

  // Date of birth (one-time entry for accounts created without one)
  static const dobTitle = 'Your date of birth';
  static const dobSubtitle = 'Needed once, kept private';
  static const dobBody =
      'The marriage service is open to members aged 18 and over. Your date '
      'of birth is saved to your account and cannot be changed afterwards, '
      'so please check it before you continue.';
  static const dobField = 'Date of birth';
  static const dobHint = 'Choose a date';
  static const dobContinue = 'Save and continue';
  static const saving = 'Saving…';
  static const dobSaveFailed =
      "Couldn't save your date of birth. Please try again.";

  // Not eligible (under 18)
  static const notEligibleTitle = 'Open to members aged 18 and over';
  static const notEligibleBody =
      'The marriage service is only available to adult members. Your account '
      'and everything else in the app are unaffected.';

  // Upload
  static const uploadTitle = 'Share your document';
  static const uploadSubtitle = 'One file, read only by the Imam';
  static const chooseOneFile = 'Choose one file';
  static const fileRules = 'PDF, JPG or PNG · up to 4 MB';
  static const files = 'Files';
  static const photos = 'Photos';
  static const whatToInclude = 'What to include';
  static const whatToIncludeBody1 =
      'There is no template. Write about yourself in your own words: your '
      'background, your family, your practice and what you are hoping for '
      'in a spouse. Turkish or English are both fine.';
  static const whatToIncludeBody2 =
      'Only share what you are comfortable with. The Imam will ask you '
      'directly if anything more is needed.';
  static const privacyStrip =
      "Private to you and the mosque's Imam. Never shown to other members.";
  static const submit = 'Submit';
  static const chooseFileToContinue = 'Choose a file to continue.';
  static const uploadingPrivately = 'Uploading privately…';
  static const uploading = 'Uploading…';
  static const keepAppOpen = 'Keep the app open until the upload finishes.';
  static const tooLarge = 'too large';
  static const tooLargeBody =
      'Files must be under 4 MB. Try exporting the PDF at a smaller size, or '
      'choose a single photo instead of several.';
  static const unsupportedType = 'not supported';
  static const unsupportedTypeBody =
      'Only PDF, JPG or PNG files can be shared.';
  static const unreadableFile = "Couldn't read this file. Try another one.";
  static const cantBeRead = "can't be read";
  static const preparingPrivately = 'Preparing privately…';
  static const detailsUnavailable =
      "Couldn't load your account details. Please try again.";
  static const uploadFailed =
      "The upload didn't finish. Check your connection and try again.";

  // Received
  static const receivedTitle = 'Received, thank you';
  static const receivedBody =
      'Your document is stored privately. Only you and the Imam can open it.';
  static const whatHappensNext = 'What happens next';
  static const nextImamReads = 'The Imam reads it';
  static const nextImamReadsBody = 'In private, when they are next available';
  static const nextContacted = "You're contacted privately";
  static const nextContactedBody = 'Only if there is a suitable match';
  static const nextYouDecide = 'You decide';
  static const nextYouDecideBody = 'Nothing happens without your agreement';
  static const done = 'Done';

  // Status
  static const yourApplication = 'Your application';
  static const underReviewBody =
      'The Imam has your document and will contact you privately if there is '
      "a suitable match. There's nothing more you need to do.";
  static const yourDocument = 'Your document';
  static const view = 'View';
  static const replace = 'Replace';
  static const withdrawTitle = 'Withdraw my application';
  static const withdrawCaption = "Deletes your document from the mosque's records";
  static const openFailed = "Couldn't open your document. Please try again.";

  // Withdraw sheet
  static const withdrawSheetTitle = 'Withdraw your application?';
  static const withdrawSheetBody =
      'Your document will be permanently deleted and the Imam will no longer '
      'see it. You can apply again at any time.';
  static const withdrawConfirm = 'Withdraw and delete';
  static const withdrawKeep = 'Keep my application';
  static const withdrawFailed =
      "Couldn't withdraw your application. Please try again.";
  static const withdrawn = 'Your application has been withdrawn.';

  // ── The mosque ────────────────────────────────────────────────────────────
  static const theMosque = 'THE MOSQUE';
  static const openingHours = 'Opening hours';
  static const getInTouch = 'Get in touch';
  static const directions = 'Directions';
  static const call = 'Call';
}
