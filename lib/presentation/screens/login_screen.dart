import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/errors/exceptions.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/routes/route_names.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/utils/validators.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/buttons/loading_button.dart';
import 'package:ai_chat/core/widgets/inputs/app_text_field.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Login screen.
///
/// Collects credentials and forwards them to [AuthController]; on
/// success the router guard redirects to the main shell automatically.
/// The screen performs no business logic — validation and the auth
/// call are the only responsibilities.
class LoginScreen extends StatefulWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await sl<AuthController>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Success: the router re-evaluates the guards and redirects.
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      context.showErrorSnackBar(_errorMessage(context, error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _errorMessage(BuildContext context, Object error) {
    if (error is AppException && error.message.isNotEmpty) {
      return error.message;
    }
    return localizedTextRead(
      context,
      'Sign in failed. Please try again.',
      'فشل تسجيل الدخول. حاول مرة أخرى.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.v6,
          vertical: AppSpacing.v8,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSpacing.gap6,
              Icon(
                Icons.auto_awesome,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              AppSpacing.gap4,
              Text(
                localizedText(context, 'Welcome back', 'مرحباً بعودتك'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              AppSpacing.gap2,
              Text(
                localizedText(
                  context,
                  'Sign in to continue',
                  'سجّل الدخول للمتابعة',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              AppTextField(
                controller: _emailController,
                hintText: localizedText(context, 'Email', 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.email(value)
                    ? null
                    : localizedTextRead(
                        context,
                        'Enter a valid email',
                        'أدخل بريداً إلكترونياً صحيحاً',
                      ),
              ),
              AppSpacing.gap4,
              AppTextField(
                controller: _passwordController,
                hintText: localizedText(context, 'Password', 'كلمة المرور'),
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) => Validators.required(value)
                    ? null
                    : localizedTextRead(
                        context,
                        'Enter your password',
                        'أدخل كلمة المرور',
                      ),
              ),
              AppSpacing.gap6,
              LoadingButton(
                text: localizedText(context, 'Sign In', 'تسجيل الدخول'),
                onPressed: _submit,
                isLoading: _isLoading,
                fullWidth: true,
              ),
              AppSpacing.gap2,
              TextButton(
                onPressed: () {
                  if (!_isLoading) {
                    context.pushTo(RouteNames.forgotPassword);
                  }
                },
                child: Text(
                  localizedText(
                    context,
                    'Forgot password?',
                    'نسيت كلمة المرور؟',
                  ),
                ),
              ),
              AppSpacing.gap6,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    localizedText(context, 'No account yet?', 'ليس لديك حساب؟'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.goToRegister(),
                    child: Text(
                      localizedText(context, 'Create one', 'أنشئ حساباً'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
