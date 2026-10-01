import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/orders_provider.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProfileProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    try {
      final file = File(picked.path);
      await context.read<UserProfileProvider>().updateAvatar(file);
      if (mounted) {
        ThemedAlert.show(context, title: 'Profile Updated', message: 'Your avatar has been updated.', type: 'success');
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Upload Failed', message: e.toString(), type: 'error');
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ThemedAlert.show(context, title: 'Invalid Name', message: 'Please enter your name.', type: 'warning');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<UserProfileProvider>().updateDetails(name: name, phone: phone);
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      if (mounted) {
        ThemedAlert.show(context, title: 'Success', message: 'Profile details saved.', type: 'success');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ThemedAlert.show(context, title: 'Error', message: e.toString(), type: 'error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>();
    final ordersProvider = context.watch<OrdersProvider>();
    final user = userProfile.user;

    final totalOrders = ordersProvider.orders.length;
    final activeOrders = ordersProvider.activeOrders.length;
    final completedOrders = ordersProvider.pastOrders.where((o) => o.status == 'delivered').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        title: 'My Profile',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            
            CardContainer(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: ClipOval(
                          child: user?.avatar != null && user!.avatar!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: user.avatar!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (_, __, ___) => _avatarFallback(user.name),
                                )
                              : _avatarFallback(user?.name ?? 'C'),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _handlePickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Customer', style: AppTypography.h2.copyWith(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: AppTypography.bodySmall),
                  const SizedBox(height: 16),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBox('Total Orders', '$totalOrders', const Color(0xFF554A4A)),
                      _statBox('Active', '$activeOrders', const Color(0xFFC7B407)),
                      _statBox('Completed', '$completedOrders', const Color(0xFF4ECDC4)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

          
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Personal Information', style: AppTypography.h3.copyWith(fontSize: 16)),
                      IconButton(
                        icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: AppColors.primary),
                        onPressed: () => setState(() => _isEditing = !_isEditing),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 12),
                  if (!_isEditing) ...[
                    _infoRow(Icons.person_outline_rounded, 'Full Name', user?.name ?? 'Not set'),
                    _infoRow(Icons.email_outlined, 'Email Address', user?.email ?? 'Not set'),
                    _infoRow(Icons.phone_outlined, 'Phone Number', (user != null && user.phone.isNotEmpty) ? user.phone : 'Not set'),
                  ] else ...[
                    CustomInput(
                      label: 'Full Name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomInput(
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomButton(
                      text: 'Save Changes',
                      loading: _isSaving,
                      onPressed: _handleSaveProfile,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            
            CardContainer(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _linkTile(Icons.receipt_outlined, 'My Bills', '/bills', const Color(0xFF10B981)),
                  const Divider(color: AppColors.border, height: 1),
                  _linkTile(Icons.location_on_outlined, 'Saved Delivery Addresses', '/addresses', const Color(0xFF4ECDC4)),
                  const Divider(color: AppColors.border, height: 1),
                  _linkTile(Icons.help_outline_rounded, 'Help & Customer Support', '/help', const Color(0xFFFF8C42)),
                  const Divider(color: AppColors.border, height: 1),
                  _linkTile(Icons.settings_outlined, 'Settings & Preferences', '/settings', const Color(0xFF94A3B8)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

           
            CustomButton(
              text: 'Sign Out',
              outline: true,
              textColor: AppColors.error,
              backgroundColor: AppColors.error,
              icon: Icons.logout_rounded,
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(initial, style: AppTypography.h1.copyWith(color: AppColors.primary)),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.h2.copyWith(color: color, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkTile(IconData icon, String title, String route, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: () => Navigator.of(context).pushNamed(route),
    );
  }
}
