import 'package:intl/intl.dart';

/// Extensions on [DateTime] for formatting, comparison, and utility operations
/// used throughout the Hajeen AI platform.
///
/// Formatting methods use the `intl` package for locale-aware output.
/// Relative-time strings are returned in English; wrap them in the
/// localization layer for production-localised display.
extension DateTimeFormattingExtension on DateTime {
  // ── ISO ───────────────────────────────────────────────────────────────────

  /// Returns the date as an ISO-8601 calendar string: `yyyy-MM-dd`.
  String toIsoDate() => DateFormat('yyyy-MM-dd').format(this);

  /// Returns a full ISO-8601 UTC timestamp: `yyyy-MM-dd'T'HH:mm:ss'Z'`.
  ///
  /// The value is first converted to UTC before formatting.
  String toIsoUtc() => DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(toUtc());

  // ── Display ───────────────────────────────────────────────────────────────

  /// Returns the date formatted as `dd/MM/yyyy` (regional short date).
  String toDisplayDate() => DateFormat('dd/MM/yyyy').format(this);

  /// Returns the date formatted as `MMMM d, yyyy` (long form).
  String toDisplayDateLong() => DateFormat('MMMM d, yyyy').format(this);

  /// Returns the time formatted as `HH:mm` (24-hour clock).
  String toDisplayTime24() => DateFormat('HH:mm').format(this);

  /// Returns the time formatted as `h:mm a` (12-hour clock with AM/PM).
  String toDisplayTime12() => DateFormat('h:mm a').format(this);

  /// Returns a combined date-time string: `dd/MM/yyyy HH:mm`.
  String toDisplayDateTime() => '${toDisplayDate()} ${toDisplayTime24()}';

  // ── Relative time ─────────────────────────────────────────────────────────

  /// Returns a human-readable relative description of this moment compared to
  /// [now] (defaults to [DateTime.now]).
  ///
  /// Examples: `'just now'`, `'5 minutes ago'`, `'2 hours ago'`,
  /// `'yesterday'`, `'3 days ago'`, `'last month'`, `'2 years ago'`.
  ///
  /// Times in the future return `'in the future'`.
  String toRelativeTime({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(this);

    if (diff.isNegative) return 'in the future';

    final seconds = diff.inSeconds;
    final minutes = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;

    if (seconds < 60) return 'just now';
    if (minutes < 60) {
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }
    if (hours < 24) {
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 14) return 'last week';
    if (days < 30) {
      final weeks = (days / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (days < 60) return 'last month';
    if (days < 365) {
      final months = (days / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    final years = (days / 365).floor();
    return years == 1 ? '1 year ago' : '$years years ago';
  }

  // ── Chat timestamp ────────────────────────────────────────────────────────

  /// Returns a short timestamp suitable for chat message bubbles.
  ///
  /// — Same day   → `HH:mm`
  /// — Yesterday  → `Yesterday HH:mm`
  /// — This year  → `MMM d, HH:mm`
  /// — Older      → `dd/MM/yyyy HH:mm`
  String toChatTimestamp({DateTime? now}) {
    final reference = now ?? DateTime.now();

    if (isSameDay(reference)) {
      return toDisplayTime24();
    }
    if (isYesterday(reference)) {
      return 'Yesterday ${toDisplayTime24()}';
    }
    if (year == reference.year) {
      return '${DateFormat('MMM d').format(this)}, ${toDisplayTime24()}';
    }
    return toDisplayDateTime();
  }
}

/// Extensions on [DateTime] for date comparisons and boundary calculations.
extension DateTimeComparisonExtension on DateTime {
  // ── Same-day checks ───────────────────────────────────────────────────────

  /// Returns `true` when this [DateTime] falls on the same calendar day as
  /// [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns `true` when this [DateTime] falls on the calendar day
  /// immediately before [reference] (defaults to today).
  bool isYesterday([DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    final yesterday = ref.subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Returns `true` when this [DateTime] is today (same calendar day as
  /// [DateTime.now]).
  bool get isToday => isSameDay(DateTime.now());

  // ── Calendar-range checks ─────────────────────────────────────────────────

  /// Returns `true` when this [DateTime] falls within the last 7 calendar
  /// days relative to [reference] (defaults to today).
  bool isThisWeek([DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    final weekAgo = ref.subtract(const Duration(days: 7));
    return isAfter(weekAgo) && !isAfter(ref);
  }

  /// Returns `true` when this [DateTime]'s month and year match [reference]
  /// (defaults to [DateTime.now]).
  bool isThisMonth([DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    return year == ref.year && month == ref.month;
  }

  /// Returns `true` when this [DateTime]'s year matches [reference]'s year
  /// (defaults to [DateTime.now]).
  bool isThisYear([DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    return year == ref.year;
  }

  // ── Boundary helpers ──────────────────────────────────────────────────────

  /// Returns a [DateTime] at the very start of this calendar day
  /// (00:00:00.000).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns a [DateTime] at the very end of this calendar day
  /// (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns a [DateTime] at the start of the calendar month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Returns a [DateTime] at the start of the calendar year.
  DateTime get startOfYear => DateTime(year);

  // ── Difference helpers ────────────────────────────────────────────────────

  /// Returns the number of whole calendar days between this and [other],
  /// ignoring time-of-day. A positive value means [other] is in the future.
  int calendarDaysUntil(DateTime other) =>
      other.startOfDay.difference(startOfDay).inDays;

  /// Returns `true` when this [DateTime] is strictly before today.
  bool get isPast => isBefore(DateTime.now());

  /// Returns `true` when this [DateTime] is strictly after now.
  bool get isFuture => isAfter(DateTime.now());
}

/// Null-safe convenience extensions on nullable [DateTime].
extension NullableDateTimeExtension on DateTime? {
  /// Returns this value, or [fallback], when `null`.
  DateTime orElse(DateTime fallback) => this ?? fallback;

  /// Returns `toRelativeTime()` when non-null, or [fallbackText] when `null`.
  String toRelativeTimeOrElse({String fallbackText = '—'}) {
    final value = this;
    return value != null ? value.toRelativeTime() : fallbackText;
  }

  /// Returns `toDisplayDate()` when non-null, or [fallbackText] when `null`.
  String toDisplayDateOrElse({String fallbackText = '—'}) {
    final value = this;
    return value != null ? value.toDisplayDate() : fallbackText;
  }
}
