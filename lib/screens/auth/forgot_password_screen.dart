import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/themed_alert.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  int _step = 1; 
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }

    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.sendOTPCode(email);
      setState(() {
        _loading = false;
        _step = 2;
      });
      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Code Sent',
          message: 'A 6-digit verification code has been sent to $email.',
          type: 'success',
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  void _handleVerifyCode() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit verification code.');
      return;
    }

    Navigator.of(context).pushNamed(
      '/create-new-password',
      arguments: {
        'email': _emailController.text.trim(),
        'code': code,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _step == 1 ? 'Forgot Password?' : 'Enter Verification Code',
                style: AppTypography.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 1
                    ? 'Enter your registered email address to receive a password reset code.'
                    : 'We sent a 6-digit code to ${_emailController.text.trim()}.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_step == 1) ...[
                CustomInput(
                  label: 'Email Address',
                  hint: 'name@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  text: 'Send Verification Code',
                  loading: _loading,
                  onPressed: _handleSendCode,
                ),
              ] else ...[
                CustomInput(
                  label: '6-Digit Code',
                  hint: '123456',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.security_rounded,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  text: 'Verify Code',
                  onPressed: _handleVerifyCode,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _handleSendCode,
                    child: Text('Resend Code', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
