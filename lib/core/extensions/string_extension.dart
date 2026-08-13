import 'package:ai_chat/core/constants/app_constants.dart';

/// Extensions on [String] for validation, formatting, and text utilities
/// used throughout the Hajeen AI platform.
///
/// All members are pure Dart — no Flutter or third-party dependencies —
/// so they can be used freely in domain, data, and presentation layers.
extension StringValidationExtension on String {
  // ── Email ────────────────────────────────────────────────────────────────

  /// Returns `true` when the string is a syntactically valid e-mail address.
  ///
  /// The pattern follows the common subset used by most mail servers and
  /// is intentionally conservative; edge-case valid addresses that would
  /// fail here (e.g. quoted-string local parts) are extremely rare in
  /// practice.
  bool get isValidEmail {
    if (isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(trim());
  }

  // ── Password ─────────────────────────────────────────────────────────────

  /// Returns `true` when the string satisfies the platform password policy:
  /// between [AppLimits.minPasswordLength] and [AppLimits.maxPasswordLength]
  /// characters and contains at least one uppercase letter, one lowercase
  /// letter, one digit, and one special character.
  bool get isValidPassword {
    final len = length;
    if (len < AppLimits.minPasswordLength ||
        len > AppLimits.maxPasswordLength) {
      return false;
    }
    final hasUpper = contains(RegExp('[A-Z]'));
    final hasLower = contains(RegExp('[a-z]'));
    final hasDigit = contains(RegExp('[0-9]'));
    final hasSpecial = contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{}|;:,.?/~`]'));
    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  /// Returns `true` when the string length is within the password length range.
  ///
  /// Use this for a lighter check that does not enforce character-class rules
  /// (e.g. on every keystroke before the full check on submission).
  bool get isPasswordLengthValid {
    return length >= AppLimits.minPasswordLength &&
        length <= AppLimits.maxPasswordLength;
  }

  // ── Display name ──────────────────────────────────────────────────────────

  /// Returns `true` when the string is a valid user display name.
  bool get isValidDisplayName {
    final trimmed = trim();
    return trimmed.length >= AppLimits.minDisplayNameLength &&
        trimmed.length <= AppLimits.maxDisplayNameLength;
  }

  // ── URL ───────────────────────────────────────────────────────────────────

  /// Returns `true` when the string is a syntactically valid HTTP/HTTPS URL.
  bool get isValidUrl {
    if (isEmpty) return false;
    final uri = Uri.tryParse(this);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  /// Returns `true` when the string looks like an international phone number.
  ///
  /// Accepts digits, spaces, dashes, parentheses, and an optional leading `+`.
  /// Length is validated to be between 7 and 15 digits (ITU-T E.164).
  bool get isValidPhoneNumber {
    if (isEmpty) return false;
    final cleaned = replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    return regex.hasMatch(cleaned);
  }

  // ── Chat message ──────────────────────────────────────────────────────────

  /// Returns `true` when the string is a valid chat message payload.
  bool get isValidChatMessage {
    final trimmed = trim();
    return trimmed.length >= AppLimits.minMessageLength &&
        trimmed.length <= AppLimits.maxMessageLength;
  }
}

/// Extensions on [String] for formatting and text transformation.
extension StringFormattingExtension on String {
  // ── Case ──────────────────────────────────────────────────────────────────

  /// Returns the string with the first character uppercased and the rest
  /// unchanged.
  ///
  /// Returns an empty string when [isEmpty].
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns the string with each word's first letter uppercased.
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  // ── Truncation ────────────────────────────────────────────────────────────

  /// Truncates the string to [maxLength] characters, appending [ellipsis]
  /// when truncation occurs.
  ///
  /// When [maxLength] is less than or equal to zero, returns an empty string.
  /// The returned string (including the ellipsis) will never exceed
  /// [maxLength] + [ellipsis].length characters.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (maxLength <= 0) return '';
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  // ── Initials ─────────────────────────────────────────────────────────────

  /// Extracts uppercase initials from the string, up to [maxInitials] (default
  /// `2`). Initials are derived from the first character of each whitespace-
  /// separated word.
  ///
  /// Examples:
  /// ```dart
  /// 'Hajeen AI'.toInitials()   // → 'HA'
  /// 'Ali'.toInitials()         // → 'A'
  /// ```
  String toInitials({int maxInitials = 2}) {
    final words = trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .take(maxInitials)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  // ── Slug ─────────────────────────────────────────────────────────────────

  /// Converts the string to a URL-safe slug (lowercase, hyphens, no special
  /// characters).
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  // ── Security / logging ────────────────────────────────────────────────────

  /// Returns a masked version of the string suitable for logging.
  ///
  /// Keeps the first and last [visibleChars] characters (default `2`) and
  /// replaces the middle with `*` repeated by [maskLength] (default `4`).
  /// Short strings (length ≤ [visibleChars] × 2) are fully masked.
  String maskSensitive({int visibleChars = 2, int maskLength = 4}) {
    if (length <= visibleChars * 2) return '*' * maskLength;
    final mask = '*' * maskLength;
    return '${substring(0, visibleChars)}$mask${substring(length - visibleChars)}';
  }

  // ── Arabic / RTL detection ────────────────────────────────────────────────

  /// Returns `true` when the string contains at least one Arabic character.
  bool get hasArabicCharacters {
    return contains(RegExp(r'[\u0600-\u06FF]'));
  }

  /// Returns `true` when the majority of alphabetic characters in the string
  /// are Arabic, indicating the content should be displayed RTL.
  bool get isPrimarilyArabic {
    if (isEmpty) return false;
    final arabicCount = RegExp(r'[\u0600-\u06FF]').allMatches(this).length;
    final latinCount = RegExp(r'[a-zA-Z]').allMatches(this).length;
    if (arabicCount == 0 && latinCount == 0) return false;
    return arabicCount >= latinCount;
  }
}

/// Null-safe convenience extensions on nullable [String].
extension NullableStringExtension on String? {
  /// Returns `true` when the string is `null` or empty after trimming.
  bool get isNullOrBlank {
    final value = this;
    return value == null || value.trim().isEmpty;
  }

  /// Returns `true` when the string is neither `null` nor blank.
  bool get isNotNullOrBlank => !isNullOrBlank;

  /// Returns this string if it is not null and not blank; otherwise returns
  /// [fallback] (default `''`).
  String orElse([String fallback = '']) {
    final value = this;
    return (value == null || value.trim().isEmpty) ? fallback : value;
  }
}
