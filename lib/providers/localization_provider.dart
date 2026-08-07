import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that manages the application UI locale.
///
/// The state is a BCP-47 language code (`en`, `ar`, …) consumed
/// directly by the UI (see `HomeScreen`, `SettingsScreen` and
/// `ChatInputField`). The selected locale is persisted to
/// [LocalStorageService] under [StorageKeys.locale].
final class LocalizationNotifier extends StateNotifier<String> {
  /// Creates a [LocalizationNotifier] backed by [storage].
  ///
  /// The initial state is hydrated synchronously from [storage],
  /// falling back to English when nothing has been persisted yet.
  LocalizationNotifier({required LocalStorageService storage})
      : _storage = storage,
        super(_hydrate(storage));

  /// Storage layer used to persist the locale preference.
  final LocalStorageService _storage;

  /// Sets the active locale to [locale] when it is supported and
  /// persists the result.
  ///
  /// Unsupported locales are ignored so the UI can never enter an
  /// untranslated state.
  Future<void> setLocale(String locale) async {
    if (!AppStrings.supportedLocaleCodes.contains(locale)) {
      return;
    }
    state = locale;
    await _persist();
  }

  /// Persists the current [state] using the canonical [StorageKeys.locale].
  Future<void> _persist() {
    return _storage.setString(StorageKeys.locale, state);
  }

  /// Reads the persisted locale and falls back to English when absent.
  static String _hydrate(LocalStorageService storage) {
    final saved = storage.getString(StorageKeys.locale);
    if (saved != null && AppStrings.supportedLocaleCodes.contains(saved)) {
      return saved;
    }
    return AppStrings.localeEn;
  }
}

/// Riverpod provider exposing the application-wide UI locale.
///
/// ```dart
/// final isArabic = ref.watch(localizationProvider) == 'ar';
/// ref.read(localizationProvider.notifier).setLocale('en');
/// ```
final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, String>((ref) {
  return LocalizationNotifier(storage: ref.watch(localStorageServiceProvider));
});
