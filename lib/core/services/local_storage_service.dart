import 'package:shared_preferences/shared_preferences.dart';

/// A typed wrapper around [SharedPreferences] for the Hajeen AI
/// application.
///
/// All keys must be sourced from [StorageKeys] to guarantee a
/// consistent, namespaced key-space and prevent collisions with other
/// storage layers. Values stored here are **non-sensitive**: tokens and
/// secrets must be persisted exclusively through [SecureStorageService].
///
/// The service is initialised asynchronously via [LocalStorageService.create]
/// and should be registered as a singleton in the DI container after that
/// future resolves. Instances must not be constructed directly.
final class LocalStorageService {
  LocalStorageService._(SharedPreferences prefs) : _prefs = prefs;

  final SharedPreferences _prefs;

  // ── Factory ──────────────────────────────────────────────────────────────

  /// Creates and initialises a [LocalStorageService].
  ///
  /// Await this during the application bootstrap phase before
  /// registering the instance with the DI container.
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService._(prefs);
  }

  // ── String ───────────────────────────────────────────────────────────────

  /// Returns the [String] stored under [key], or `null` if absent.
  String? getString(String key) => _prefs.getString(key);

  /// Persists [value] under [key].
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  // ── Bool ─────────────────────────────────────────────────────────────────

  /// Returns the [bool] stored under [key], or `null` if absent.
  bool? getBool(String key) => _prefs.getBool(key);

  /// Persists [value] under [key].
  Future<void> setBool(String key, {required bool value}) async {
    await _prefs.setBool(key, value);
  }

  // ── Int ──────────────────────────────────────────────────────────────────

  /// Returns the [int] stored under [key], or `null` if absent.
  int? getInt(String key) => _prefs.getInt(key);

  /// Persists [value] under [key].
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  // ── Double ───────────────────────────────────────────────────────────────

  /// Returns the [double] stored under [key], or `null` if absent.
  double? getDouble(String key) => _prefs.getDouble(key);

  /// Persists [value] under [key].
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  // ── String list ──────────────────────────────────────────────────────────

  /// Returns the `List<String>` stored under [key], or `null` if
  /// absent.
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  /// Persists [value] under [key].
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  // ── Key presence ─────────────────────────────────────────────────────────

  /// Returns `true` if a value has been stored under [key].
  bool containsKey(String key) => _prefs.containsKey(key);

  /// Returns all stored keys.
  ///
  /// Intended for diagnostics only. Avoid iterating this in hot paths.
  Set<String> get allKeys => _prefs.getKeys();

  // ── Removal ──────────────────────────────────────────────────────────────

  /// Removes the value stored under [key].
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  /// Removes all values stored by this application.
  ///
  /// This is a destructive operation. Prefer [remove] for targeted
  /// eviction. Call this only on a deliberate user sign-out or a
  /// factory reset of local data.
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
