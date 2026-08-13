import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Immutable state for [ThemeCubit].
///
/// Wraps [ThemeMode] so BLoC can detect transitions via object equality
/// without requiring the Equatable package on a framework primitive.
final class ThemeState {
  const ThemeState(this.mode);

  /// The active [ThemeMode].
  final ThemeMode mode;

  /// `true` when [mode] is [ThemeMode.dark].
  bool get isDark => mode == ThemeMode.dark;

  /// `true` when [mode] is [ThemeMode.light].
  bool get isLight => mode == ThemeMode.light;

  /// `true` when [mode] defers to the OS brightness setting.
  bool get isSystem => mode == ThemeMode.system;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          mode == other.mode;

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'ThemeState(mode: $mode)';
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the application theme mode and persists the user's selection
/// to [LocalStorageService].
///
/// The cubit is initialised to [ThemeMode.system] and hydrated from
/// persisted storage via [loadSavedTheme] during the application
/// bootstrap sequence.
///
/// ### Wiring in the root widget
/// ```dart
/// BlocProvider(
///   create: (_) => sl<ThemeCubit>()..loadSavedTheme(),
///   child: BlocBuilder<ThemeCubit, ThemeState>(
///     builder: (context, state) => MaterialApp.router(
///       theme: AppTheme.light,
///       darkTheme: AppTheme.dark,
///       themeMode: state.mode,
///       ...
///     ),
///   ),
/// )
/// ```
///
/// ### Toggling the theme
/// ```dart
/// // Explicit
/// context.read<ThemeCubit>().setDark();
///
/// // Toggle (requires the current platform brightness)
/// final brightness = MediaQuery.platformBrightnessOf(context);
/// context.read<ThemeCubit>().toggle(brightness);
/// ```
final class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required LocalStorageService localStorageService})
    : _storage = localStorageService,
      super(const ThemeState(ThemeMode.system));

  final LocalStorageService _storage;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Loads the previously persisted theme preference from storage and
  /// emits the corresponding [ThemeState].
  ///
  /// Call once during the bootstrap sequence, after the DI container
  /// has resolved this cubit and before the first frame is rendered.
  Future<void> loadSavedTheme() async {
    final raw = _storage.getString(StorageKeys.themeMode);
    final mode = _parseSavedMode(raw);
    emit(ThemeState(mode));
  }

  // ── Theme switching ───────────────────────────────────────────────────────

  /// Switches to the light theme and persists the preference.
  Future<void> setLight() => _applyTheme(ThemeMode.light);

  /// Switches to the dark theme and persists the preference.
  Future<void> setDark() => _applyTheme(ThemeMode.dark);

  /// Defers to the OS brightness setting and persists the preference.
  Future<void> setSystem() => _applyTheme(ThemeMode.system);

  /// Toggles between light and dark based on the current state.
  ///
  /// - If the current mode is explicitly [ThemeMode.light] or
  ///   [ThemeMode.dark], the opposite is applied.
  /// - If the current mode is [ThemeMode.system], [systemBrightness]
  ///   is used to determine the effective current brightness, and the
  ///   opposite is applied. The persisted preference becomes explicit
  ///   (light or dark) after this call, so the app no longer follows
  ///   the OS.
  Future<void> toggle(Brightness systemBrightness) {
    final effectivelyDark =
        state.isDark || (state.isSystem && systemBrightness == Brightness.dark);
    return effectivelyDark ? setLight() : setDark();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _applyTheme(ThemeMode mode) async {
    emit(ThemeState(mode));
    await _storage.setString(StorageKeys.themeMode, mode.name);
  }

  /// Parses the raw [String] value stored by [StorageKeys.themeMode]
  /// back into a [ThemeMode].
  ///
  /// Unrecognised or absent values fall back to [ThemeMode.system],
  /// which is always a safe default.
  static ThemeMode _parseSavedMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
