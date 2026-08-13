import 'dart:async';
import 'dart:collection';

/// A single cache entry holding a strongly-typed value and its
/// expiration timestamp.
final class _CacheEntry<T extends Object> {
  const _CacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// An in-memory TTL cache for the Hajeen AI application.
///
/// All entries carry a mandatory time-to-live ([Duration]) after which
/// they are treated as stale and removed on the next access or via an
/// explicit eviction sweep. The cache is **not** persisted to disk; it
/// survives only for the lifetime of the running process.
///
/// The cache is safe within the main Dart isolate because Dart's event
/// loop is single-threaded; it is **not** safe across isolates.
///
/// ### Usage
/// ```dart
/// final cache = CacheService();
/// cache.put('key', 42, ttl: const Duration(minutes: 5));
/// final value = cache.get<int>('key'); // 42
/// ```
final class CacheService {
  /// Creates a new [CacheService] with an empty internal store.
  CacheService() : _store = LinkedHashMap<String, _CacheEntry<Object>>();

  final LinkedHashMap<String, _CacheEntry<Object>> _store;
  Timer? _evictionTimer;

  // ── Write ───────────────────────────────────────────────────────────────

  /// Inserts [value] under [key] with a time-to-live of [ttl].
  ///
  /// If [key] already exists its entry is silently overwritten.
  void put<T extends Object>(String key, T value, {required Duration ttl}) {
    _store[key] = _CacheEntry<T>(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    _scheduleEviction();
  }

  // ── Read ────────────────────────────────────────────────────────────────

  /// Returns the value stored under [key] cast to [T], or `null` if
  /// the key is absent or its entry has expired.
  T? get<T extends Object>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    final value = entry.value;
    if (value is T) return value;
    return null;
  }

  /// Returns `true` if [key] exists in the cache and has not expired.
  bool containsKey(String key) {
    final entry = _store[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _store.remove(key);
      return false;
    }
    return true;
  }

  /// Returns the remaining time-to-live for [key], or `null` if the
  /// key is absent or expired.
  Duration? remainingTtl(String key) {
    final entry = _store[key];
    if (entry == null || entry.isExpired) return null;
    return entry.expiresAt.difference(DateTime.now());
  }

  // ── Remove ──────────────────────────────────────────────────────────────

  /// Removes the entry for [key], whether expired or not.
  void remove(String key) => _store.remove(key);

  /// Removes all entries whose keys start with [prefix].
  ///
  /// Useful for invalidating a logical group of related entries, e.g.
  /// all cached messages for a single conversation.
  void removeByPrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  // ── Maintenance ─────────────────────────────────────────────────────────

  /// Removes all expired entries from the store.
  ///
  /// Called automatically by an internal periodic timer. Also safe to
  /// invoke manually — for example when the application returns to
  /// the foreground after a long background session.
  void evictExpired() {
    final now = DateTime.now();
    _store.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }

  /// Removes every entry from the cache, regardless of expiration, and
  /// cancels the internal eviction timer.
  ///
  /// Use this when clearing a user session so that stale data from the
  /// previous session cannot bleed into the next one.
  void clear() {
    _store.clear();
    _evictionTimer?.cancel();
    _evictionTimer = null;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Cancels the eviction timer and clears the store.
  ///
  /// Call this when the service is being torn down to avoid timer
  /// leaks in test environments.
  void dispose() {
    _evictionTimer?.cancel();
    _evictionTimer = null;
    _store.clear();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  /// Starts a periodic eviction sweep if one is not already running.
  void _scheduleEviction() {
    if (_evictionTimer?.isActive ?? false) return;
    _evictionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => evictExpired(),
    );
  }
}
