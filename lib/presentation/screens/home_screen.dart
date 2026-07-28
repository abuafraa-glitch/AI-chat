import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/localization/app_localization.dart';
import '../../providers/localization_provider.dart';
import '../../providers/api_provider.dart';
import '../../providers/storage_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/model_selector.dart';
import '../widgets/suggestion_chips.dart';
import '../widgets/chat_input_field.dart';
import 'chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localizationProvider) == 'ar';
    final isDarkMode = ref.watch(themeProvider);
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      body: Directionality(
        textDirection: textDirection,
        child: SafeArea(
          child: Column(
            children: [
              // Header with Model Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Theme Toggle
                    FadeInLeft(
                      child: IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                    // Hajeen Logo
                    FadeIn(
                      child: Text(
                        '🧠 Hajeen AI',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    // Language Toggle
                    FadeInRight(
                      child: IconButton(
                        icon: Text(isArabic ? '🇺🇸' : '🇸🇦'),
                        onPressed: () {
                          ref.read(localizationProvider.notifier).setLocale(
                            isArabic ? 'en' : 'ar',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Model Selector
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: ModelSelector(
                  onModelSelected: (model) {
                    ref.read(selectedModelProvider.notifier).state = model.id;
                  },
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Welcome Message
                      FadeInUp(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            Strings.welcome,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Suggestion Chips
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: SuggestionChips(
                          onSuggestionSelected: (suggestion) {
                            _startChat(suggestion);
                          },
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Chat Input Field
              FadeInUp(
                child: ChatInputField(
                  onSendMessage: (message) {
                    _startChat(message);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(String message) {
    final selectedModel = ref.read(selectedModelProvider);
    if (selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a model first')),
      );
      return;
    }

    // Navigate to chat screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          initialMessage: message,
          modelId: selectedModel,
        ),
      ),
    );
  }
}
