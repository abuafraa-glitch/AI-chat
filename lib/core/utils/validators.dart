/// A utility class for performing common validation checks.
///
/// This class provides static methods to validate various types of input,
/// such as email, password, phone numbers, and more. It is designed to be
/// easily extensible for future validation rules.
abstract final class Validators {
  const Validators._();

  // ---------------------------------------------------------------------------
  // General Validators
  // ---------------------------------------------------------------------------

  /// Returns `true` if the [value] is not null and not empty.
  static bool required(String? value) {
    return value != null && value.isNotEmpty;
  }

  /// Returns `true` if the [value] is null or empty.
  static bool empty(String? value) {
    return value == null || value.isEmpty;
  }

  /// Returns `true` if the [value] has a length greater than or equal to [minLength].
  static bool minLength(String? value, int minLength) {
    return value != null && value.length >= minLength;
  }

  /// Returns `true` if the [value] has a length less than or equal to [maxLength].
  static bool maxLength(String? value, int maxLength) {
    return value != null && value.length <= maxLength;
  }

  // ---------------------------------------------------------------------------
  // Specific Type Validators
  // ---------------------------------------------------------------------------

  /// Returns `true` if the [email] is a valid email format.
  static bool email(String? email) {
    if (email == null || email.isEmpty) return false;
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegex.hasMatch(email);
  }

  /// Returns `true` if the [password] meets the minimum security requirements.
  /// (e.g., at least 8 characters, contains uppercase, lowercase, digit, and special character).
  static bool password(String? password) {
    if (password == null || password.isEmpty) return false;
    // At least 8 characters, one uppercase, one lowercase, one digit, one special character
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_+{}|:<>?~-]).{8,}');
    return passwordRegex.hasMatch(password);
  }

  /// Returns `true` if the [username] is valid.
  /// (e.g., alphanumeric, 3-20 characters).
  static bool username(String? username) {
    if (username == null || username.isEmpty) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
  }

  /// Returns `true` if the [phone] number is a valid format.
  /// (Basic check, can be extended for specific country codes).
  static bool phone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Returns `true` if the [url] is a valid URL format.
  static bool url(String? url) {
    if (url == null || url.isEmpty) return false;
    final urlRegex = RegExp(
        r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');
    return urlRegex.hasMatch(url);
  }

  /// Returns `true` if the [value] contains only numeric digits.
  static bool numeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  /// Returns `true` if the [value] contains only integer digits.
  static bool integer(String? value) {
    if (value == null || value.isEmpty) return false;
    return int.tryParse(value) != null;
  }

  /// Returns `true` if the [value] contains a valid double.
  static bool doubleValue(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  /// Returns `true` if the [fileName] is a valid file name.
  /// (Basic check, disallows common invalid characters).
  static bool fileName(String? fileName) {
    if (fileName == null || fileName.isEmpty) return false;
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return !invalidChars.hasMatch(fileName);
  }

  /// Returns `true` if the [fileSize] is within the [maxSize] in bytes.
  static bool fileSize(int? fileSize, int maxSize) {
    return fileSize != null && fileSize <= maxSize;
  }
}
