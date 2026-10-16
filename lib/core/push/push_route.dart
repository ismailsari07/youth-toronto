final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Where a tapped notification opens, from its data (all strings):
/// `event_id` → that event (with `occurrence`, that day's session),
/// else `announcement_id` → that announcement, else the Community tab.
/// Malformed ids count as absent.
String pushRoute(Map<String, dynamic> data) {
  final eventId = data['event_id'];
  if (eventId is String && _uuid.hasMatch(eventId)) {
    final occurrence = data['occurrence'];
    return occurrence is String && _day.hasMatch(occurrence)
        ? '/community/event/$eventId?occurrence=$occurrence'
        : '/community/event/$eventId';
  }
  final announcementId = data['announcement_id'];
  if (announcementId is String && _uuid.hasMatch(announcementId)) {
    return '/community/announcement/$announcementId';
  }
  return '/community';
}

/// The last notifications already opened, so a second open of the same
/// one (cold start and stream both reporting it) does nothing.
class OpenedNotifications {
  OpenedNotifications([Iterable<String> seen = const []])
      : _seen = [...seen];

  static const keep = 50;
  final List<String> _seen;

  List<String> get seen => List.unmodifiable(_seen);

  /// True the first time [nid] is seen; a missing id always opens.
  bool firstOpen(String? nid) {
    if (nid == null || nid.isEmpty) return true;
    if (_seen.contains(nid)) return false;
    _seen.add(nid);
    if (_seen.length > keep) _seen.removeRange(0, _seen.length - keep);
    return true;
  }
}
