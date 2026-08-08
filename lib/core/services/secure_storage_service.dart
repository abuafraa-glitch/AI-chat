import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/network/api_consumer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A typed wrapper around [FlutterSecureStorage] for the Hajeen AI
/// application.
///
/// Sensitive values — access tokens, refresh tokens, biometric keys,
/// PIN hashes, and push-device tokens — must be persisted exclusively
/// through this service. Non-sensitive preferences belong in
/// [LocalStorageService].
///
/// The service configures platform-appropriate encryption options:
/// - **Android**: `encryptedSharedPreferences: true` (uses Jetpack
///   Security under the hood, backed by the Android Keystore).
/// - **iOS**: `KeychainAccessibility.first_unlock_this_device` so
///   that the data is accessible after the first unlock and survives
///   app reinstalls when iCloud Keychain is enabled.
///
/// All keys are sourced from [SecureStorageKeys] to enforce a
/// consistent, namespaced key-space.
///
/// ### Usage
/// ```dart
/// await secureStorage.writeAccessToken(token);
/// final token = await secureStorage.readAccessToken();
/// await secureStorage.clearTokens();
/// ```
final class SecureStorageService implements TokenProvider {
  /// Creates a [SecureStorageService].
  ///
  /// The [storage] parameter is exposed for dependency injection in
  /// tests. Production code should omit it; the default instance is
  /// configured automatically with the correct platform options.
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  // ── Generic read / write / delete ─────────────────────────────────────────

  /// Returns the value stored under [key], or `null` if absent.
  Future<String?> read(String key) => _storage.read(key: key);

  /// Returns `true` if a value has been stored under [key].
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  /// Returns all key-value pairs in secure storage for this app.
  ///
  /// Prefer targeted [read] calls in hot paths; this method is intended
  /// for diagnostics and data-migration scenarios only.
  Future<Map<String, String>> readAll() => _storage.readAll();

  /// Persists [value] under [key].
  ///
  /// If [key] already exists its value is silently overwritten.
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Removes the value stored under [key].
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Removes every value from secure storage for this app.
  ///
  /// This is a destructive, irreversible operation. Prefer [delete]
  /// for targeted eviction.
  Future<void> deleteAll() => _storage.deleteAll();

  // ── Token convenience ─────────────────────────────────────────────────────

  /// Returns the current access token, or `null` if none has been
  /// stored.
  Future<String?> readAccessToken() =>
      read(SecureStorageKeys.accessToken);

  /// Persists [token] as the current access token.
  Future<void> writeAccessToken(String token) =>
      write(SecureStorageKeys.accessToken, token);

  /// Returns the current refresh token, or `null` if none has been
  /// stored.
  Future<String?> readRefreshToken() =>
      read(SecureStorageKeys.refreshToken);

  /// Persists [token] as the current refresh token.
  Future<void> writeRefreshToken(String token) =>
      write(SecureStorageKeys.refreshToken, token);

  /// Removes both the access and refresh tokens in a single operation.
  ///
  /// Call this during user sign-out to invalidate the local session
  /// before navigating to the login screen.
  Future<void> clearTokens() async {
    await Future.wait<void>(<Future<void>>[
      delete(SecureStorageKeys.accessToken),
      delete(SecureStorageKeys.refreshToken),
    ]);
  }

  // ── Device token ──────────────────────────────────────────────────────────

  /// Returns the stored push-notification device token, or `null` if
  /// the device has not yet registered.
  Future<String?> readPushDeviceToken() =>
      read(SecureStorageKeys.pushDeviceToken);

  /// Persists [token] as the push-notification device token.
  Future<void> writePushDeviceToken(String token) =>
      write(SecureStorageKeys.pushDeviceToken, token);

  /// Removes the stored push-notification device token.
  ///
  /// Call when the user opts out of notifications or on sign-out.
  Future<void> deletePushDeviceToken() =>
      delete(SecureStorageKeys.pushDeviceToken);

  // ── PIN ───────────────────────────────────────────────────────────────────

  /// Returns the stored PIN hash, or `null` if the user has not set a
  /// PIN.
  Future<String?> readPinCodeHash() =>
      read(SecureStorageKeys.pinCodeHash);

  /// Persists [hash] as the PIN code hash.
  ///
  /// Store only the hash of the PIN — never the raw PIN value.
  Future<void> writePinCodeHash(String hash) =>
      write(SecureStorageKeys.pinCodeHash, hash);

  /// Removes the stored PIN hash.
  Future<void> deletePinCodeHash() =>
      delete(SecureStorageKeys.pinCodeHash);
}
