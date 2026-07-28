import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localizationProvider = StateNotifierProvider<LocalizationNotifier, String>((ref) {
  return LocalizationNotifier();
});

class LocalizationNotifier extends StateNotifier<String> {
  LocalizationNotifier() : super('en') {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('locale') ?? 'en';
    state = locale;
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    state = locale;
    await prefs.setString('locale', locale);
  }

  bool get isArabic => state == 'ar';
  bool get isEnglish => state == 'en';
}
