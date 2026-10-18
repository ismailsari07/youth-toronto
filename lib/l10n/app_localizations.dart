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

  /// No description provided for @prayerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Prayer notifications'**
  String get prayerNotifications;

  /// No description provided for @remindersPrayers.
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get remindersPrayers;

  /// No description provided for @remindersNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get remindersNotifyMe;

  /// No description provided for @notifyAtAthan.
  ///
  /// In en, this message translates to:
  /// **'At athan time'**
  String get notifyAtAthan;

  /// No description provided for @notifyBeforeIqamah.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before iqamah'**
  String get notifyBeforeIqamah;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSound;

  /// Sound choice. Only shown once an athan recording is bundled with the app.
  ///
  /// In en, this message translates to:
  /// **'Athan'**
  String get soundAthan;

  /// No description provided for @soundStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard notification sound'**
  String get soundStandard;

  /// No description provided for @soundSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get soundSilent;

  /// No description provided for @playSound.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playSound;

  /// No description provided for @stopSound.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopSound;

  /// No description provided for @remindersSummaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get remindersSummaryOff;

  /// No description provided for @remindersSummaryAthan.
  ///
  /// In en, this message translates to:
  /// **'On · At athan time'**
  String get remindersSummaryAthan;

  /// No description provided for @remindersSummaryIqamah.
  ///
  /// In en, this message translates to:
  /// **'On · 5 min before iqamah'**
  String get remindersSummaryIqamah;

  /// Body of the notification at athan time. [prayer] is the lower-case English key. Turkish uses the namaz form (Fajr: Sabah namazı).
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{It\'s time for Fajr prayer} dhuhr{It\'s time for Dhuhr prayer} asr{It\'s time for Asr prayer} maghrib{It\'s time for Maghrib prayer} isha{It\'s time for Isha prayer} other{It\'s time for {prayer} prayer}}'**
  String reminderAthanBody(String prayer);

  /// Appended to the athan-time body after ' · '. [time] is 12-hour in every language, e.g. 1:45 PM.
  ///
  /// In en, this message translates to:
  /// **'Iqamah at {time}'**
  String reminderIqamahAt(String time);

  /// Body of the notification 5 minutes before the iqamah. [prayer] is the lower-case English key.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{Fajr iqamah in 5 minutes} dhuhr{Dhuhr iqamah in 5 minutes} asr{Asr iqamah in 5 minutes} maghrib{Maghrib iqamah in 5 minutes} isha{Isha iqamah in 5 minutes} other{{prayer} iqamah in 5 minutes}}'**
  String reminderIqamahSoon(String prayer);

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

  /// No description provided for @timesUnavailableShortBody.
  ///
  /// In en, this message translates to:
  /// **'The mosque calendar could not be reached.'**
  String get timesUnavailableShortBody;

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

  /// Last line of a shared event, under its details.
  ///
  /// In en, this message translates to:
  /// **'Shared from the Pape Mosque app · {website}'**
  String sharedFromApp(String website);

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

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// No description provided for @appearanceSystemDetail.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone\'s setting'**
  String get appearanceSystemDetail;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

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

  /// Blocking screen when the app is older than the panel's minimum supported version.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of the app is no longer supported. Update to the latest version to keep using it.'**
  String get updateRequiredBody;

  /// No description provided for @openAppStore.
  ///
  /// In en, this message translates to:
  /// **'Open the App Store'**
  String get openAppStore;

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

  /// No description provided for @burialServices.
  ///
  /// In en, this message translates to:
  /// **'Burial services'**
  String get burialServices;

  /// No description provided for @burialEyebrow.
  ///
  /// In en, this message translates to:
  /// **'MOSQUE SERVICES'**
  String get burialEyebrow;

  /// No description provided for @burialCemetery.
  ///
  /// In en, this message translates to:
  /// **'Cemetery'**
  String get burialCemetery;

  /// No description provided for @burialContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get burialContacts;

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

  /// No description provided for @jumuah.
  ///
  /// In en, this message translates to:
  /// **'Jumu\'ah'**
  String get jumuah;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get getInTouch;

  /// Mosque & Contact: the website, donation and social links from the panel.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get linksSection;

  /// No description provided for @donation.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donation;

  /// Grey note under the Donate sheet title (Prayer Donate pill, Profile Donate row).
  ///
  /// In en, this message translates to:
  /// **'Opens our website in Safari'**
  String get donateSheetNote;

  /// Last row of the Donate sheet: opens the website's donation page without a fund.
  ///
  /// In en, this message translates to:
  /// **'All donation options'**
  String get allDonationOptions;

  /// Subtitle of the Donate row in Profile > Mosque services.
  ///
  /// In en, this message translates to:
  /// **'Give through our website'**
  String get donateRowSubtitle;

  /// Label of the Donate pill in the Prayer hero (heart + label). Must fit next to the organisation name on an iPhone SE; VoiceOver reads `donation` instead.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donatePill;

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

  /// No description provided for @pushPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushPromptTitle;

  /// No description provided for @pushPromptReason.
  ///
  /// In en, this message translates to:
  /// **'Hear about events and important news from the mosque.'**
  String get pushPromptReason;

  /// No description provided for @pushPromptAllow.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushPromptAllow;

  /// No description provided for @pushPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pushPromptLater;

  /// No description provided for @pushEvents.
  ///
  /// In en, this message translates to:
  /// **'Event notifications'**
  String get pushEvents;

  /// No description provided for @pushEventsDetail.
  ///
  /// In en, this message translates to:
  /// **'Reminders for upcoming events'**
  String get pushEventsDetail;

  /// No description provided for @pushAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements and important news'**
  String get pushAnnouncements;

  /// No description provided for @pushAnnouncementsDetail.
  ///
  /// In en, this message translates to:
  /// **'Includes urgent mosque notices'**
  String get pushAnnouncementsDetail;

  /// No description provided for @pushDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in iPhone Settings'**
  String get pushDenied;

  /// No description provided for @pushDeniedDetail.
  ///
  /// In en, this message translates to:
  /// **'To turn them on, go to Pape Mosque in Settings.'**
  String get pushDeniedDetail;

  /// No description provided for @pushOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get pushOpenSettings;

  /// No description provided for @eventNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify me about this event'**
  String get eventNotify;

  /// No description provided for @eventNotifyOn.
  ///
  /// In en, this message translates to:
  /// **'A reminder before it starts'**
  String get eventNotifyOn;

  /// No description provided for @eventNotifyOff.
  ///
  /// In en, this message translates to:
  /// **'Off for this event'**
  String get eventNotifyOff;

  /// No description provided for @eventNotifyEventsOff.
  ///
  /// In en, this message translates to:
  /// **'Event notifications are off'**
  String get eventNotifyEventsOff;

  /// No description provided for @eventGone.
  ///
  /// In en, this message translates to:
  /// **'This event is no longer available'**
  String get eventGone;

  /// No description provided for @announcementGone.
  ///
  /// In en, this message translates to:
  /// **'This announcement is no longer available'**
  String get announcementGone;

  /// No description provided for @goneBody.
  ///
  /// In en, this message translates to:
  /// **'It may have ended or been removed.'**
  String get goneBody;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @deviceCode.
  ///
  /// In en, this message translates to:
  /// **'Device code'**
  String get deviceCode;

  /// No description provided for @deviceCodeNote.
  ///
  /// In en, this message translates to:
  /// **'Share this code if support asks for it.'**
  String get deviceCodeNote;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @saveFailedLater.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again in a little while.'**
  String get saveFailedLater;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @errorProviderFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in couldn\'t be completed. Please try again.'**
  String get errorProviderFailed;

  /// No description provided for @errorAppleMismatch.
  ///
  /// In en, this message translates to:
  /// **'Confirm with the Apple ID you use for this account.'**
  String get errorAppleMismatch;

  /// No description provided for @addName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get addName;

  /// No description provided for @addNameBody.
  ///
  /// In en, this message translates to:
  /// **'Shown on your profile. You can set it once; to change it later, contact the mosque office.'**
  String get addNameBody;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveName;

  /// No description provided for @errorAppleRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple couldn\'t confirm the deletion, so your account wasn\'t deleted. Please try again in a few minutes.'**
  String get errorAppleRevokeFailed;

  /// Badge on an event card whose event takes registrations in the app.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get regBadge;

  /// Event page: registration card title while open.
  ///
  /// In en, this message translates to:
  /// **'Registration open'**
  String get regOpen;

  /// Event page button when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to register'**
  String get regSignInToRegister;

  /// Under the signed-out button.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to register.'**
  String get regSignInNote;

  /// Badge when 5 or fewer places remain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last place} other{Last {count} places}}'**
  String regPlacesLeft(int count);

  /// Under the registration card; only from 25 views.
  ///
  /// In en, this message translates to:
  /// **'{count} people viewed'**
  String regViews(int count);

  /// Registration state and disabled button: no places left.
  ///
  /// In en, this message translates to:
  /// **'Registration is full'**
  String get regFull;

  /// Registration state and disabled button: deadline passed.
  ///
  /// In en, this message translates to:
  /// **'Registration has ended'**
  String get regDeadlinePassed;

  /// Under 'Registration has ended'. {when} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'Registration closed on {when}'**
  String regDeadlineWas(String when);

  /// Under 'Registration open'. {when} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'Register by {when}'**
  String regDeadlineIs(String when);

  /// Registration state and disabled button: closed by the mosque.
  ///
  /// In en, this message translates to:
  /// **'Registration is closed'**
  String get regClosed;

  /// Event page when the event has no form any more.
  ///
  /// In en, this message translates to:
  /// **'This event no longer takes registrations.'**
  String get regNotAccepting;

  /// An admin account without a member profile.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t register for events.'**
  String get regNoProfile;

  /// Event page when the registration state didn't load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load registration details.'**
  String get regStateFailed;

  /// Event page once registered.
  ///
  /// In en, this message translates to:
  /// **'You\'re registered'**
  String get regRegistered;

  /// Under 'You're registered'. {when} is a date.
  ///
  /// In en, this message translates to:
  /// **'Registered on {when}'**
  String regRegisteredOn(String when);

  /// Section title: the member's own registration.
  ///
  /// In en, this message translates to:
  /// **'What you sent'**
  String get regSubmitted;

  /// Event notification row, locked on.
  ///
  /// In en, this message translates to:
  /// **'On because you\'re registered'**
  String get regNotifyLocked;

  /// Recurring event: what the registration is for.
  ///
  /// In en, this message translates to:
  /// **'This registration covers the whole programme.'**
  String get regRecurringNote;

  /// Eyebrow of the registration screen.
  ///
  /// In en, this message translates to:
  /// **'REGISTRATION'**
  String get regEyebrow;

  /// Registration screen: name, email, phone.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get regYourDetails;

  /// Registration screen: the event's questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get regQuestions;

  /// Registration screen field.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get regFullName;

  /// Registration screen field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get regEmail;

  /// Registration screen field.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get regPhone;

  /// Under the phone field when the profile has none.
  ///
  /// In en, this message translates to:
  /// **'Saved to your profile'**
  String get regSavedToProfile;

  /// Registration screen button.
  ///
  /// In en, this message translates to:
  /// **'Send registration'**
  String get regSubmit;

  /// Under the send button.
  ///
  /// In en, this message translates to:
  /// **'A registration can\'t be cancelled in the app.'**
  String get regNoCancel;

  /// Banner when sending failed for lack of a connection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Registering needs one.'**
  String get regOffline;

  /// Banner after form_changed.
  ///
  /// In en, this message translates to:
  /// **'The form was updated. Check it and send again.'**
  String get regFormChanged;

  /// Banner when fields have errors.
  ///
  /// In en, this message translates to:
  /// **'Check the fields below.'**
  String get regFixBelow;

  /// Banner when the server refused the answers as a whole.
  ///
  /// In en, this message translates to:
  /// **'Your answers couldn\'t be sent. Update the app and try again.'**
  String get regAnswersRejected;

  /// A question type this version can't show.
  ///
  /// In en, this message translates to:
  /// **'Update the app to answer this question.'**
  String get regUpdateApp;

  /// Snack bar after registering.
  ///
  /// In en, this message translates to:
  /// **'You\'re registered'**
  String get regDone;

  /// Yes/no question.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get regYes;

  /// Yes/no question.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get regNo;

  /// Single choice with many options, nothing chosen yet.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get regChoose;

  /// Date question, nothing chosen yet.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get regPickDate;

  /// Number question hint.
  ///
  /// In en, this message translates to:
  /// **'Whole number'**
  String get regWholeNumber;

  /// Number question hint.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max}'**
  String regRange(String min, String max);

  /// Number question hint.
  ///
  /// In en, this message translates to:
  /// **'At least {min}'**
  String regAtLeast(String min);

  /// Number question hint.
  ///
  /// In en, this message translates to:
  /// **'At most {max}'**
  String regAtMost(String max);

  /// Multiple choice hint.
  ///
  /// In en, this message translates to:
  /// **'Choose all that apply'**
  String get regChooseAny;

  /// Read by VoiceOver after a required field's label.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get regRequired;

  /// Field error: full_name required.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get regErrNameRequired;

  /// Field error: full_name invalid.
  ///
  /// In en, this message translates to:
  /// **'At most 120 characters.'**
  String get regErrNameInvalid;

  /// Field error: phone required.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get regErrPhoneRequired;

  /// Field error: phone invalid, or a phone question's invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get regErrPhoneInvalid;

  /// Field error: required.
  ///
  /// In en, this message translates to:
  /// **'This question is required.'**
  String get regErrRequired;

  /// Field error: too_long.
  ///
  /// In en, this message translates to:
  /// **'This answer is too long.'**
  String get regErrTooLong;

  /// Field error: not_a_number.
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get regErrNotANumber;

  /// Field error: not_an_integer.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get regErrNotAnInteger;

  /// Field error: out_of_range.
  ///
  /// In en, this message translates to:
  /// **'Enter a number in the allowed range.'**
  String get regErrOutOfRange;

  /// Field error: unknown_option.
  ///
  /// In en, this message translates to:
  /// **'That option is gone. Choose again.'**
  String get regErrUnknownOption;

  /// Field error: invalid_date.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid date.'**
  String get regErrInvalidDate;

  /// Field error: wrong_type, unknown_question or anything new.
  ///
  /// In en, this message translates to:
  /// **'This answer wasn\'t accepted. Update the app.'**
  String get regErrRejected;
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
