import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/services/local_storage_service.dart';
import 'package:ai_chat/core/theme/theme_cubit.dart';
import 'package:ai_chat/presentation/blocs/conversations_cubit.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/localization_cubit.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/blocs/subscriptions_cubit.dart';
import 'package:ai_chat/presentation/screens/conversations_screen.dart';
import 'package:ai_chat/presentation/screens/home_screen.dart';
import 'package:ai_chat/presentation/screens/settings_screen.dart';
import 'package:ai_chat/presentation/screens/subscription_screen.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main application shell hosting the four primary tabs.
///
/// This widget is the composition root of the presentation layer: it
/// provides the shared application cubits — theme, locale, AI model
/// catalogue, conversations and subscriptions — to the whole tab tree,
/// and renders the selected tab inside an [IndexedStack] so tab state
/// is preserved across switches.
///
/// Every dependency is resolved from the DI container (`sl`) or built
/// through [buildRemoteDataSource] / [buildLocalDataSource]; no widget
/// below this point talks to the network or storage directly.
class MainLayout extends StatefulWidget {
  /// Creates the [MainLayout] shell.
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProviderSingleChildWidget>[
        BlocProvider<ThemeCubit>(
          create: (context) => sl<ThemeCubit>()..loadSavedTheme(),
        ),
        BlocProvider<LocalizationCubit>(
          create: (context) =>
              LocalizationCubit(storage: sl<LocalStorageService>()),
        ),
        BlocProvider<ModelsCubit>(
          create: (context) => ModelsCubit(
            remoteDataSource: buildRemoteDataSource(),
            localDataSource: buildLocalDataSource(),
          )..loadModels(),
        ),
        BlocProvider<ConversationsCubit>(
          create: (context) => ConversationsCubit(
            remoteDataSource: buildRemoteDataSource(),
            localDataSource: buildLocalDataSource(),
          )..loadConversations(),
        ),
        BlocProvider<SubscriptionsCubit>(
          create: (context) => SubscriptionsCubit(
            remoteDataSource: buildRemoteDataSource(),
            localDataSource: buildLocalDataSource(),
          )..load(),
        ),
      ],
      child: _MainShell(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const List<Widget> _tabs = <Widget>[
    HomeScreen(),
    ConversationsScreen(),
    SubscriptionScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTabSelected,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: localizedText(context, 'Home', 'الرئيسية'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: localizedText(context, 'Chats', 'المحادثات'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.card_membership_outlined),
            selectedIcon: const Icon(Icons.card_membership),
            label: localizedText(context, 'Plans', 'الخطط'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: localizedText(context, 'Settings', 'الإعدادات'),
          ),
        ],
      ),
    );
  }
}
