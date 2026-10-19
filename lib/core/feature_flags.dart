/// Prayer reminders (back since 1.3.0, off 1.0.2–1.2.x). They were off
/// while prayer_cache held only today's row and the app filled later days
/// with it. Now the rows cover about 30 days and the app schedules only from
/// real rows (scheduleDays), as many days as fit in iOS's 64 slots. While false: nothing is
/// scheduled, every pending reminder is cancelled at launch, and the bell,
/// the reminders sheet and the reminder rows are hidden.
const bool kPrayerRemindersEnabled = true;

/// Sign in with Google is postponed (1.1.0 ships Apple only). The code
/// stays (AuthService.signInWithGoogle, the button in
/// SocialSignInButtons); while false the button is hidden. To turn it on:
/// set this to true and add GIDClientID, GIDServerClientID and the reversed
/// iOS client ID URL scheme to ios/Runner/Info.plist (see CLAUDE.md).
const bool kGoogleSignInEnabled = false;
