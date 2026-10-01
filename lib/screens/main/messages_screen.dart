import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = ApiService.auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        title: 'Messages',
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: ApiService.streamConversations(uid),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final convs = snapshot.data ?? [];
          if (convs.isEmpty) {
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
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('No Active Chats', style: AppTypography.h3),
                  const SizedBox(height: 6),
                  Text('When an order is assigned, you can chat with your rider here.', style: AppTypography.bodySmall),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: convs.length,
            itemBuilder: (ctx, i) {
              final c = convs[i];
              return CardContainer(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'conversationId': c.id,
                      'participantId': c.participantId,
                      'contactName': c.participantName,
                      'orderCode': c.orderId,
                    },
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        c.participantName.isNotEmpty ? c.participantName[0].toUpperCase() : 'R',
                        style: AppTypography.h3.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.participantName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Text(_formatTime(c.lastMessageTime), style: AppTypography.caption),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.lastMessage?.isNotEmpty == true ? c.lastMessage! : 'Tap to start conversation...',
                            style: AppTypography.bodySmall.copyWith(
                              color: c.lastMessage?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  String _formatTime(dynamic timeVal) {
    if (timeVal == null) return '';
    try {
      if (timeVal is String) {
        final d = DateTime.parse(timeVal);
        return DateFormat('h:mm a').format(d);
      }
    } catch (_) {}
    return '';
  }
}
