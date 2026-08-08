/// Shared presentation formatters.
///
/// Formatting is a pure presentation concern; keeping the small
/// helpers here avoids duplicating the same logic across screens and
/// widgets.
library;

/// Formats [date] as a local `yyyy-MM-dd` string.
String formatAppDate(DateTime date) {
  final local = date.toLocal();
  final year = local.year.toString();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Formats [time] as a local `HH:mm` string.
String formatAppTime(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
