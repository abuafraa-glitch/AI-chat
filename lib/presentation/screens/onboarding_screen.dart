import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/theme/app_radius.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// First-launch onboarding flow.
///
/// Purely presentational: three intro slides, a progress indicator and
/// a final "Get started" action that marks onboarding as completed
/// through [AuthController] and routes to the login screen.
class OnboardingScreen extends StatefulWidget {
  /// Creates an [OnboardingScreen].
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    _finish();
  }

  Future<void> _finish() async {
    await sl<AuthController>().markOnboardingCompleted();
    if (!mounted) {
      return;
    }
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.v2),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(localizedText(context, 'Skip', 'تخطي')),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: AppSpacing.h8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: AppRadius.xxl,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 60,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          localizedText(context, slide.titleEn, slide.titleAr),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        AppSpacing.gap4,
                        Text(
                          localizedText(context, slide.bodyEn, slide.bodyAr),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_slides.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: AppSpacing.h1,
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: AppRadius.xs,
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.v6),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _currentPage == _slides.length - 1
                        ? localizedText(context, 'Get Started', 'ابدأ الآن')
                        : localizedText(context, 'Next', 'التالي'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    const _OnboardingSlide(
      icon: Icons.smart_toy_outlined,
      titleEn: 'Chat with the best AI models',
      titleAr: 'تحدث مع أفضل نماذج الذكاء الاصطناعي',
      bodyEn:
          'One app, many models — OpenAI, Claude, Gemini and more, with real-time streaming replies.',
      bodyAr:
          'تطبيق واحد، نماذج متعددة — OpenAI وClaude وGemini وغيرها، مع ردود بثّ مباشر.',
    ),
    const _OnboardingSlide(
      icon: Icons.history_rounded,
      titleEn: 'Your conversations, everywhere',
      titleAr: 'محادثاتك في كل مكان',
      bodyEn:
          'Every chat is saved automatically and synchronised across your devices.',
      bodyAr: 'كل محادثة تُحفظ تلقائياً وتُتزامن عبر أجهزتك.',
    ),
    const _OnboardingSlide(
      icon: Icons.workspace_premium_outlined,
      titleEn: 'Unlock powerful features',
      titleAr: 'افتح ميزات قوية',
      bodyEn:
          'Subscriptions, file uploads, search, notifications and agents — all in one place.',
      bodyAr:
          'الاشتراكات، رفع الملفات، البحث، الإشعارات والوكلاء — كل ذلك في مكان واحد.',
    ),
  ];
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });

  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
}
