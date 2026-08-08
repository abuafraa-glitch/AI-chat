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

/// Forgot-password screen.
///
/// Collects the account email and initiates the recovery flow through
/// [AuthController.forgotPassword].
class ForgotPasswordScreen extends StatefulWidget {
  /// Creates a [ForgotPasswordScreen].
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
      await sl<AuthController>().forgotPassword(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      context.showSnackBar(
        localizedTextRead(
          context,
          'If the account exists, a reset link has been sent.',
          'إذا كان الحساب موجوداً، فقد أُرسلت رسالة إعادة تعيين كلمة المرور.',
        ),
      );
      context.popRoute();
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AppException && error.message.isNotEmpty
          ? error.message
          : localizedTextRead(context, 'Something went wrong. Try again.', 'حدث خطأ ما. حاول مرة أخرى.');
      context.showErrorSnackBar(message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Reset password', 'إعادة تعيين كلمة المرور')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.lock_reset,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                localizedText(
                  context,
                  'Enter your email and we will send you a reset link.',
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _emailController,
                hintText: localizedText(context, 'Email', 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) => Validators.email(value)
                    ? null
                    : localizedTextRead(context, 'Enter a valid email', 'أدخل بريداً إلكترونياً صحيحاً'),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                text: localizedText(context, 'Send Reset Link', 'إرسال رابط إعادة التعيين'),
                onPressed: _submit,
                isLoading: _isLoading,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
