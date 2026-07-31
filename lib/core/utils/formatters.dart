import 'dart:math';
import 'package:intl/intl.dart';

/// A utility class for formatting various data types into human-readable strings.
///
/// This class provides static methods for formatting dates, times, numbers,
/// currencies, file sizes, percentages, durations, and text. It is designed
/// to be easily extensible for future formatting needs.
abstract final class Formatters {
  const Formatters._();

  // ---------------------------------------------------------------------------
  // Date and Time Formatters
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] object into a date string (e.g., 'Jan 1, 2023').
  static String formatDate(DateTime dateTime, {String? locale}) {
    return DateFormat.yMMMd(locale).format(dateTime);
  }

  /// Formats a [DateTime] object into a time string (e.g., '10:30 AM').
  static String formatTime(DateTime dateTime, {String? locale}) {
    return DateFormat.jm(locale).format(dateTime);
  }

  /// Formats a [DateTime] object into a date and time string (e.g., 'Jan 1, 2023 10:30 AM').
  static String formatDateTime(DateTime dateTime, {String? locale}) {
    return DateFormat.yMMMd(locale).add_jm().format(dateTime);
  }

  /// Formats a [DateTime] object into a full date and time string (e.g., 'Monday, January 1, 2023 10:30:00 AM').
  static String formatFullDateTime(DateTime dateTime, {String? locale}) {
    return DateFormat.EEEE(locale).add_yMMMMd().add_jms().format(dateTime);
  }

  // ---------------------------------------------------------------------------
  // Numeric Formatters
  // ---------------------------------------------------------------------------

  /// Formats a [num] into a currency string (e.g., '$1,234.56').
  static String formatCurrency(num amount, {String symbol = '$', String? locale}) {
    final formatter = NumberFormat.currency(locale: locale, symbol: symbol);
    return formatter.format(amount);
  }

  /// Formats a [num] into a decimal number string with a specified number of decimal places.
  static String formatDecimal(num number, {int decimalDigits = 2, String? locale}) {
    final formatter = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(number);
  }

  /// Formats a [num] into a percentage string (e.g., '12.34%').
  static String formatPercentage(num value, {int decimalDigits = 2, String? locale}) {
    final formatter = NumberFormat.percentPattern(locale)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(value / 100);
  }

  /// Formats a [int] representing bytes into a human-readable file size string (e.g., '1.23 MB').
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes > 0 ? (log(bytes) / log(1024)) : 0).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Formats a [Duration] into a human-readable string (e.g., '1h 30m 15s').
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (duration.inMinutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // ---------------------------------------------------------------------------
  // Text Formatters
  // ---------------------------------------------------------------------------

  /// Capitalizes the first letter of each word in a string.
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncates a string to a specified [maxLength] and appends an ellipsis if truncated.
  static String truncateText(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
