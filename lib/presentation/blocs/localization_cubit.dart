import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/core/constants/storage_keys.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state for the active UI locale.
///
/// The value is a BCP-47 language code (`en`, `ar`, …) consumed
/// directly by the presentation layer.
final class LocalizationState extends Equatable {
  /// Creates a [LocalizationState] for [locale].
  const LocalizationState({required this.locale});

  /// Active BCP-47 language code.
  final String locale;

  /// Returns a copy with [locale] replaced.
  LocalizationState copyWith({String? locale}) {
    return LocalizationState(locale: locale ?? this.locale);
  }

  @override
  List<Object?> get props => <Object?>[locale];
}

/// Manages the application UI locale.
///
/// The initial locale is hydrated from [LocalStorageService] and every
/// change is persisted under [StorageKeys.locale] so the preference
/// survives restarts. Unsupported locales are rejected so the UI can
/// never enter an untranslated state.
final class LocalizationCubit extends Cubit<LocalizationState> {
  /// Creates a [LocalizationCubit] backed by [storage].
  LocalizationCubit({required LocalStorageService storage})
      : _storage = storage,
        super(LocalizationState(locale: _hydrate(storage)));

  /// Storage layer used to persist the locale preference.
  final LocalStorageService _storage;

  /// Sets the active locale to [locale] when it is supported and
  /// persists the result.
  Future<void> setLocale(String locale) async {
    if (!AppStrings.supportedLocaleCodes.contains(locale)) {
      return;
    }
    emit(LocalizationState(locale: locale));
    await _persist();
  }

  /// Persists the current locale using [StorageKeys.locale].
  Future<void> _persist() {
    return _storage.setString(StorageKeys.locale, state.locale);
  }

  /// Reads the persisted locale, falling back to English when absent.
  static String _hydrate(LocalStorageService storage) {
    final saved = storage.getString(StorageKeys.locale);
    if (saved != null && AppStrings.supportedLocaleCodes.contains(saved)) {
      return saved;
    }
    return AppStrings.localeEn;
  }
}
