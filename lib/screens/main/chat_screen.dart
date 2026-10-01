import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String participantId;
  final String contactName;
  final String? orderCode;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.participantId,
    this.contactName = 'Rider',
    this.orderCode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;
  String? _riderPhone;

  @override
  void initState() {
    super.initState();
    _fetchRiderInfo();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiderInfo() async {
    try {
      final doc = await ApiService.firestore.collection('users').doc(widget.participantId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _riderPhone = doc.data()!['phone']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      await ApiService.sendMessage(conversationId: widget.conversationId, text: text);
    } catch (_) {} finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _handlePickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isSending = true);

    try {
      final file = File(picked.path);
      await ApiService.sendMediaMessage(
        conversationId: widget.conversationId,
        file: file,
        fileName: 'chat_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } catch (_) {} finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _callRider() async {
    if (_riderPhone != null && _riderPhone!.isNotEmpty) {
      final uri = Uri.parse('tel:$_riderPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      Navigator.of(context).pushNamed(
        '/calling',
        arguments: {'name': widget.contactName, 'orderCode': widget.orderCode},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ApiService.auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        shadowColor: AppColors.shadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'R',
                style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contactName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (widget.orderCode != null)
                    Text('Order #${widget.orderCode}', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
            onPressed: _callRider,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: ApiService.streamMessages(widget.conversationId, uid),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text('No messages yet', style: AppTypography.bodySmall),
                        Text('Send a message to coordinate with your rider.', style: AppTypography.caption),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),

          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                    onPressed: () => _handlePickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                    onPressed: () => _handlePickImage(ImageSource.gallery),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _isSending ? null : _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final isMe = msg.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: msg.mediaUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                ),
              ),
              if (msg.text.isNotEmpty) const SizedBox(height: 6),
            ],
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
