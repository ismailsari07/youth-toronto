/// A Siri question (or a silent push) can launch the app in the background.
/// [main] and the first frame still run, because Flutter builds its first
/// frame without a screen, but nothing a member would notice may happen then:
/// no pre-prompt, no launch counted, no `register_device`, no reminders
/// rescheduled, no sync of the panel's content. All of that waits until the
/// app really comes forward, and runs once. (The unseen first frame can still
/// run a screen's read-only loads; they write nothing.)
class LaunchGate {
  LaunchGate({required this.startedInBackground, required this.onFirstForeground});

  /// What iOS said when [main] asked. Elsewhere, or if asking failed: false,
  /// which is how the app has always started.
  final bool startedInBackground;
  final void Function() onFirstForeground;

  bool _ran = false;

  /// Whether the launch's foreground work has run.
  bool get ran => _ran;

  void _run() {
    if (_ran) return;
    _ran = true;
    onFirstForeground();
  }

  /// After the first frame. [isResumed] covers the app coming forward before
  /// the lifecycle listener was there to hear it.
  void firstFrame({required bool isResumed}) {
    if (!startedInBackground || isResumed) _run();
  }

  /// On every resume. True when this was a later resume, for the caller's
  /// usual resume work; false when it ran the launch's work instead.
  bool resume() {
    if (_ran) return true;
    _run();
    return false;
  }
}
