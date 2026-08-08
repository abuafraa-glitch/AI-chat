import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/errors/exceptions.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/utils/validators.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/buttons/loading_button.dart';
import 'package:ai_chat/core/widgets/inputs/app_text_field.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Registration screen.
///
/// Collects the account details and forwards them to
/// [AuthController.signUp]; on success the router redirects to the
/// main shell. No business logic lives in this widget.
class RegisterScreen extends StatefulWidget {
  /// Creates a [RegisterScreen].
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      await sl<AuthController>().signUp(
        name: _nameController.text.trim(),
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
    return localizedTextRead(context, 'Registration failed. Please try again.', 'فشل التسجيل. حاول مرة أخرى.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Create account', 'إنشاء حساب')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                controller: _nameController,
                hintText: localizedText(context, 'Full name', 'الاسم الكامل'),
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.minLength(value, 2)
                    ? null
                    : localizedTextRead(context, 'Enter your name', 'أدخل اسمك'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                hintText: localizedText(context, 'Email', 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.email(value)
                    ? null
                    : localizedTextRead(context, 'Enter a valid email', 'أدخل بريداً إلكترونياً صحيحاً'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                hintText: localizedText(context, 'Password', 'كلمة المرور'),
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.minLength(value, 6)
                    ? null
                    : localizedTextRead(context, 'At least 6 characters', '6 أحرف على الأقل'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmController,
                hintText: localizedText(context, 'Confirm password', 'تأكيد كلمة المرور'),
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) =>
                    value == _passwordController.text && Validators.required(value)
                        ? null
                        : localizedTextRead(context, 'Passwords do not match', 'كلمتا المرور غير متطابقتين'),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                text: localizedText(context, 'Create Account', 'إنشاء الحساب'),
                onPressed: _submit,
                isLoading: _isLoading,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    localizedText(context, 'Already have an account?', 'لديك حساب بالفعل؟'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.goToLogin(),
                    child: Text(
                      localizedText(context, 'Sign in', 'تسجيل الدخول'),
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
