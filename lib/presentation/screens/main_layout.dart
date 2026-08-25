import 'package:ai_chat/presentation/blocs/conversations_cubit.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/models_cubit.dart';
import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:go_router/go_router.dart';

/// Main application shell rendered by the router for the four primary tabs.
class MainLayout extends StatefulWidget {
  /// Creates the main shell for [navigationShell].
  const MainLayout({super.key, required this.navigationShell});

  /// go_router navigation shell driving the tab branches.
  final StatefulNavigationShell navigationShell;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    super.initState();
    // MainLayout is created only after the auth guard reports an authenticated
    // session. Reload here so the initial request carries the new token; the
    // singleton's earlier unauthenticated request may have returned 401.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final models = sl<ModelsCubit>();
        if (models.state.models.isEmpty && !models.state.isLoading) {
          models.loadModels();
        }
      }
    });
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<ModelsCubit>.value(value: sl<ModelsCubit>()),
        BlocProvider<ConversationsCubit>(
          create: (context) =>
              ConversationsCubit(repository: buildConversationRepository())
                ..loadConversations(),
        ),
      ],
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
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
