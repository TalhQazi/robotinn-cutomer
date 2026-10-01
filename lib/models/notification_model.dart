class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final Map<String, dynamic>? data;
  final dynamic createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'general',
    this.read = false,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return NotificationModel(
      id: docId ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      read: map['read'] == true,
      data: map['data'] is Map ? Map<String, dynamic>.from(map['data']) : null,
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'data': data,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
