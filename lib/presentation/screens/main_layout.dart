import 'package:ai_chat/presentation/blocs/conversations_cubit.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/presentation/blocs/subscriptions_cubit.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nested/nested.dart';

/// Main application shell rendered by the router for the four primary
/// tabs.
///
/// This widget is the composition root of the tab tree: it provides the
/// shared feature cubits — AI model catalogue, conversations and
/// subscriptions — to the whole branch tree, and switches branches
/// through the [StatefulNavigationShell] handed in by go_router so tab
/// state is preserved across switches.
///
/// Theme and locale cubits are provided at the application root, not
/// here, so every route (including pushed pages above the shell) can
/// react to them. Every dependency is resolved from the DI container;
/// no widget below this point talks to the network or storage directly.
class MainLayout extends StatelessWidget {
  /// Creates the [MainLayout] shell for [navigationShell].
  const MainLayout({super.key, required this.navigationShell});

  /// go_router navigation shell driving the tab branches.
  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<ModelsCubit>(
          create: (context) =>
              ModelsCubit(repository: buildAIRepository())..loadModels(),
        ),
        BlocProvider<ConversationsCubit>(
          create: (context) =>
              ConversationsCubit(repository: buildConversationRepository())
                ..loadConversations(),
        ),
        BlocProvider<SubscriptionsCubit>(
          create: (context) =>
              SubscriptionsCubit(repository: buildSubscriptionRepository())
                ..load(),
        ),
      ],
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: localizedText(context, 'Chat', 'المحادثات'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: localizedText(context, 'Models', 'النماذج'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: localizedText(context, 'Profile', 'الملف'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: localizedText(context, 'Settings', 'الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}
