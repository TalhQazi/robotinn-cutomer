class StoreModel {
  final String id;
  final String name;
  final String? type;
  final String? category;
  final String? categoryId;
  final String? address;
  final String? area;
  final double? rating;
  final int? userRatingsTotal;
  final String? icon;
  final String? logo;
  final bool active;
  final bool isBackendStore;
  final bool isAdminStore;
  final bool isGoogleStore;
  final bool isFallbackStore;
  final double? lat;
  final double? lng;
  final String? placeId;
  final bool? isOpen;
  final String? openingHours;
  final List<String>? supportedCategories;

  StoreModel({
    required this.id,
    required this.name,
    this.type = 'Store',
    this.category,
    this.categoryId,
    this.address,
    this.area,
    this.rating = 4.8,
    this.userRatingsTotal,
    this.icon,
    this.logo,
    this.active = true,
    this.isBackendStore = true,
    this.isAdminStore = true,
    this.isGoogleStore = false,
    this.isFallbackStore = false,
    this.lat,
    this.lng,
    this.placeId,
    this.isOpen,
    this.openingHours,
    this.supportedCategories,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    double? ratingVal;
    if (map['rating'] != null) {
      ratingVal = double.tryParse(map['rating'].toString());
    }

    double? latVal;
    if (map['lat'] != null || map['latitude'] != null) {
      latVal = double.tryParse((map['lat'] ?? map['latitude']).toString());
    }

    double? lngVal;
    if (map['lng'] != null || map['longitude'] != null) {
      lngVal = double.tryParse((map['lng'] ?? map['longitude']).toString());
    }

    List<String>? suppList;
    final rawSupp = map['supportedCategories'] ?? map['types'];
    if (rawSupp is List) {
      suppList = rawSupp.map((e) => e.toString()).toList();
    }

    return StoreModel(
      id: docId ?? map['id']?.toString() ?? map['placeId']?.toString() ?? map['place_id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['storeName']?.toString() ?? 'Store',
      type: map['type']?.toString() ?? 'Store',
      category: map['category']?.toString() ?? map['type']?.toString(),
      categoryId: map['categoryId']?.toString() ?? map['category_id']?.toString(),
      address: map['address']?.toString() ?? map['locationName']?.toString() ?? map['vicinity']?.toString(),
      area: map['area']?.toString(),
      rating: ratingVal ?? 4.8,
      userRatingsTotal: int.tryParse(map['userRatingsTotal']?.toString() ?? map['userRatingCount']?.toString() ?? ''),
      icon: map['icon']?.toString(),
      logo: map['logo']?.toString(),
      active: map['active'] != false,
      isBackendStore: map['isBackendStore'] != false,
      isAdminStore: map['isAdminStore'] == true,
      isGoogleStore: map['isGoogleStore'] == true,
      isFallbackStore: map['isFallbackStore'] == true,
      lat: latVal,
      lng: lngVal,
      placeId: map['placeId']?.toString() ?? map['place_id']?.toString(),
      isOpen: map['isOpen'] is bool ? map['isOpen'] as bool : null,
      openingHours: map['openingHours']?.toString(),
      supportedCategories: suppList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'categoryId': categoryId,
      'address': address,
      'area': area,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'icon': icon,
      'logo': logo,
      'active': active,
      'isBackendStore': isBackendStore,
      'isAdminStore': isAdminStore,
      'isGoogleStore': isGoogleStore,
      'isFallbackStore': isFallbackStore,
      'lat': lat,
      'lng': lng,
      'placeId': placeId,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'supportedCategories': supportedCategories,
    };
  }
}
