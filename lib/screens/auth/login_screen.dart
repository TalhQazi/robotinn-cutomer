import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/notification_unread_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/themed_alert.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }

    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() => _error = null);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(email, password);

    if (success && mounted) {
      final user = auth.user!;
      _onLoginSuccess(user.uid, user.name);
    } else if (mounted) {
      setState(() => _error = auth.error ?? 'Unable to login. Please try again.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _error = null);

   
    final knownAccounts = await ApiService.getKnownGoogleAccounts();
    if (knownAccounts.isNotEmpty && mounted) {
      _showGoogleAccountChooser(knownAccounts);
      return;
    }

    _proceedGoogleSignIn();
  }

  Future<void> _proceedGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (success && mounted) {
      final user = auth.user!;
      _onLoginSuccess(user.uid, user.name);
    } else if (mounted && auth.error != null) {
      setState(() => _error = auth.error);
    }
  }

  void _showGoogleAccountChooser(List<Map<String, dynamic>> accounts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: AppColors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Choose an account', style: AppTypography.h3),
            const SizedBox(height: 4),
            Text('to continue to RobotInn', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            ...accounts.map((acc) {
              final isBanned = acc['isBanned'] == true;
              final email = acc['email'] ?? '';
              final name = acc['name'] ?? email;
              final photo = acc['photo'];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.background,
                  backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
                  child: photo == null ? Text(name[0].toUpperCase()) : null,
                ),
                title: Text(name, style: AppTypography.bodyLarge.copyWith(fontSize: 15)),
                subtitle: Text(email, style: AppTypography.bodySmall),
                trailing: isBanned
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                        child: Text('Banned', style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                      )
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (isBanned) {
                    ThemedAlert.show(
                      context,
                      title: 'Account Suspended',
                      message: acc['banReason'] ?? 'This account has been suspended by an administrator.',
                      type: 'error',
                    );
                  } else {
                    _proceedGoogleSignIn();
                  }
                },
              );
            }),
            const Divider(color: AppColors.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.background,
                child: Icon(Icons.person_add_alt_1_rounded, color: AppColors.textPrimary, size: 20),
              ),
              title: Text('Use another account', style: AppTypography.bodyLarge.copyWith(fontSize: 15)),
              onTap: () {
                Navigator.of(ctx).pop();
                _proceedGoogleSignIn();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onLoginSuccess(String uid, String name) {
    context.read<UserProfileProvider>().loadProfile();
    context.read<OrdersProvider>().startListening(uid);
    context.read<NotificationUnreadProvider>().startListening(uid);
    context.read<CartProvider>().loadCart();

    ThemedAlert.show(
      context,
      title: 'Welcome Back!',
      message: 'Welcome back, $name!',
      type: 'success',
      buttons: [
        AlertButtonConfig(
          text: 'Continue',
          isDefault: true,
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/main');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo1.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.delivery_dining_rounded, size: 40, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Welcome Back', style: AppTypography.h1.copyWith(fontSize: 26)),
                const SizedBox(height: 6),
                Text('Sign in to continue ordering', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
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

                
                CustomInput(
                  label: 'Email Address',
                  hint: 'name@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomInput(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                ),

                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                
                CustomButton(
                  text: 'Sign In',
                  loading: auth.isLoading,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: AppTypography.caption),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.g_mobiledata_rounded, size: 28, color: Color(0xFF4285F4)),
                        const SizedBox(width: 8),
                        Text('Continue with Google', style: AppTypography.button.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

             
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signup');
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
