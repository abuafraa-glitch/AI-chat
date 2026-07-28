import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/localization/app_localization.dart';
import '../../providers/theme_provider.dart';
import '../../providers/localization_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            FadeInUp(
              child: _SettingsSection(
                title: Strings.account,
                children: [
                  _SettingsTile(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Manage your profile',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'user@example.com',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Appearance Section
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _SettingsSection(
                title: 'Appearance',
                children: [
                  ListTile(
                    leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).setDarkMode(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: locale,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text('العربية'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(localizationProvider.notifier).setLocale(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _SettingsSection(
                title: Strings.notifications,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Enable Notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail),
                    title: const Text('Email Notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy & Security Section
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _SettingsSection(
                title: 'Privacy & Security',
                children: [
                  _SettingsTile(
                    icon: Icons.lock,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Data & Privacy',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subscription Section
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _SettingsSection(
                title: 'Subscription',
                children: [
                  _SettingsTile(
                    icon: Icons.card_membership,
                    title: 'Manage Subscription',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.receipt,
                    title: 'Billing History',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _SettingsSection(
                title: 'Danger Zone',
                children: [
                  _SettingsTile(
                    icon: Icons.delete_forever,
                    title: Strings.deleteAccount,
                    subtitle: 'This action cannot be undone',
                    onTap: () => _showDeleteAccountDialog(context),
                    iconColor: Colors.red,
                  ),
                  _SettingsTile(
                    icon: Icons.logout,
                    title: Strings.logout,
                    onTap: () => _showLogoutDialog(context),
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Version Info
            Center(
              child: Text(
                'Hajeen AI v1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement logout
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: List.generate(
              children.length,
              (index) => Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
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
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
