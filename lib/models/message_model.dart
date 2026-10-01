class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaName;
  final bool isMe;
  final String? time;
  final bool read;
  final dynamic createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
    this.isMe = false,
    this.time,
    this.read = false,
    this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId, String? currentUserId}) {
    final sender = map['senderId']?.toString() ?? '';
    final isMine = currentUserId != null && sender == currentUserId;

    return MessageModel(
      id: docId ?? map['id']?.toString() ?? '',
      senderId: sender,
      text: map['text']?.toString() ?? '',
      mediaUrl: map['mediaUrl']?.toString(),
      mediaType: map['mediaType']?.toString(),
      mediaName: map['mediaName']?.toString(),
      isMe: isMine,
      time: map['time']?.toString(),
      read: map['read'] == true,
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'mediaName': mediaName,
      'read': read,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final String? orderId;
  final String participantId;
  final String participantName;
  final String participantType;
  final String? lastMessage;
  final dynamic lastMessageTime;
  final dynamic createdAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.orderId,
    required this.participantId,
    this.participantName = 'Rider',
    this.participantType = 'rider',
    this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, {required String docId, required String currentUserId}) {
    final rawParts = map['participants'] is List ? (map['participants'] as List).map((e) => e.toString()).toList() : <String>[];
    final otherParticipant = rawParts.firstWhere((p) => p != currentUserId, orElse: () => '');
    final lastMsg = map['lastMessage'] is Map ? map['lastMessage']['text']?.toString() : map['lastMessage']?.toString();
    final lastMsgTime = map['lastMessage'] is Map ? map['lastMessage']['createdAt'] : map['lastMessageTime'];

    return ConversationModel(
      id: docId,
      participants: rawParts,
      orderId: map['orderId']?.toString(),
      participantId: otherParticipant,
      participantName: map['participantName']?.toString() ?? 'Rider',
      participantType: map['participantType']?.toString() ?? 'rider',
      lastMessage: lastMsg,
      lastMessageTime: lastMsgTime,
      createdAt: map['createdAt'],
    );
  }
}
