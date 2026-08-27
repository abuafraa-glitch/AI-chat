import 'package:ai_chat/core/constants/app_strings.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/theme/theme_cubit.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/presentation/blocs/localization_cubit.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Application settings tab.
///
/// Purely presentational: it observes [ThemeCubit] and
/// [LocalizationCubit] and forwards user intents — dark mode and
/// language changes, and navigation to other screens — to the cubits
/// and the router. No handlers here are stubbed: every tile performs a
/// real action.
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeCubit>().state.isDark;
    final locale = context.watch<LocalizationCubit>().state.locale;

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Settings', 'الإعدادات')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SettingsSection(
              title: localizedText(
                context,
                'General settings',
                'الإعدادات العامة',
              ),
              children: <Widget>[
                SwitchListTile(
                  secondary: Icon(
                    isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: Text(
                    localizedText(context, 'Dark mode', 'الوضع الداكن'),
                  ),
                  value: isDark,
                  onChanged: (value) {
                    final cubit = context.read<ThemeCubit>();
                    if (value) {
                      cubit.setDark();
                    } else {
                      cubit.setLight();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(localizedText(context, 'Language', 'اللغة')),
                  trailing: DropdownButton<String>(
                    value: locale,
                    underline: const SizedBox(),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: AppStrings.localeEn,
                        child: Text('English'),
                      ),
                      DropdownMenuItem<String>(
                        value: AppStrings.localeAr,
                        child: Text('العربية'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<LocalizationCubit>().setLocale(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: localizedText(context, 'Account', 'الحساب'),
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: localizedText(context, 'Profile', 'الملف الشخصي'),
                  onTap: () => context.goToProfile(),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: localizedText(context, 'Notifications', 'الإشعارات'),
                  onTap: () => context.goToNotifications(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: localizedText(
                context,
                'Subscription & Billing',
                'الاشتراك والفوترة',
              ),
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.card_membership_outlined,
                  title: localizedText(
                    context,
                    'Manage Subscription',
                    'إدارة الاشتراك',
                  ),
                  onTap: () => context.pushTo(RouteNames.subscriptions),
                ),
                _SettingsTile(
                  icon: Icons.receipt_outlined,
                  title: localizedText(
                    context,
                    'Billing / Payment History',
                    'سجل الفواتير/المدفوعات',
                  ),
                  onTap: () => context.pushTo(RouteNames.payments),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('Hajeen AI v1.0.0', style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List<Widget>.generate(
              children.length,
              (index) => Column(
                children: <Widget>[
                  children[index],
                  if (index < children.length - 1) const Divider(height: 1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
