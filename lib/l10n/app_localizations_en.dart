// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pape Mosque';

  @override
  String get tabPrayer => 'Prayer';

  @override
  String get tabCommunity => 'Community';

  @override
  String get tabProfile => 'Profile';

  @override
  String prayer(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'other': '$prayer',
    });
    return '$_temp0';
  }

  @override
  String prayerSalah(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'other': '$prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayer(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'After Fajr',
      'sunrise': 'After sunrise',
      'dhuhr': 'After Dhuhr',
      'asr': 'After Asr',
      'maghrib': 'After Maghrib',
      'isha': 'After Isha',
      'other': 'After $prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayerInline(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'after Fajr',
      'sunrise': 'after sunrise',
      'dhuhr': 'after Dhuhr',
      'asr': 'after Asr',
      'maghrib': 'after Maghrib',
      'isha': 'after Isha',
      'other': 'after $prayer',
    });
    return '$_temp0';
  }

  @override
  String afterPrayerTitle(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'After Fajr prayer',
      'sunrise': 'After sunrise',
      'dhuhr': 'After Dhuhr prayer',
      'asr': 'After Asr prayer',
      'maghrib': 'After Maghrib prayer',
      'isha': 'After Isha prayer',
      'other': 'After $prayer prayer',
    });
    return '$_temp0';
  }

  @override
  String get organisationName => 'Canadian Turkish Islamic Trust';

  @override
  String get homeMosqueLine => 'Pape Mosque · Toronto';

  @override
  String get nextPrayer => 'NEXT PRAYER';

  @override
  String get city => 'Toronto';

  @override
  String get todayAtTheMosque => 'Today at the mosque';

  @override
  String get homeCommunitySection => 'Community';

  @override
  String get seeAll => 'See all';

  @override
  String get athanIqamah => 'Athan · Iqamah';

  @override
  String get iqamah => 'IQAMAH';

  @override
  String athanAt(String time) {
    return 'Athan $time';
  }

  @override
  String iqamahAt(String time) {
    return 'Iqamah $time';
  }

  @override
  String prayerNow(String prayer) {
    return '$prayer · now';
  }

  @override
  String get fajrWindowCloses => 'Fajr window closes';

  @override
  String get prayerReminders => 'Prayer reminders';

  @override
  String get prayerRemindersDetail => '5 minutes before each iqamah';

  @override
  String get remindersDeniedNote =>
      'Notifications for Pape Mosque are turned off in iOS Settings, so reminders can\'t appear.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get reminderBody => 'Iqamah in 5 minutes';

  @override
  String get timesUnavailable => 'Times unavailable';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get timesUnavailableTitle => 'Today\'s times aren\'t available';

  @override
  String get timesUnavailableBody =>
      'The mosque calendar could not be reached. Reminders already scheduled on this device still run.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get jumuahThisFriday => 'Jumu\'ah · this Friday';

  @override
  String get jumuahEveryFriday => 'Every Friday at the mosque';

  @override
  String get everyFriday => 'Every Friday';

  @override
  String salahAt(String time) {
    return 'Salah $time';
  }

  @override
  String get eidFitr => 'Eid al-Fitr';

  @override
  String get eidAdha => 'Eid al-Adha';

  @override
  String eidTimes(String first, String second) {
    return 'Salah $first · Second jamaah $second';
  }

  @override
  String get directions => 'Directions';

  @override
  String get call => 'Call';

  @override
  String get callOffice => 'Call office';

  @override
  String get hijriMonth1 => 'Muharram';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi\' al-Awwal';

  @override
  String get hijriMonth4 => 'Rabi\' al-Thani';

  @override
  String get hijriMonth5 => 'Jumada al-Awwal';

  @override
  String get hijriMonth6 => 'Jumada al-Thani';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Sha\'ban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get hijriMonth10 => 'Shawwal';

  @override
  String get hijriMonth11 => 'Dhu al-Qi\'dah';

  @override
  String get hijriMonth12 => 'Dhu al-Hijjah';

  @override
  String get datePatternTitle => 'EEEE, d MMMM';

  @override
  String get datePatternLong => 'EEEE d MMMM';

  @override
  String get datePatternShort => 'EEE d MMM';

  @override
  String get datePatternDayMonth => 'd MMMM';

  @override
  String get datePatternMonthYear => 'MMMM y';

  @override
  String get datePatternCard => 'MMM d';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String postedAgo(String ago) {
    return 'Posted $ago';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get repeatsWeekly => 'Repeats weekly';

  @override
  String get repeatsBiweekly => 'Repeats every 2 weeks';

  @override
  String get repeatsMonthly => 'Repeats monthly';

  @override
  String everyWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'Every Monday',
      'tue': 'Every Tuesday',
      'wed': 'Every Wednesday',
      'thu': 'Every Thursday',
      'fri': 'Every Friday',
      'sat': 'Every Saturday',
      'sun': 'Every Sunday',
      'other': 'Every Monday',
    });
    return '$_temp0';
  }

  @override
  String everyOtherWeekday(String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      'mon': 'Every other Monday',
      'tue': 'Every other Tuesday',
      'wed': 'Every other Wednesday',
      'thu': 'Every other Thursday',
      'fri': 'Every other Friday',
      'sat': 'Every other Saturday',
      'sun': 'Every other Sunday',
      'other': 'Every other Monday',
    });
    return '$_temp0';
  }

  @override
  String get everyTwoWeeks => 'Every 2 weeks';

  @override
  String get monthly => 'Monthly';

  @override
  String everyMonthOnDay(String day) {
    return 'Every month on the $day';
  }

  @override
  String get weeklyProgrammeEyebrow => 'WEEKLY PROGRAMME';

  @override
  String get biweeklyProgrammeEyebrow => 'BIWEEKLY PROGRAMME';

  @override
  String get monthlyProgrammeEyebrow => 'MONTHLY PROGRAMME';

  @override
  String get eventEyebrow => 'EVENT';

  @override
  String get weeklyProgramme => 'Weekly programme';

  @override
  String get biweeklyProgramme => 'Programme every 2 weeks';

  @override
  String get monthlyProgramme => 'Monthly programme';

  @override
  String nextOn(String date) {
    return 'next: $date';
  }

  @override
  String aboutTime(String time) {
    return 'about $time';
  }

  @override
  String beginsAboutOn(String begins, String time, String date) {
    return '$begins — about $time on $date';
  }

  @override
  String registerAt(String url) {
    return 'Register: $url';
  }

  @override
  String get events => 'Events';

  @override
  String get announcements => 'Announcements';

  @override
  String get noEventsTitle => 'No events scheduled';

  @override
  String get noEventsBody =>
      'When the mosque publishes an event it will appear here. Jumu\'ah runs every Friday as usual.';

  @override
  String get noAnnouncementsTitle => 'No announcements';

  @override
  String get noAnnouncementsBody =>
      'Notices from the mosque office will appear here.';

  @override
  String get notifyMe => 'Tell me when something is posted';

  @override
  String get newBadge => 'New';

  @override
  String get announcementEyebrow => 'ANNOUNCEMENT';

  @override
  String get register => 'Register';

  @override
  String get registerFree => 'Register · free';

  @override
  String get aboutThisEvent => 'About this event';

  @override
  String get shareThisEvent => 'Share this event';

  @override
  String get shareThisAnnouncement => 'Share this announcement';

  @override
  String get questions => 'Questions?';

  @override
  String get callTheOffice => 'Call the mosque office';

  @override
  String get mosqueOffice => 'Mosque office';

  @override
  String get everyoneWelcome => 'Everyone is welcome';

  @override
  String get freeToAttend => 'Free to attend';

  @override
  String get ticketed => 'Ticketed';

  @override
  String get map => 'Map';

  @override
  String get dropIn => 'Drop in — no registration needed';

  @override
  String get nextSession => 'Next session';

  @override
  String get startTime => 'Start time';

  @override
  String get date => 'Date';

  @override
  String get beginsAfterJamaah => 'Begins once the jama\'ah finishes';

  @override
  String get notSignedIn => 'You\'re not signed in';

  @override
  String get notSignedInBody =>
      'Sign in to register for events and keep your reminders across devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get createAccount => 'Create an account';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get creatingAccount => 'Creating…';

  @override
  String get signOut => 'Sign out';

  @override
  String get settings => 'Settings';

  @override
  String get settingsRowSubtitle => 'Reminders, language, account';

  @override
  String get yourDetails => 'Your details';

  @override
  String get notifications => 'Notifications';

  @override
  String get app => 'App';

  @override
  String get account => 'Account';

  @override
  String get accountEyebrow => 'ACCOUNT';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get notSignedInShort => 'Not signed in';

  @override
  String get language => 'Language';

  @override
  String get deviceLanguage => 'Device language';

  @override
  String get deviceLanguageDetail => 'Follows your phone\'s setting';

  @override
  String get languageAuto => 'Auto';

  @override
  String get mosqueAndContact => 'Mosque & contact';

  @override
  String get aboutThisApp => 'About this app';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get worksWithoutAccount =>
      'Prayer times, events and announcements work without an account.';

  @override
  String get member => 'Member';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get website => 'Website';

  @override
  String get notAdded => 'Not added';

  @override
  String get password => 'Password';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to register for events';

  @override
  String get noAccountYet => 'New to Pape Mosque?';

  @override
  String get accountOptional =>
      'An account is optional. Prayer times, events and announcements work without one.';

  @override
  String get signUpSubtitle => 'So the office knows who\'s coming';

  @override
  String get fullName => 'Full name';

  @override
  String get yourName => 'Your name';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get detailsSharedOnlyWithOffice =>
      'Your details are shared only with the mosque office.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get enterName => 'Please enter your name.';

  @override
  String get enterValidEmail => 'Please enter a valid email.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';

  @override
  String get chooseDob => 'Please choose your date of birth.';

  @override
  String get errorUnexpected => 'An unexpected error occurred.';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailTaken => 'An account with this email already exists.';

  @override
  String get errorWeakPassword =>
      'This password is too weak. Please choose a stronger one.';

  @override
  String get errorEmailNotConfirmed =>
      'Please confirm your email first, using the link we sent you.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorNetwork =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Sign in again, then retry.';

  @override
  String get errorAdminAccount =>
      'Admin accounts can\'t be deleted from the app. Contact another administrator.';

  @override
  String get errorDeleteFailed =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleting => 'Deleting…';

  @override
  String get keepMyAccount => 'Keep my account';

  @override
  String get cannotBeUndone => 'This cannot be undone';

  @override
  String get deleteAccountBody1 =>
      'Deleting your account removes your name, email, phone number and date of birth from the mosque\'s records, along with any document you shared with the marriage service.';

  @override
  String get deleteAccountBody2 =>
      'The app keeps working without an account: prayer times, events and announcements are all available signed out.';

  @override
  String get whatStays => 'What stays';

  @override
  String get remindersStay =>
      'Kept on this device; they are not tied to your account';

  @override
  String get attendanceRecorded => 'Attendance already recorded';

  @override
  String get attendanceStays => 'Kept as a count, without your name';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String typeWordToConfirm(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get mosqueServices => 'Mosque services';

  @override
  String get marriageService => 'Marriage service';

  @override
  String get marriageServiceRow => 'Confidential introductions';

  @override
  String get marriageEyebrow => 'MARRIAGE SERVICE';

  @override
  String get underReview => 'Under review';

  @override
  String submittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get marriageGateTitle => 'Confidential introductions';

  @override
  String get marriageGateSubtitle => 'A service of Pape Mosque';

  @override
  String get marriageGateBody =>
      'If you are looking to marry, you can share one document about yourself with the mosque\'s Imam. The Imam reads it in private and, if there is a suitable match, contacts you directly. Nothing is published and no one else sees it.';

  @override
  String get yourPrivacy => 'Your privacy';

  @override
  String get privacyOnlyImam => 'Only you and the Imam';

  @override
  String get privacyOnlyImamBody =>
      'Your document is never shown to other members';

  @override
  String get privacyNoProfiles => 'No profiles, no browsing';

  @override
  String get privacyNoProfilesBody =>
      'There is no listing or directory of applicants';

  @override
  String get privacyWithdraw => 'Withdraw at any time';

  @override
  String get privacyWithdrawBody =>
      'Your document is deleted when you withdraw';

  @override
  String get marriageAgeNote => 'Open to members aged 18 and over.';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get marriageGateCaption =>
      'An account lets the Imam reach you privately.';

  @override
  String get dobTitle => 'Your date of birth';

  @override
  String get dobSubtitle => 'Needed once, kept private';

  @override
  String get dobBody =>
      'The marriage service is open to members aged 18 and over. Your date of birth is saved to your account and cannot be changed afterwards, so please check it before you continue.';

  @override
  String get dobField => 'Date of birth';

  @override
  String get dobHint => 'Choose a date';

  @override
  String get dobContinue => 'Save and continue';

  @override
  String get saving => 'Saving…';

  @override
  String get dobSaveFailed =>
      'Couldn\'t save your date of birth. Please try again.';

  @override
  String get notEligibleTitle => 'Open to members aged 18 and over';

  @override
  String get notEligibleBody =>
      'The marriage service is only available to adult members. Your account and everything else in the app are unaffected.';

  @override
  String get uploadTitle => 'Share your document';

  @override
  String get uploadSubtitle => 'One file, read only by the Imam';

  @override
  String get chooseOneFile => 'Choose one file';

  @override
  String get fileRules => 'PDF, JPG or PNG · up to 4 MB';

  @override
  String get files => 'Files';

  @override
  String get photos => 'Photos';

  @override
  String get whatToInclude => 'What to include';

  @override
  String get whatToIncludeBody1 =>
      'There is no template. Write about yourself in your own words: your background, your family, your practice and what you are hoping for in a spouse. French, Turkish or English are all fine.';

  @override
  String get whatToIncludeBody2 =>
      'Only share what you are comfortable with. The Imam will ask you directly if anything more is needed.';

  @override
  String get privacyStrip =>
      'Private to you and the mosque\'s Imam. Never shown to other members.';

  @override
  String get submit => 'Submit';

  @override
  String get chooseFileToContinue => 'Choose a file to continue.';

  @override
  String get uploadingPrivately => 'Uploading privately…';

  @override
  String get uploading => 'Uploading…';

  @override
  String get keepAppOpen => 'Keep the app open until the upload finishes.';

  @override
  String get tooLarge => 'too large';

  @override
  String get tooLargeBody =>
      'Files must be under 4 MB. Try exporting the PDF at a smaller size, or choose a single photo instead of several.';

  @override
  String get unsupportedType => 'not supported';

  @override
  String get unsupportedTypeBody => 'Only PDF, JPG or PNG files can be shared.';

  @override
  String get unreadableFile => 'Couldn\'t read this file. Try another one.';

  @override
  String get cantBeRead => 'can\'t be read';

  @override
  String get preparingPrivately => 'Preparing privately…';

  @override
  String get detailsUnavailable =>
      'Couldn\'t load your account details. Please try again.';

  @override
  String get uploadFailed =>
      'The upload didn\'t finish. Check your connection and try again.';

  @override
  String get receivedTitle => 'Received, thank you';

  @override
  String get receivedBody =>
      'Your document is stored privately. Only you and the Imam can open it.';

  @override
  String get whatHappensNext => 'What happens next';

  @override
  String get nextImamReads => 'The Imam reads it';

  @override
  String get nextImamReadsBody => 'In private, when they are next available';

  @override
  String get nextContacted => 'You\'re contacted privately';

  @override
  String get nextContactedBody => 'Only if there is a suitable match';

  @override
  String get nextYouDecide => 'You decide';

  @override
  String get nextYouDecideBody => 'Nothing happens without your agreement';

  @override
  String get done => 'Done';

  @override
  String get yourApplication => 'Your application';

  @override
  String get underReviewBody =>
      'The Imam has your document and will contact you privately if there is a suitable match. There\'s nothing more you need to do.';

  @override
  String get yourDocument => 'Your document';

  @override
  String get view => 'View';

  @override
  String get replace => 'Replace';

  @override
  String get withdrawTitle => 'Withdraw my application';

  @override
  String get withdrawCaption =>
      'Deletes your document from the mosque\'s records';

  @override
  String get openFailed => 'Couldn\'t open your document. Please try again.';

  @override
  String get openingPrivately => 'Opening privately…';

  @override
  String get replaceSubtitle =>
      'Your current document stays until the new one is uploaded';

  @override
  String get applicationUnavailable =>
      'Couldn\'t load your application. Please try again.';

  @override
  String get withdrawSheetTitle => 'Withdraw your application?';

  @override
  String get withdrawSheetBody =>
      'Your document will be permanently deleted and the Imam will no longer see it. You can apply again at any time.';

  @override
  String get withdrawConfirm => 'Withdraw and delete';

  @override
  String get withdrawing => 'Deleting…';

  @override
  String get withdrawKeep => 'Keep my application';

  @override
  String get withdrawFailed =>
      'Couldn\'t withdraw your application. Please try again.';

  @override
  String get withdrawn => 'Your application has been withdrawn.';

  @override
  String get theMosque => 'THE MOSQUE';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get dailyPrayers => 'Daily prayers';

  @override
  String get dailyPrayersBody => 'Open for every prayer, Fajr through Isha';

  @override
  String get jumuah => 'Jumu\'ah';

  @override
  String get fridays => 'Fridays';

  @override
  String get office => 'Office';

  @override
  String get callForHours => 'Call for current hours';

  @override
  String get getInTouch => 'Get in touch';

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }
}
