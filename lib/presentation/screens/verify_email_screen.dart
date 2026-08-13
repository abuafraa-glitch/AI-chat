import 'package:ai_chat/core/di/injection.dart';
import 'package:ai_chat/core/errors/exceptions.dart';
import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/theme/app_spacing.dart';
import 'package:ai_chat/core/utils/validators.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/buttons/loading_button.dart';
import 'package:ai_chat/core/widgets/inputs/app_text_field.dart';
import 'package:ai_chat/core/widgets/inputs/otp_field.dart';
import 'package:ai_chat/presentation/blocs/auth_controller.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:flutter/material.dart';

/// Email-verification screen.
///
/// Collects the account email and the emailed verification code via the
/// [OtpField] and forwards them to [AuthController.verifyEmail].
class VerifyEmailScreen extends StatefulWidget {
  /// Creates a [VerifyEmailScreen].
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String _code = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _code.length < 4) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await sl<AuthController>().verifyEmail(
        email: _emailController.text.trim(),
        code: _code,
      );
      if (!mounted) {
        return;
      }
      context.showSuccessSnackBar(
        localizedTextRead(
          context,
          'Email verified. You can sign in now.',
          'تم التحقق من البريد. يمكنك تسجيل الدخول الآن.',
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
              'Verification failed. Try again.',
              'فشل التحقق. حاول مرة أخرى.',
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
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(
        title: Text(localizedText(context, 'Verify email', 'تحقق من البريد')),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.all6,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.mark_email_read_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              AppSpacing.gap4,
              Text(
                localizedText(
                  context,
                  'Enter the verification code sent to your email.',
                  'أدخل رمز التحقق المرسل إلى بريدك الإلكتروني.',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              AppSpacing.gap8,
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
              AppSpacing.gap6,
              OtpField(
                length: 6,
                autoFocus: false,
                onCompleted: (code) {
                  setState(() {
                    _code = code;
                  });
                },
              ),
              AppSpacing.gap6,
              LoadingButton(
                text: localizedText(context, 'Verify', 'تحقق'),
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
