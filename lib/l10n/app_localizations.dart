import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pape Mosque'**
  String get appTitle;

  /// No description provided for @tabPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get tabPrayer;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// A prayer time as the timetable names it. [prayer] is the lower-case English key.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{Fajr} sunrise{Sunrise} dhuhr{Dhuhr} asr{Asr} maghrib{Maghrib} isha{Isha} other{{prayer}}}'**
  String prayer(String prayer);

  /// The prayer itself (the salah), as a reminder title. Turkish uses the namaz form: İmsak is a time, the prayer is the sabah namazı.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{Fajr} sunrise{Sunrise} dhuhr{Dhuhr} asr{Asr} maghrib{Maghrib} isha{Isha} other{{prayer}}}'**
  String prayerSalah(String prayer);

  /// Start of an event card's when line.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{After Fajr} sunrise{After sunrise} dhuhr{After Dhuhr} asr{After Asr} maghrib{After Maghrib} isha{After Isha} other{After {prayer}}}'**
  String afterPrayer(String prayer);

  /// Mid-line, after the cadence: 'Every Friday · after Maghrib'.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{after Fajr} sunrise{after sunrise} dhuhr{after Dhuhr} asr{after Asr} maghrib{after Maghrib} isha{after Isha} other{after {prayer}}}'**
  String afterPrayerInline(String prayer);

  /// Event detail row title.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{After Fajr prayer} sunrise{After sunrise} dhuhr{After Dhuhr prayer} asr{After Asr prayer} maghrib{After Maghrib prayer} isha{After Isha prayer} other{After {prayer} prayer}}'**
  String afterPrayerTitle(String prayer);

  /// Header of the Prayer home, next to the logo. Same name in English and French.
  ///
  /// In en, this message translates to:
  /// **'Canadian Turkish Islamic Trust'**
  String get organisationName;

  /// No description provided for @homeMosqueLine.
  ///
  /// In en, this message translates to:
  /// **'Pape Mosque · Toronto'**
  String get homeMosqueLine;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'NEXT PRAYER'**
  String get nextPrayer;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'Toronto'**
  String get city;

  /// No description provided for @todayAtTheMosque.
  ///
  /// In en, this message translates to:
  /// **'Today at the mosque'**
  String get todayAtTheMosque;

  /// Prayer home section with the next event and the latest announcement.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get homeCommunitySection;

  /// Link from the Prayer home's Community section to the Community tab.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @athanIqamah.
  ///
  /// In en, this message translates to:
  /// **'Athan · Iqamah'**
  String get athanIqamah;

  /// No description provided for @iqamah.
  ///
  /// In en, this message translates to:
  /// **'IQAMAH'**
  String get iqamah;

  /// No description provided for @athanAt.
  ///
  /// In en, this message translates to:
  /// **'Athan {time}'**
  String athanAt(String time);

  /// No description provided for @iqamahAt.
  ///
  /// In en, this message translates to:
  /// **'Iqamah {time}'**
  String iqamahAt(String time);

  /// No description provided for @prayerNow.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · now'**
  String prayerNow(String prayer);

  /// No description provided for @fajrWindowCloses.
  ///
  /// In en, this message translates to:
  /// **'Fajr window closes'**
  String get fajrWindowCloses;

  /// No description provided for @prayerReminders.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders'**
  String get prayerReminders;

  /// No description provided for @prayerRemindersDetail.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before each iqamah'**
  String get prayerRemindersDetail;

  /// No description provided for @remindersDeniedNote.
  ///
  /// In en, this message translates to:
  /// **'Notifications for Pape Mosque are turned off in iOS Settings, so reminders can\'t appear.'**
  String get remindersDeniedNote;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Notification body, 5 minutes before the iqamah.
  ///
  /// In en, this message translates to:
  /// **'Iqamah in 5 minutes'**
  String get reminderBody;

  /// No description provided for @timesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Times unavailable'**
  String get timesUnavailable;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @timesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s times aren\'t available'**
  String get timesUnavailableTitle;

  /// No description provided for @timesUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The mosque calendar could not be reached. Reminders already scheduled on this device still run.'**
  String get timesUnavailableBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @jumuahEveryFriday.
  ///
  /// In en, this message translates to:
  /// **'Every Friday at the mosque'**
  String get jumuahEveryFriday;

  /// No description provided for @everyFriday.
  ///
  /// In en, this message translates to:
  /// **'Every Friday'**
  String get everyFriday;

  /// No description provided for @salahAt.
  ///
  /// In en, this message translates to:
  /// **'Salah {time}'**
  String salahAt(String time);

  /// No description provided for @eidFitr.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get eidFitr;

  /// No description provided for @eidAdha.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get eidAdha;

  /// No description provided for @eidTimes.
  ///
  /// In en, this message translates to:
  /// **'Salah {first} · Second jamaah {second}'**
  String eidTimes(String first, String second);

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callOffice.
  ///
  /// In en, this message translates to:
  /// **'Call office'**
  String get callOffice;

  /// No description provided for @hijriMonth1.
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get hijriMonth1;

  /// No description provided for @hijriMonth2.
  ///
  /// In en, this message translates to:
  /// **'Safar'**
  String get hijriMonth2;

  /// No description provided for @hijriMonth3.
  ///
  /// In en, this message translates to:
  /// **'Rabi\' al-Awwal'**
  String get hijriMonth3;

  /// No description provided for @hijriMonth4.
  ///
  /// In en, this message translates to:
  /// **'Rabi\' al-Thani'**
  String get hijriMonth4;

  /// No description provided for @hijriMonth5.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Awwal'**
  String get hijriMonth5;

  /// No description provided for @hijriMonth6.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Thani'**
  String get hijriMonth6;

  /// No description provided for @hijriMonth7.
  ///
  /// In en, this message translates to:
  /// **'Rajab'**
  String get hijriMonth7;

  /// No description provided for @hijriMonth8.
  ///
  /// In en, this message translates to:
  /// **'Sha\'ban'**
  String get hijriMonth8;

  /// No description provided for @hijriMonth9.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get hijriMonth9;

  /// No description provided for @hijriMonth10.
  ///
  /// In en, this message translates to:
  /// **'Shawwal'**
  String get hijriMonth10;

  /// No description provided for @hijriMonth11.
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Qi\'dah'**
  String get hijriMonth11;

  /// No description provided for @hijriMonth12.
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Hijjah'**
  String get hijriMonth12;

  /// intl pattern: 'Wednesday, 23 September'.
  ///
  /// In en, this message translates to:
  /// **'EEEE, d MMMM'**
  String get datePatternTitle;

  /// intl pattern: 'Saturday 26 September'.
  ///
  /// In en, this message translates to:
  /// **'EEEE d MMMM'**
  String get datePatternLong;

  /// intl pattern: 'Wed 30 Sep'. Turkish spells both out: abbreviations like 'Eki Cum' read badly.
  ///
  /// In en, this message translates to:
  /// **'EEE d MMM'**
  String get datePatternShort;

  /// intl pattern: '30 September'.
  ///
  /// In en, this message translates to:
  /// **'d MMMM'**
  String get datePatternDayMonth;

  /// intl pattern: 'March 2024'.
  ///
  /// In en, this message translates to:
  /// **'MMMM y'**
  String get datePatternMonthYear;

  /// intl pattern for the event card: 'MAY 8'.
  ///
  /// In en, this message translates to:
  /// **'MMM d'**
  String get datePatternCard;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String weeksAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String monthsAgo(int count);

  /// [ago] is e.g. '3 hours ago'.
  ///
  /// In en, this message translates to:
  /// **'Posted {ago}'**
  String postedAgo(String ago);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Badge: days until the next session.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String inDays(int count);

  /// No description provided for @repeatsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Repeats weekly'**
  String get repeatsWeekly;

  /// No description provided for @repeatsBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Repeats every 2 weeks'**
  String get repeatsBiweekly;

  /// No description provided for @repeatsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Repeats monthly'**
  String get repeatsMonthly;

  /// [weekday] is mon…sun.
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, mon{Every Monday} tue{Every Tuesday} wed{Every Wednesday} thu{Every Thursday} fri{Every Friday} sat{Every Saturday} sun{Every Sunday} other{Every Monday}}'**
  String everyWeekday(String weekday);

  /// [weekday] is mon…sun.
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, mon{Every other Monday} tue{Every other Tuesday} wed{Every other Wednesday} thu{Every other Thursday} fri{Every other Friday} sat{Every other Saturday} sun{Every other Sunday} other{Every other Monday}}'**
  String everyOtherWeekday(String weekday);

  /// No description provided for @everyTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get everyTwoWeeks;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// [day] is the ordinal from Dart: '5th' (en), '5' or '1er' (fr), '5' (tr).
  ///
  /// In en, this message translates to:
  /// **'Every month on the {day}'**
  String everyMonthOnDay(String day);

  /// No description provided for @weeklyProgrammeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY PROGRAMME'**
  String get weeklyProgrammeEyebrow;

  /// No description provided for @biweeklyProgrammeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'BIWEEKLY PROGRAMME'**
  String get biweeklyProgrammeEyebrow;

  /// No description provided for @monthlyProgrammeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY PROGRAMME'**
  String get monthlyProgrammeEyebrow;

  /// No description provided for @eventEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EVENT'**
  String get eventEyebrow;

  /// No description provided for @weeklyProgramme.
  ///
  /// In en, this message translates to:
  /// **'Weekly programme'**
  String get weeklyProgramme;

  /// No description provided for @biweeklyProgramme.
  ///
  /// In en, this message translates to:
  /// **'Programme every 2 weeks'**
  String get biweeklyProgramme;

  /// No description provided for @monthlyProgramme.
  ///
  /// In en, this message translates to:
  /// **'Monthly programme'**
  String get monthlyProgramme;

  /// No description provided for @nextOn.
  ///
  /// In en, this message translates to:
  /// **'next: {date}'**
  String nextOn(String date);

  /// No description provided for @aboutTime.
  ///
  /// In en, this message translates to:
  /// **'about {time}'**
  String aboutTime(String time);

  /// No description provided for @beginsAboutOn.
  ///
  /// In en, this message translates to:
  /// **'{begins} — about {time} on {date}'**
  String beginsAboutOn(String begins, String time, String date);

  /// No description provided for @registerAt.
  ///
  /// In en, this message translates to:
  /// **'Register: {url}'**
  String registerAt(String url);

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @noEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled'**
  String get noEventsTitle;

  /// No description provided for @noEventsBody.
  ///
  /// In en, this message translates to:
  /// **'When the mosque publishes an event it will appear here. Jumu\'ah runs every Friday as usual.'**
  String get noEventsBody;

  /// No description provided for @noAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'No announcements'**
  String get noAnnouncementsTitle;

  /// No description provided for @noAnnouncementsBody.
  ///
  /// In en, this message translates to:
  /// **'Notices from the mosque office will appear here.'**
  String get noAnnouncementsBody;

  /// No description provided for @notifyMe.
  ///
  /// In en, this message translates to:
  /// **'Tell me when something is posted'**
  String get notifyMe;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @announcementEyebrow.
  ///
  /// In en, this message translates to:
  /// **'ANNOUNCEMENT'**
  String get announcementEyebrow;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerFree.
  ///
  /// In en, this message translates to:
  /// **'Register · free'**
  String get registerFree;

  /// No description provided for @aboutThisEvent.
  ///
  /// In en, this message translates to:
  /// **'About this event'**
  String get aboutThisEvent;

  /// No description provided for @shareThisEvent.
  ///
  /// In en, this message translates to:
  /// **'Share this event'**
  String get shareThisEvent;

  /// No description provided for @shareThisAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Share this announcement'**
  String get shareThisAnnouncement;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions?'**
  String get questions;

  /// No description provided for @callTheOffice.
  ///
  /// In en, this message translates to:
  /// **'Call the mosque office'**
  String get callTheOffice;

  /// No description provided for @mosqueOffice.
  ///
  /// In en, this message translates to:
  /// **'Mosque office'**
  String get mosqueOffice;

  /// No description provided for @everyoneWelcome.
  ///
  /// In en, this message translates to:
  /// **'Everyone is welcome'**
  String get everyoneWelcome;

  /// No description provided for @freeToAttend.
  ///
  /// In en, this message translates to:
  /// **'Free to attend'**
  String get freeToAttend;

  /// No description provided for @ticketed.
  ///
  /// In en, this message translates to:
  /// **'Ticketed'**
  String get ticketed;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @dropIn.
  ///
  /// In en, this message translates to:
  /// **'Drop in — no registration needed'**
  String get dropIn;

  /// No description provided for @nextSession.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get nextSession;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @beginsAfterJamaah.
  ///
  /// In en, this message translates to:
  /// **'Begins once the jama\'ah finishes'**
  String get beginsAfterJamaah;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re not signed in'**
  String get notSignedIn;

  /// No description provided for @notSignedInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to register for events and keep your reminders across devices.'**
  String get notSignedInBody;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders, language, account'**
  String get settingsRowSubtitle;

  /// No description provided for @yourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get yourDetails;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountEyebrow.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountEyebrow;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @notSignedInShort.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedInShort;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @deviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get deviceLanguage;

  /// No description provided for @deviceLanguageDetail.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone\'s setting'**
  String get deviceLanguageDetail;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// No description provided for @mosqueAndContact.
  ///
  /// In en, this message translates to:
  /// **'Mosque & contact'**
  String get mosqueAndContact;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutThisApp;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @worksWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Prayer times, events and announcements work without an account.'**
  String get worksWithoutAccount;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to register for events'**
  String get signInSubtitle;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'New to Pape Mosque?'**
  String get noAccountYet;

  /// No description provided for @accountOptional.
  ///
  /// In en, this message translates to:
  /// **'An account is optional. Prayer times, events and announcements work without one.'**
  String get accountOptional;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'So the office knows who\'s coming'**
  String get signUpSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @detailsSharedOnlyWithOffice.
  ///
  /// In en, this message translates to:
  /// **'Your details are shared only with the mosque office.'**
  String get detailsSharedOnlyWithOffice;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get enterName;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get enterValidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @chooseDob.
  ///
  /// In en, this message translates to:
  /// **'Please choose your date of birth.'**
  String get chooseDob;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnexpected;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailTaken;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password is too weak. Please choose a stronger one.'**
  String get errorWeakPassword;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email first, using the link we sent you.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again, then retry.'**
  String get errorSessionExpired;

  /// No description provided for @errorAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts can\'t be deleted from the app. Contact another administrator.'**
  String get errorAdminAccount;

  /// No description provided for @errorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Please try again.'**
  String get errorDeleteFailed;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleting;

  /// No description provided for @keepMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get keepMyAccount;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone'**
  String get cannotBeUndone;

  /// Shown to everyone, whether or not they applied, so it never reveals who used the marriage service.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account removes your name, email, phone number and date of birth from the mosque\'s records, along with any document you shared with the marriage service.'**
  String get deleteAccountBody1;

  /// No description provided for @deleteAccountBody2.
  ///
  /// In en, this message translates to:
  /// **'The app keeps working without an account: prayer times, events and announcements are all available signed out.'**
  String get deleteAccountBody2;

  /// No description provided for @whatStays.
  ///
  /// In en, this message translates to:
  /// **'What stays'**
  String get whatStays;

  /// No description provided for @remindersStay.
  ///
  /// In en, this message translates to:
  /// **'Kept on this device; they are not tied to your account'**
  String get remindersStay;

  /// No description provided for @attendanceRecorded.
  ///
  /// In en, this message translates to:
  /// **'Attendance already recorded'**
  String get attendanceRecorded;

  /// No description provided for @attendanceStays.
  ///
  /// In en, this message translates to:
  /// **'Kept as a count, without your name'**
  String get attendanceStays;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// The word the member types to confirm deletion.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirmWord;

  /// No description provided for @typeWordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String typeWordToConfirm(String word);

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @mosqueServices.
  ///
  /// In en, this message translates to:
  /// **'Mosque services'**
  String get mosqueServices;

  /// No description provided for @marriageService.
  ///
  /// In en, this message translates to:
  /// **'Marriage service'**
  String get marriageService;

  /// No description provided for @marriageServiceRow.
  ///
  /// In en, this message translates to:
  /// **'Confidential introductions'**
  String get marriageServiceRow;

  /// No description provided for @marriageEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MARRIAGE SERVICE'**
  String get marriageEyebrow;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get underReview;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String submittedOn(String date);

  /// No description provided for @marriageGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Confidential introductions'**
  String get marriageGateTitle;

  /// No description provided for @marriageGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A service of Pape Mosque'**
  String get marriageGateSubtitle;

  /// No description provided for @marriageGateBody.
  ///
  /// In en, this message translates to:
  /// **'If you are looking to marry, you can share one document about yourself with the mosque\'s Imam. The Imam reads it in private and, if there is a suitable match, contacts you directly. Nothing is published and no one else sees it.'**
  String get marriageGateBody;

  /// No description provided for @yourPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get yourPrivacy;

  /// No description provided for @privacyOnlyImam.
  ///
  /// In en, this message translates to:
  /// **'Only you and the Imam'**
  String get privacyOnlyImam;

  /// No description provided for @privacyOnlyImamBody.
  ///
  /// In en, this message translates to:
  /// **'Your document is never shown to other members'**
  String get privacyOnlyImamBody;

  /// No description provided for @privacyNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'No profiles, no browsing'**
  String get privacyNoProfiles;

  /// No description provided for @privacyNoProfilesBody.
  ///
  /// In en, this message translates to:
  /// **'There is no listing or directory of applicants'**
  String get privacyNoProfilesBody;

  /// No description provided for @privacyWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw at any time'**
  String get privacyWithdraw;

  /// No description provided for @privacyWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'Your document is deleted when you withdraw'**
  String get privacyWithdrawBody;

  /// No description provided for @marriageAgeNote.
  ///
  /// In en, this message translates to:
  /// **'Open to members aged 18 and over.'**
  String get marriageAgeNote;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @marriageGateCaption.
  ///
  /// In en, this message translates to:
  /// **'An account lets the Imam reach you privately.'**
  String get marriageGateCaption;

  /// No description provided for @dobTitle.
  ///
  /// In en, this message translates to:
  /// **'Your date of birth'**
  String get dobTitle;

  /// No description provided for @dobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Needed once, kept private'**
  String get dobSubtitle;

  /// No description provided for @dobBody.
  ///
  /// In en, this message translates to:
  /// **'The marriage service is open to members aged 18 and over. Your date of birth is saved to your account and cannot be changed afterwards, so please check it before you continue.'**
  String get dobBody;

  /// No description provided for @dobField.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dobField;

  /// No description provided for @dobHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get dobHint;

  /// No description provided for @dobContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get dobContinue;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @dobSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your date of birth. Please try again.'**
  String get dobSaveFailed;

  /// No description provided for @notEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Open to members aged 18 and over'**
  String get notEligibleTitle;

  /// No description provided for @notEligibleBody.
  ///
  /// In en, this message translates to:
  /// **'The marriage service is only available to adult members. Your account and everything else in the app are unaffected.'**
  String get notEligibleBody;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your document'**
  String get uploadTitle;

  /// No description provided for @uploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One file, read only by the Imam'**
  String get uploadSubtitle;

  /// No description provided for @chooseOneFile.
  ///
  /// In en, this message translates to:
  /// **'Choose one file'**
  String get chooseOneFile;

  /// No description provided for @fileRules.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG or PNG · up to 4 MB'**
  String get fileRules;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @whatToInclude.
  ///
  /// In en, this message translates to:
  /// **'What to include'**
  String get whatToInclude;

  /// No description provided for @whatToIncludeBody1.
  ///
  /// In en, this message translates to:
  /// **'There is no template. Write about yourself in your own words: your background, your family, your practice and what you are hoping for in a spouse. French, Turkish or English are all fine.'**
  String get whatToIncludeBody1;

  /// No description provided for @whatToIncludeBody2.
  ///
  /// In en, this message translates to:
  /// **'Only share what you are comfortable with. The Imam will ask you directly if anything more is needed.'**
  String get whatToIncludeBody2;

  /// No description provided for @privacyStrip.
  ///
  /// In en, this message translates to:
  /// **'Private to you and the mosque\'s Imam. Never shown to other members.'**
  String get privacyStrip;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @chooseFileToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose a file to continue.'**
  String get chooseFileToContinue;

  /// No description provided for @uploadingPrivately.
  ///
  /// In en, this message translates to:
  /// **'Uploading privately…'**
  String get uploadingPrivately;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @keepAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open until the upload finishes.'**
  String get keepAppOpen;

  /// No description provided for @tooLarge.
  ///
  /// In en, this message translates to:
  /// **'too large'**
  String get tooLarge;

  /// No description provided for @tooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'Files must be under 4 MB. Try exporting the PDF at a smaller size, or choose a single photo instead of several.'**
  String get tooLargeBody;

  /// No description provided for @unsupportedType.
  ///
  /// In en, this message translates to:
  /// **'not supported'**
  String get unsupportedType;

  /// No description provided for @unsupportedTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Only PDF, JPG or PNG files can be shared.'**
  String get unsupportedTypeBody;

  /// No description provided for @unreadableFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file. Try another one.'**
  String get unreadableFile;

  /// No description provided for @cantBeRead.
  ///
  /// In en, this message translates to:
  /// **'can\'t be read'**
  String get cantBeRead;

  /// No description provided for @preparingPrivately.
  ///
  /// In en, this message translates to:
  /// **'Preparing privately…'**
  String get preparingPrivately;

  /// No description provided for @detailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your account details. Please try again.'**
  String get detailsUnavailable;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The upload didn\'t finish. Check your connection and try again.'**
  String get uploadFailed;

  /// No description provided for @receivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Received, thank you'**
  String get receivedTitle;

  /// No description provided for @receivedBody.
  ///
  /// In en, this message translates to:
  /// **'Your document is stored privately. Only you and the Imam can open it.'**
  String get receivedBody;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNext;

  /// No description provided for @nextImamReads.
  ///
  /// In en, this message translates to:
  /// **'The Imam reads it'**
  String get nextImamReads;

  /// No description provided for @nextImamReadsBody.
  ///
  /// In en, this message translates to:
  /// **'In private, when they are next available'**
  String get nextImamReadsBody;

  /// No description provided for @nextContacted.
  ///
  /// In en, this message translates to:
  /// **'You\'re contacted privately'**
  String get nextContacted;

  /// No description provided for @nextContactedBody.
  ///
  /// In en, this message translates to:
  /// **'Only if there is a suitable match'**
  String get nextContactedBody;

  /// No description provided for @nextYouDecide.
  ///
  /// In en, this message translates to:
  /// **'You decide'**
  String get nextYouDecide;

  /// No description provided for @nextYouDecideBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing happens without your agreement'**
  String get nextYouDecideBody;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yourApplication.
  ///
  /// In en, this message translates to:
  /// **'Your application'**
  String get yourApplication;

  /// No description provided for @underReviewBody.
  ///
  /// In en, this message translates to:
  /// **'The Imam has your document and will contact you privately if there is a suitable match. There\'s nothing more you need to do.'**
  String get underReviewBody;

  /// No description provided for @yourDocument.
  ///
  /// In en, this message translates to:
  /// **'Your document'**
  String get yourDocument;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw my application'**
  String get withdrawTitle;

  /// No description provided for @withdrawCaption.
  ///
  /// In en, this message translates to:
  /// **'Deletes your document from the mosque\'s records'**
  String get withdrawCaption;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your document. Please try again.'**
  String get openFailed;

  /// No description provided for @openingPrivately.
  ///
  /// In en, this message translates to:
  /// **'Opening privately…'**
  String get openingPrivately;

  /// No description provided for @replaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your current document stays until the new one is uploaded'**
  String get replaceSubtitle;

  /// No description provided for @applicationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your application. Please try again.'**
  String get applicationUnavailable;

  /// No description provided for @withdrawSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your application?'**
  String get withdrawSheetTitle;

  /// No description provided for @withdrawSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Your document will be permanently deleted and the Imam will no longer see it. You can apply again at any time.'**
  String get withdrawSheetBody;

  /// No description provided for @withdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Withdraw and delete'**
  String get withdrawConfirm;

  /// No description provided for @withdrawing.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get withdrawing;

  /// No description provided for @withdrawKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my application'**
  String get withdrawKeep;

  /// No description provided for @withdrawFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t withdraw your application. Please try again.'**
  String get withdrawFailed;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Your application has been withdrawn.'**
  String get withdrawn;

  /// No description provided for @theMosque.
  ///
  /// In en, this message translates to:
  /// **'THE MOSQUE'**
  String get theMosque;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHours;

  /// No description provided for @dailyPrayers.
  ///
  /// In en, this message translates to:
  /// **'Daily prayers'**
  String get dailyPrayers;

  /// No description provided for @dailyPrayersBody.
  ///
  /// In en, this message translates to:
  /// **'Open for every prayer, Fajr through Isha'**
  String get dailyPrayersBody;

  /// No description provided for @jumuah.
  ///
  /// In en, this message translates to:
  /// **'Jumu\'ah'**
  String get jumuah;

  /// No description provided for @fridays.
  ///
  /// In en, this message translates to:
  /// **'Fridays'**
  String get fridays;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @callForHours.
  ///
  /// In en, this message translates to:
  /// **'Call for current hours'**
  String get callForHours;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get getInTouch;

  /// No description provided for @sizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMegabytes(String size);

  /// No description provided for @sizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String sizeKilobytes(String size);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
