import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'Settings',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: AppTypography.h3.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            CardContainer(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Push Notifications', style: AppTypography.bodyMedium),
                    subtitle: Text('Receive order status updates & messages', style: AppTypography.caption),
                    activeColor: AppColors.primary,
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    title: Text('Order Alert Sounds', style: AppTypography.bodyMedium),
                    subtitle: Text('Play audio alerts when status changes', style: AppTypography.caption),
                    activeColor: AppColors.primary,
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text('Legal & About', style: AppTypography.h3.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            CardContainer(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: Text('Terms of Service', style: AppTypography.bodyMedium),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      ThemedAlert.show(
                        context,
                        title: 'Terms of Service',
                        message: 'RobotInn is an on-demand logistics & delivery platform connecting customers with verified riders.',
                        type: 'info',
                      );
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: Text('Privacy Policy', style: AppTypography.bodyMedium),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      ThemedAlert.show(
                        context,
                        title: 'Privacy Policy',
                        message: 'We protect your data with end-to-end cloud encryption and only share delivery addresses with assigned riders.',
                        type: 'info',
                      );
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: Text('App Version', style: AppTypography.bodyMedium),
                    trailing: Text('1.0.0 (Flutter)', style: AppTypography.bodySmall),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

         
            CardContainer(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text('Sign Out', style: AppTypography.bodyLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
