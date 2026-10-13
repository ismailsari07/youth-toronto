/// Prayer reminders are switched off while their times can be wrong for
/// members who don't open the app for a few days (prayer_cache only holds
/// today's row). While false: nothing is scheduled, every reminder an
/// earlier build left on the phone is cancelled at launch, the permission
/// is never asked for, and the bell, the reminders sheet and the reminder
/// rows are hidden. The code and strings stay; set to true to bring it all
/// back.
const bool kPrayerRemindersEnabled = false;
