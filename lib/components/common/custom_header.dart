import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/notification_unread_provider.dart';
import '../../providers/orders_provider.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPress;
  final bool transparent;

  const CustomHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onBackPress,
    this.transparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationUnreadProvider>().unreadCount;

    return AppBar(
      backgroundColor: transparent ? Colors.transparent : AppColors.white,
      elevation: transparent ? 0 : 1,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadow,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
              onPressed: onBackPress ?? () => Navigator.of(context).maybePop(),
            )
          : IconButton(
              icon: const Icon(Icons.menu_rounded, size: 26, color: AppColors.textPrimary),
              onPressed: () => _openDrawer(context),
            ),
      title: title != null
          ? Text(
              title!,
              style: AppTypography.h3.copyWith(fontSize: 19),
            )
          : Image.asset(
              'assets/images/logo1.png',
              height: 38,
              errorBuilder: (_, __, ___) => Text('RobotInn', style: AppTypography.h2.copyWith(color: AppColors.primary)),
            ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 26, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.of(context).pushNamed('/notifications');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Drawer',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const _CustomSideDrawer(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }
}

class _CustomSideDrawer extends StatelessWidget {
  const _CustomSideDrawer();

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>();
    final ordersProvider = context.watch<OrdersProvider>();
    final user = userProfile.user;

    final totalOrders = ordersProvider.orders.length;
    final activeOrders = ordersProvider.activeOrders.length;
    final completedOrders = ordersProvider.pastOrders.where((o) => o.status == 'delivered').length;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.82,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: user?.avatar != null && user!.avatar!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: user.avatar!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (_, __, ___) => _avatarFallback(user.name),
                                )
                              : _avatarFallback(user?.name ?? 'Customer'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Customer',
                              style: AppTypography.h3.copyWith(fontSize: 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

               
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Total', '$totalOrders', const Color(0xFF554A4A)),
                        _statItem('Active', '$activeOrders', const Color(0xFFC7B407)),
                        _statItem('Completed', '$completedOrders', const Color(0xFF4ECDC4)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),

               
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    children: [
                      _menuTile(
                        context,
                        icon: Icons.person_outline_rounded,
                        label: 'My Profile',
                        subtitle: 'Manage your profile details',
                        color: const Color(0xFFFF6B6B),
                        iconBg: const Color(0xFFFFF0F0),
                        route: '/profile',
                      ),
                      _menuTile(
                        context,
                        icon: Icons.receipt_outlined,
                        label: 'My Bills',
                        subtitle: 'View and pay your bills',
                        color: const Color(0xFF10B981),
                        iconBg: const Color(0xFFECFDF5),
                        route: '/bills',
                      ),
                      _menuTile(
                        context,
                        icon: Icons.location_on_outlined,
                        label: 'Saved Addresses',
                        subtitle: 'Manage your delivery locations',
                        color: const Color(0xFF4ECDC4),
                        iconBg: const Color(0xFFE8FAF8),
                        route: '/addresses',
                      ),
                      _menuTile(
                        context,
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        subtitle: 'View all notifications',
                        color: const Color(0xFFA78BFA),
                        iconBg: const Color(0xFFF3EEFF),
                        route: '/notifications',
                      ),
                      _menuTile(
                        context,
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Messages',
                        subtitle: 'Chat with support & riders',
                        color: const Color(0xFF60A5FA),
                        iconBg: const Color(0xFFEBF4FF),
                        route: '/messages',
                      ),
                      _menuTile(
                        context,
                        icon: Icons.help_outline_rounded,
                        label: 'Help Center',
                        subtitle: 'FAQs & customer support',
                        color: const Color(0xFFFF8C42),
                        iconBg: const Color(0xFFFFF5EB),
                        route: '/help',
                      ),
                      _menuTile(
                        context,
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        subtitle: 'Manage app preferences',
                        color: const Color(0xFF94A3B8),
                        iconBg: const Color(0xFFF0F2F5),
                        route: '/settings',
                      ),
                    ],
                  ),
                ),

               
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InkWell(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await context.read<AuthProvider>().logout();
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text('Log Out', style: AppTypography.button.copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.h2.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.h3.copyWith(color: color, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color iconBg,
    required String route,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      },
    );
  }
}
