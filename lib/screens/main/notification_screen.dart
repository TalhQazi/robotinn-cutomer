import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = ApiService.auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        showBackButton: true,
        title: 'Notifications',
      ),
      body: Column(
        children: [
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            color: AppColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => ApiService.markAllNotificationsAsRead(uid),
                  child: Text('Mark all as read', style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: ApiService.streamNotifications(uid),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('No Notifications', style: AppTypography.h3),
                        const SizedBox(height: 6),
                        Text('You\'re all caught up! Updates about your orders will appear here.', style: AppTypography.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final n = list[i];
                    return CardContainer(
                      color: n.read ? AppColors.white : const Color(0xFFF0FDF4),
                      border: n.read ? null : Border.all(color: AppColors.primary.withOpacity(0.3)),
                      onTap: () {
                        ApiService.markNotificationAsRead(n.id);
                        if (n.data?['orderId'] != null) {
                          Navigator.of(context).pushNamed(
                            '/order-details',
                            arguments: {'orderId': n.data!['orderId']},
                          );
                        } else if (n.data?['conversationId'] != null) {
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: {
                              'conversationId': n.data!['conversationId'],
                              'participantId': n.data!['senderId'] ?? '',
                            },
                          );
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getIconColor(n.type).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIcon(n.type), color: _getIconColor(n.type), size: 22),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: n.read ? FontWeight.w600 : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(_formatTime(n.createdAt), style: AppTypography.caption),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.message,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: n.read ? AppColors.textSecondary : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.delivery_dining_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'bill':
      case 'bill_dispute':
        return Icons.receipt_long_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppColors.primary;
      case 'chat':
        return const Color(0xFF60A5FA);
      case 'bill_dispute':
        return AppColors.error;
      default:
        return const Color(0xFFA78BFA);
    }
  }

  String _formatTime(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      if (dateVal is String) {
        final d = DateTime.parse(dateVal);
        return DateFormat('MMM d, h:mm a').format(d);
      }
    } catch (_) {}
    return '';
  }
}
