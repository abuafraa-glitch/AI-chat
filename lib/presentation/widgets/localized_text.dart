import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/presentation/blocs/localization_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Resolves a bilingual UI string from the active locale.
///
/// This is the single place where en/ar string pairs are translated;
/// screens and widgets call it instead of re-implementing locale
/// lookups. It is reactive — call it from `build` so the widget
/// rebuilds when the locale changes.
String localizedText(BuildContext context, String en, String ar) {
  final locale = context.watch<LocalizationCubit>().state.locale;
  return locale == AppStrings.localeAr ? ar : en;
}

/// One-shot variant for event handlers and listeners, where a reactive
/// dependency cannot be registered.
String localizedTextRead(BuildContext context, String en, String ar) {
  final locale = context.read<LocalizationCubit>().state.locale;
  return locale == AppStrings.localeAr ? ar : en;
}

/// `true` when the active locale is Arabic (used for RTL direction).
bool isArabicLocale(BuildContext context) {
  return context.watch<LocalizationCubit>().state.locale == AppStrings.localeAr;
}
