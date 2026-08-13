import 'dart:math';

/// A collection of general utility functions and helpers that do not belong
/// to any specific layer or domain. These helpers are designed to be pure
/// functions or static methods, avoiding business logic.
abstract final class Helpers {
  const Helpers._();

  // ---------------------------------------------------------------------------
  // String Helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` if the string is null, empty, or contains only whitespace characters.
  static bool isNullEmptyOrWhitespace(String? s) {
    return s == null || s.trim().isEmpty;
  }

  /// Capitalizes the first letter of a string.
  static String capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Reverses a given string.
  static String reverseString(String s) {
    return s.split('').reversed.join();
  }

  // ---------------------------------------------------------------------------
  // Collection Helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` if the list is null or empty.
  static bool isNullOrEmptyList<T>(List<T>? list) {
    return list == null || list.isEmpty;
  }

  /// Returns `true` if the map is null or empty.
  static bool isNullOrEmptyMap<K, V>(Map<K, V>? map) {
    return map == null || map.isEmpty;
  }

  /// Returns a new list containing only the unique elements from the original list.
  static List<T> uniqueList<T>(List<T> list) {
    return list.toSet().toList();
  }

  // ---------------------------------------------------------------------------
  // Date Helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` if the given [dateTime] is today.
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Returns `true` if the given [dateTime] is yesterday.
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  // ---------------------------------------------------------------------------
  // Safe Parsing
  // ---------------------------------------------------------------------------

  /// Safely parses a string to an integer, returning `null` if parsing fails.
  static int? safeParseInt(String? s) {
    return int.tryParse(s ?? '');
  }

  /// Safely parses a string to a double, returning `null` if parsing fails.
  static double? safeParseDouble(String? s) {
    return double.tryParse(s ?? '');
  }

  /// Safely parses a string to a boolean, returning `null` if parsing fails.
  /// Recognizes 'true', '1', 'yes' as true (case-insensitive).
  static bool? safeParseBool(String? s) {
    if (s == null) return null;
    final lower = s.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Equality Helpers
  // ---------------------------------------------------------------------------

  /// Compares two lists for deep equality.
  static bool areListsEqual<T>(List<T>? list1, List<T>? list2) {
    if (identical(list1, list2)) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Compares two maps for deep equality.
  static bool areMapsEqual<K, V>(Map<K, V>? map1, Map<K, V>? map2) {
    if (identical(map1, map2)) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Random Utilities
  // ---------------------------------------------------------------------------

  static final Random _random = Random();

  /// Generates a random integer within a specified range (inclusive).
  static int randomInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates a random string of a specified length.
  static String randomString(
    int length, {
    String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
  }) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }
}
