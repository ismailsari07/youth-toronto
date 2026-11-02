const _turkishMonths = {
  'ocak': 1, 'şubat': 2, 'subat': 2, 'mart': 3, 'nisan': 4, 'mayıs': 5,
  'mayis': 5, 'haziran': 6, 'temmuz': 7, 'ağustos': 8, 'agustos': 8,
  'eylül': 9, 'eylul': 9, 'ekim': 10, 'kasım': 11, 'kasim': 11, 'aralık': 12,
  'aralik': 12,
};

/// `eidPrayerTimes.date` arrives as a Turkish string from the upstream
/// Diyanet feed ("20 Mart 2026 Cuma"). Unreadable: null, so no Eid is shown.
DateTime? parseEidDate(String raw) {
  final parts = raw.trim().split(RegExp(r'\s+'));
  if (parts.length < 3) return null;
  final day = int.tryParse(parts[0]);
  final month = _turkishMonths[parts[1].toLowerCase()];
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}
