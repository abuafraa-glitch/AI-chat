import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/services/cache_service.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider exposing the [LocalStorageService] singleton.
///
/// The instance is resolved from the GetIt container (`sl`) which is
/// initialised during the application bootstrap phase by
/// `initDependencies()`.
///
/// ```dart
/// final name = ref.watch(localStorageServiceProvider).getString(key);
/// ```
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return sl<LocalStorageService>();
});

/// Riverpod provider exposing the [SecureStorageService] singleton.
///
/// Use this for sensitive values (access tokens, refresh tokens, PIN
/// hashes) — never [localStorageServiceProvider].
///
/// ```dart
/// final token = await ref.read(secureStorageServiceProvider).readAccessToken();
/// ```
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return sl<SecureStorageService>();
});

/// Riverpod provider exposing the in-memory [CacheService] singleton.
///
/// The cache is process-lifetime only and is never persisted; use it
/// for short-lived, strongly-typed values with a TTL.
///
/// ```dart
/// ref.read(cacheServiceProvider).put(key, value, ttl: const Duration(minutes: 5));
/// ```
final cacheServiceProvider = Provider<CacheService>((ref) {
  return sl<CacheService>();
});
