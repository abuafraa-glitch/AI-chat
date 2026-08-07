import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that manages the application theme mode.
///
/// The state is a plain `bool` — `true` for dark mode, `false` for
/// light mode — which mirrors how the UI consumes it (see
/// `HomeScreen` and `SettingsScreen`). The selected mode is persisted
/// to [LocalStorageService] under [StorageKeys.themeMode] so the
/// preference survives application restarts.
final class ThemeNotifier extends StateNotifier<bool> {
  /// Creates a [ThemeNotifier] backed by [storage].
  ///
  /// The initial state is hydrated synchronously from [storage] so the
  /// correct theme is applied on the very first frame.
  ThemeNotifier({required LocalStorageService storage})
      : _storage = storage,
        super(_hydrate(storage));

  /// Storage layer used to persist the theme preference.
  final LocalStorageService _storage;

  /// Toggles between light and dark mode and persists the result.
  Future<void> toggleTheme() async {
    state = !state;
    await _persist();
  }

  /// Sets dark mode to [value] and persists the result.
  Future<void> setDarkMode(bool value) async {
    state = value;
    await _persist();
  }

  /// Persists the current [state] using the canonical [StorageKeys.themeMode].
  Future<void> _persist() {
    return _storage.setString(
      StorageKeys.themeMode,
      state ? AppStrings.themeModeDark : AppStrings.themeModeLight,
    );
  }

  /// Reads the persisted theme mode and maps it to a `bool`.
  static bool _hydrate(LocalStorageService storage) {
    return storage.getString(StorageKeys.themeMode) == AppStrings.themeModeDark;
  }
}

/// Riverpod provider exposing the application-wide theme mode.
///
/// ```dart
/// final isDarkMode = ref.watch(themeProvider);
/// ref.read(themeProvider.notifier).toggleTheme();
/// ```
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier(storage: ref.watch(localStorageServiceProvider));
});
