class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? iconUrl;
  final String? emoji;
  final bool active;
  final String? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.iconUrl,
    this.emoji,
    this.active = true,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CategoryModel(
      id: docId ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Category',
      icon: map['icon']?.toString(),
      iconUrl: map['iconUrl']?.toString() ?? (map['icon']?.toString().startsWith('http') == true ? map['icon']?.toString() : null),
      emoji: map['emoji']?.toString() ?? map['icon']?.toString(),
      active: map['active'] != false,
      createdAt: map['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'iconUrl': iconUrl,
      'emoji': emoji,
      'active': active,
      'createdAt': createdAt,
    };
  }
}
