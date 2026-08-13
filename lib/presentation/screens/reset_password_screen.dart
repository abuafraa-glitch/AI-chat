import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/errors/exceptions.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/utils/validators.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/buttons/loading_button.dart';
import 'package:ai_chat/core/widgets/inputs/app_text_field.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Reset-password screen.
///
/// Collects the email, the emailed reset token and the new password,
/// then completes the flow through [AuthController.resetPassword].
class ResetPasswordScreen extends StatefulWidget {
  /// Creates a [ResetPasswordScreen].
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
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
      await sl<AuthController>().resetPassword(
        email: _emailController.text.trim(),
        token: _tokenController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      context.showSuccessSnackBar(
        localizedTextRead(
          context,
          'Password updated. Please sign in.',
          'تم تحديث كلمة المرور. سجّل الدخول الآن.',
        ),
      );
      context.goToLogin();
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AppException && error.message.isNotEmpty
          ? error.message
          : localizedTextRead(
              context,
              'Could not reset the password.',
              'تعذّرت إعادة تعيين كلمة المرور.',
            );
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
    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'New password', 'كلمة مرور جديدة')),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.all6,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                controller: _tokenController,
                hintText: localizedText(
                  context,
                  'Reset token',
                  'رمز إعادة التعيين',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(value)
                    ? null
                    : localizedTextRead(
                        context,
                        'Enter the reset token',
                        'أدخل رمز إعادة التعيين',
                      ),
              ),
              AppSpacing.gap4,
              AppTextField(
                controller: _passwordController,
                hintText: localizedText(
                  context,
                  'New password',
                  'كلمة المرور الجديدة',
                ),
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.minLength(value, 6)
                    ? null
                    : localizedTextRead(
                        context,
                        'At least 6 characters',
                        '6 أحرف على الأقل',
                      ),
              ),
              AppSpacing.gap4,
              AppTextField(
                controller: _confirmController,
                hintText: localizedText(
                  context,
                  'Confirm password',
                  'تأكيد كلمة المرور',
                ),
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) =>
                    value == _passwordController.text &&
                        Validators.required(value)
                    ? null
                    : localizedTextRead(
                        context,
                        'Passwords do not match',
                        'كلمتا المرور غير متطابقتين',
                      ),
              ),
              AppSpacing.gap6,
              LoadingButton(
                text: localizedText(
                  context,
                  'Update Password',
                  'تحديث كلمة المرور',
                ),
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
