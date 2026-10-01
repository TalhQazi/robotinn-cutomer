class UserModel {
  final String id;
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String type;
  final List<String> types;
  final String? avatar;
  final List<dynamic> addresses;
  final bool isBanned;
  final String banReason;
  final String? fcmToken;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    this.type = 'customer',
    this.types = const ['customer'],
    this.avatar,
    this.addresses = const [],
    this.isBanned = false,
    this.banReason = '',
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final id = docId ?? map['id'] ?? map['uid'] ?? map['_id'] ?? '';
    final typesList = map['types'] is List
        ? (map['types'] as List).map((e) => e.toString()).toList()
        : [map['type']?.toString() ?? 'customer'];

    return UserModel(
      id: id,
      uid: map['uid']?.toString() ?? id,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Customer',
      phone: map['phone']?.toString() ?? '',
      type: map['type']?.toString() ?? 'customer',
      types: typesList,
      avatar: map['avatar']?.toString() ?? map['photo']?.toString() ?? map['photoURL']?.toString(),
      addresses: map['addresses'] is List ? map['addresses'] as List : [],
      isBanned: map['isBanned'] == true || map['is_banned'] == true || map['status'] == 'banned',
      banReason: map['banReason']?.toString() ?? map['ban_reason']?.toString() ?? '',
      fcmToken: map['fcmToken']?.toString(),
      createdAt: map['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'type': type,
      'types': types,
      'avatar': avatar,
      'addresses': addresses,
      'isBanned': isBanned,
      'banReason': banReason,
      'fcmToken': fcmToken,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
