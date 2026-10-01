import 'dart:math';

class AreaHelper {
  static const Map<String, Map<String, double>> areaCoordinates = {
    // Islamabad Sectors & Commercial Hubs
    'F-5': {'lat': 33.7380, 'lng': 73.0900},
    'F-6': {'lat': 33.7294, 'lng': 73.0747},
    'F-7': {'lat': 33.7215, 'lng': 73.0565},
    'F-8': {'lat': 33.7126, 'lng': 73.0378},
    'F-9': {'lat': 33.7000, 'lng': 73.0200},
    'F-10': {'lat': 33.6920, 'lng': 73.0134},
    'F-11': {'lat': 33.6844, 'lng': 72.9886},
    'F-12': {'lat': 33.6700, 'lng': 72.9600},
    'G-5': {'lat': 33.7250, 'lng': 73.0950},
    'G-6': {'lat': 33.7150, 'lng': 73.0800},
    'G-7': {'lat': 33.7050, 'lng': 73.0600},
    'G-8': {'lat': 33.6950, 'lng': 73.0400},
    'G-9': {'lat': 33.6880, 'lng': 73.0240},
    'G-10': {'lat': 33.6780, 'lng': 73.0040},
    'G-11': {'lat': 33.6680, 'lng': 72.9840},
    'G-12': {'lat': 33.6580, 'lng': 72.9640},
    'G-13': {'lat': 33.6480, 'lng': 72.9440},
    'G-14': {'lat': 33.6380, 'lng': 72.9240},
    'G-15': {'lat': 33.6280, 'lng': 72.9040},
    'I-8': {'lat': 33.6685, 'lng': 73.0750},
    'I-9': {'lat': 33.6550, 'lng': 73.0550},
    'I-10': {'lat': 33.6450, 'lng': 73.0350},
    'I-11': {'lat': 33.6350, 'lng': 73.0150},
    'I-12': {'lat': 33.6250, 'lng': 72.9950},
    'I-14': {'lat': 33.6050, 'lng': 72.9550},
    'E-7': {'lat': 33.7320, 'lng': 73.0520},
    'E-8': {'lat': 33.7220, 'lng': 73.0320},
    'E-9': {'lat': 33.7120, 'lng': 73.0120},
    'E-11': {'lat': 33.6980, 'lng': 72.9750},
    'H-8': {'lat': 33.6800, 'lng': 73.0650},
    'H-9': {'lat': 33.6700, 'lng': 73.0450},
    'H-10': {'lat': 33.6600, 'lng': 73.0250},
    'H-11': {'lat': 33.6500, 'lng': 73.0050},
    'H-12': {'lat': 33.6400, 'lng': 72.9850},
    'Blue Area': {'lat': 33.7120, 'lng': 73.0650},
    'Centaurus': {'lat': 33.7075, 'lng': 73.0515},
    'Bani Gala': {'lat': 33.7050, 'lng': 73.1550},
    'PWD': {'lat': 33.5850, 'lng': 73.1550},
    'Pakistan Town': {'lat': 33.5780, 'lng': 73.1480},
    'Korang Town': {'lat': 33.5900, 'lng': 73.1400},
    'Soan Garden': {'lat': 33.5650, 'lng': 73.1650},
    'Gulberg Residencia': {'lat': 33.5950, 'lng': 73.1950},
    'Gulberg Greens': {'lat': 33.6100, 'lng': 73.1600},
    'DHA Phase 1': {'lat': 33.5250, 'lng': 73.1350},
    'DHA Phase 2': {'lat': 33.5150, 'lng': 73.1750},
    'DHA Phase 3': {'lat': 33.5000, 'lng': 73.1200},
    'DHA Phase 4': {'lat': 33.4900, 'lng': 73.1100},
    'DHA Phase 5': {'lat': 33.5100, 'lng': 73.1900},
    'Bahria Phase 1': {'lat': 33.5650, 'lng': 73.0900},
    'Bahria Phase 2': {'lat': 33.5600, 'lng': 73.0950},
    'Bahria Phase 3': {'lat': 33.5550, 'lng': 73.1000},
    'Bahria Phase 4': {'lat': 33.5500, 'lng': 73.1050},
    'Bahria Phase 5': {'lat': 33.5450, 'lng': 73.1100},
    'Bahria Phase 6': {'lat': 33.5400, 'lng': 73.1120},
    'Bahria Phase 7': {'lat': 33.5350, 'lng': 73.1150},
    'Bahria Phase 8': {'lat': 33.5050, 'lng': 73.0950},
    'Bahria Enclave': {'lat': 33.6900, 'lng': 73.2200},
    'Saddar': {'lat': 33.5980, 'lng': 73.0550},
    'Commercial Market': {'lat': 33.6350, 'lng': 73.0720},
    'Satellite Town': {'lat': 33.6420, 'lng': 73.0750},
    'Chaklala': {'lat': 33.5850, 'lng': 73.0950},
    'Westridge': {'lat': 33.6050, 'lng': 73.0250},
    'Raja Bazar': {'lat': 33.6150, 'lng': 73.0580},
    'Islamabad': {'lat': 33.6844, 'lng': 73.0479},
  };

  static const List<String> allSectors = [
    'F-5', 'F-6', 'F-7', 'F-8', 'F-9', 'F-10', 'F-11', 'F-12',
    'G-5', 'G-6', 'G-7', 'G-8', 'G-9', 'G-10', 'G-11', 'G-12', 'G-13', 'G-14', 'G-15',
    'I-8', 'I-9', 'I-10', 'I-11', 'I-12', 'I-14',
    'E-7', 'E-8', 'E-9', 'E-11',
    'H-8', 'H-9', 'H-10', 'H-11', 'H-12',
    'Blue Area', 'Centaurus', 'PWD', 'Pakistan Town', 'Korang Town', 'Soan Garden',
    'Gulberg', 'DHA Phase 1', 'DHA Phase 2', 'DHA Phase 3', 'DHA Phase 4', 'DHA Phase 5',
    'Bahria Phase 1', 'Bahria Phase 2', 'Bahria Phase 3', 'Bahria Phase 4', 'Bahria Phase 5',
    'Bahria Phase 6', 'Bahria Phase 7', 'Bahria Phase 8', 'Bahria Enclave',
    'Saddar', 'Commercial Market', 'Satellite Town', 'Chaklala', 'Westridge', 'Raja Bazar',
  ];

  static const Map<String, List<String>> sectorAliases = {
    'F-6': ['f-6', 'f6', 'super market', 'kohsar', 'f 6', 'f-6 markaz', 'f6 markaz'],
    'F-7': ['f-7', 'f7', 'jinnah super', 'gol market', 'f 7', 'f-7 markaz', 'f7 markaz'],
    'F-8': ['f-8', 'f8', 'ayub market', 'f 8', 'f-8 markaz', 'f8 markaz'],
    'F-10': ['f-10', 'f10', 'tariq market', 'f 10', 'f-10 markaz', 'f10 markaz'],
    'F-11': ['f-11', 'f11', 'f 11', 'f-11 markaz', 'f11 markaz'],
    'G-6': ['g-6', 'g6', 'melody', 'aabpara', 'g 6', 'g-6 markaz', 'g6 markaz'],
    'G-7': ['g-7', 'g7', 'sitara market', 'g 7', 'g-7 markaz', 'g7 markaz'],
    'G-8': ['g-8', 'g8', 'i&t centre', 'i&t center', 'g 8', 'g-8 markaz', 'g8 markaz'],
    'G-9': ['g-9', 'g9', 'karachi company', 'g 9', 'g-9 markaz', 'g9 markaz'],
    'G-10': ['g-10', 'g10', 'g 10', 'g-10 markaz', 'g10 markaz'],
    'G-11': ['g-11', 'g11', 'g 11', 'g-11 markaz', 'g11 markaz'],
    'G-13': ['g-13', 'g13', 'g 13', 'g-13 markaz', 'g13 markaz'],
    'I-8': ['i-8', 'i8', 'habib market', 'i 8', 'i-8 markaz', 'i8 markaz'],
    'I-9': ['i-9', 'i9', 'i 9', 'i-9 markaz', 'i9 markaz'],
    'I-10': ['i-10', 'i10', 'i 10', 'i-10 markaz', 'i10 markaz'],
    'E-7': ['e-7', 'e7', 'e 7', 'e-7 markaz', 'e7 markaz'],
    'E-11': ['e-11', 'e11', 'mpchs', 'fechs', 'e 11', 'e-11 markaz', 'e11 markaz'],
    'Blue Area': ['blue area', 'jinnah avenue', 'fazl-e-haq'],
  };

  /// Extracts clean sector / area token (e.g. "F-6, Islamabad" -> "F-6")
  static String cleanSectorName(String? areaName) {
    if (areaName == null || areaName.trim().isEmpty) return 'F-6';
    final trimmed = areaName.trim();

    // Check regex pattern for Islamabad sectors like F-6, F 6, f-7, G-9, I-8, E-11, etc.
    final sectorRegex = RegExp(r'\b([A-Ia-i])\s*[-–]?\s*([0-9]{1,2})\b');
    final match = sectorRegex.firstMatch(trimmed);
    if (match != null) {
      final letter = match.group(1)!.toUpperCase();
      final num = match.group(2)!;
      return '$letter-$num';
    }

    // Check known areas
    for (final sec in allSectors) {
      if (trimmed.toLowerCase().contains(sec.toLowerCase())) {
        return sec;
      }
    }

    // Split by comma
    final commaParts = trimmed.split(',');
    if (commaParts.isNotEmpty && commaParts.first.trim().isNotEmpty) {
      return commaParts.first.trim();
    }

    return trimmed;
  }

  static Map<String, double>? resolveAreaCoords(String? areaName) {
    if (areaName == null || areaName.trim().isEmpty) return null;
    final clean = cleanSectorName(areaName).toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    for (final entry in areaCoordinates.entries) {
      final keyNorm = entry.key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (clean == keyNorm || clean.contains(keyNorm) || keyNorm.contains(clean)) {
        return entry.value;
      }
    }
    return {'lat': 33.6844, 'lng': 73.0479}; // Islamabad default
  }

  static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Validates if a store belongs to targetArea (prevents cross-sector pollution)
  static bool isStoreInTargetArea(
    dynamic store,
    String? targetArea, {
    double? targetLat,
    double? targetLng,
  }) {
    if (targetArea == null || targetArea.trim().isEmpty) return true;
    final cleanTarget = cleanSectorName(targetArea);
    final targetLower = cleanTarget.toLowerCase();
    final targetNorm = cleanTarget.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (targetLower == 'islamabad' || targetLower == 'rawalpindi') {
      return true;
    }

    String storeName = '';
    String storeAddress = '';
    String storeArea = '';
    bool isAdminStore = false;
    double? storeLat;
    double? storeLng;

    if (store is Map) {
      storeName = (store['name'] ?? store['storeName'] ?? '').toString().toLowerCase();
      storeAddress = (store['address'] ?? store['vicinity'] ?? store['locationName'] ?? '').toString().toLowerCase();
      storeArea = (store['area'] ?? '').toString();
      isAdminStore = store['isAdminStore'] == true;
      storeLat = double.tryParse(store['lat']?.toString() ?? store['latitude']?.toString() ?? '');
      storeLng = double.tryParse(store['lng']?.toString() ?? store['longitude']?.toString() ?? '');
    } else {
      try {
        storeName = (store.name ?? '').toString().toLowerCase();
        storeAddress = (store.address ?? '').toString().toLowerCase();
        storeArea = (store.area ?? '').toString();
        isAdminStore = store.isAdminStore == true;
        storeLat = store.lat != null ? double.tryParse(store.lat.toString()) : null;
        storeLng = store.lng != null ? double.tryParse(store.lng.toString()) : null;
      } catch (_) {}
    }

    // Admin stores explicitly tied to this area doc belong to it
    if (isAdminStore) return true;

    // Check store.area explicitly
    if (storeArea.isNotEmpty) {
      final storeAreaNorm = storeArea.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (storeAreaNorm == targetNorm || storeAreaNorm.contains(targetNorm) || targetNorm.contains(storeAreaNorm)) {
        return true;
      }
    }

    final fullText = '$storeName $storeAddress';

    // 1. Check known aliases for this target sector
    List<String> targetAliases = [targetLower, targetNorm.toLowerCase()];
    for (final entry in sectorAliases.entries) {
      final secNorm = entry.key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (targetNorm == secNorm || targetLower.contains(entry.key.toLowerCase())) {
        targetAliases.addAll(entry.value);
        break;
      }
    }

    final hasTargetMention = targetAliases.any((alias) => fullText.contains(alias));

    // 2. Reject if conflicting with another sector
    if (targetNorm != 'BLUEAREA' && targetNorm != 'CENTAURUS') {
      if (storeName.contains('beverly centre') ||
          storeName.contains('blue area') ||
          storeName.contains('centaurus') ||
          storeAddress.contains('blue area') ||
          storeAddress.contains('centaurus')) {
        return false;
      }
    }

    for (final otherSec in allSectors) {
      final otherNorm = otherSec.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (otherNorm == targetNorm) continue;

      final otherLower = otherSec.toLowerCase();
      final otherNoHyphen = otherLower.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final otherSpace = otherLower.replaceAll('-', ' ');

      final regex = RegExp(r'\b(' + RegExp.escape(otherLower) + r'|' + RegExp.escape(otherNoHyphen) + r'|' + RegExp.escape(otherSpace) + r')\b', caseSensitive: false);
      if (regex.hasMatch(fullText)) {
        if (!hasTargetMention) {
          return false;
        }
      }
    }

    // 3. If explicit target mention
    if (hasTargetMention) return true;

    // 4. Distance check
    final coords = resolveAreaCoords(cleanTarget);
    final tLat = targetLat ?? coords?['lat'];
    final tLng = targetLng ?? coords?['lng'];

    if (storeLat != null && storeLng != null && tLat != null && tLng != null) {
      final dist = haversineKm(tLat, tLng, storeLat, storeLng);
      final isSector = RegExp(r'^[E-Ie-i]-?[0-9]+').hasMatch(targetNorm);
      final maxRadiusKm = isSector ? 1.5 : 3.0;
      if (dist <= maxRadiusKm) {
        return true;
      }
      return false;
    }

    return false;
  }

  static const Map<String, List<Map<String, dynamic>>> generalBrandStoresByCategory = {
    'pharmacy': [
      {'name': 'Shaheen Chemist', 'rating': 4.9, 'type': 'pharmacy'},
      {'name': 'D.Watson Pharmacy', 'rating': 4.8, 'type': 'pharmacy'},
      {'name': 'Shifa Pharmacy', 'rating': 4.8, 'type': 'pharmacy'},
      {'name': 'Servaid Pharmacy', 'rating': 4.7, 'type': 'pharmacy'},
      {'name': 'Metro Pharmacy', 'rating': 4.6, 'type': 'pharmacy'},
      {'name': 'City Pharmacy & Medical', 'rating': 4.5, 'type': 'pharmacy'},
    ],
    'food': [
      {'name': 'KFC', 'rating': 4.8, 'type': 'food'},
      {'name': "McDonald's", 'rating': 4.8, 'type': 'food'},
      {'name': 'Pizza Hut', 'rating': 4.7, 'type': 'food'},
      {'name': 'Subway', 'rating': 4.7, 'type': 'food'},
      {'name': 'Cheezious', 'rating': 4.9, 'type': 'food'},
      {'name': 'Howdy', 'rating': 4.8, 'type': 'food'},
      {'name': 'Tehzeeb Bakers & Foods', 'rating': 4.9, 'type': 'food'},
      {'name': 'Savour Foods', 'rating': 4.8, 'type': 'food'},
    ],
    'grocery': [
      {'name': 'SaveMart', 'rating': 4.8, 'type': 'grocery'},
      {'name': 'Punjab Cash & Carry', 'rating': 4.7, 'type': 'grocery'},
      {'name': 'Greenvalley Premium Hypermarket', 'rating': 4.9, 'type': 'grocery'},
      {'name': 'Imtiaz Super Market', 'rating': 4.8, 'type': 'grocery'},
      {'name': 'Corner Grocery Store', 'rating': 4.5, 'type': 'grocery'},
    ],
    'bakery': [
      {'name': 'Tehzeeb Bakery', 'rating': 4.9, 'type': 'bakery'},
      {'name': 'Rahat Bakery', 'rating': 4.7, 'type': 'bakery'},
      {'name': 'Layered Bakery', 'rating': 4.8, 'type': 'bakery'},
      {'name': 'Kitchen Cuisine', 'rating': 4.7, 'type': 'bakery'},
    ],
    'meat': [
      {'name': 'Meat One', 'rating': 4.8, 'type': 'meat'},
      {'name': 'Kausar Chicken & Meat', 'rating': 4.6, 'type': 'meat'},
      {'name': 'Fresh Butcher Shop', 'rating': 4.5, 'type': 'meat'},
    ],
    'cosmetics': [
      {'name': 'Scentsation Cosmetics', 'rating': 4.8, 'type': 'cosmetics'},
      {'name': 'Saeed Ghani Beauty Store', 'rating': 4.7, 'type': 'cosmetics'},
      {'name': 'Nivea Beauty Store', 'rating': 4.6, 'type': 'cosmetics'},
      {'name': 'Glamour Cosmetics Shop', 'rating': 4.5, 'type': 'cosmetics'},
    ],
    'stationery': [
      {'name': 'Saeed Book Bank', 'rating': 4.9, 'type': 'stationery'},
      {'name': 'London Book Co', 'rating': 4.7, 'type': 'stationery'},
      {'name': 'Stationery & Copy Corner', 'rating': 4.5, 'type': 'stationery'},
    ],
    'electronics': [
      {'name': 'Mi Official Store', 'rating': 4.8, 'type': 'electronics'},
      {'name': 'Samsung Experience Store', 'rating': 4.8, 'type': 'electronics'},
      {'name': 'Mobile & Computer Zone', 'rating': 4.6, 'type': 'electronics'},
    ],
    'pet_supplies': [
      {'name': 'Pet Care & Supplies Store', 'rating': 4.7, 'type': 'pet_supplies'},
      {'name': 'Vet & Animal Care Center', 'rating': 4.6, 'type': 'pet_supplies'},
    ],
    'dairy': [
      {'name': 'Dairy & Milk Fresh Shop', 'rating': 4.7, 'type': 'dairy'},
    ],
    'fruits': [
      {'name': 'Fresh Fruits & Produce Market', 'rating': 4.7, 'type': 'fruits'},
      {'name': 'Fruit Shop & Fresh Mart', 'rating': 4.6, 'type': 'fruits'},
    ],
    'vegetables': [
      {'name': 'Sabzi & Fresh Veggie Store', 'rating': 4.7, 'type': 'vegetables'},
      {'name': "Farm's Fresh Produce", 'rating': 4.8, 'type': 'vegetables'},
      {'name': 'Bio-Organic & Fresh Vegetables', 'rating': 4.6, 'type': 'vegetables'},
    ],
    'soft_drinks': [
      {'name': 'Beverage & Cold Drink Corner', 'rating': 4.6, 'type': 'soft_drinks'},
    ],
  };

  /// Returns fallback stores for the specific area and category
  static List<Map<String, dynamic>> getFallbackStoresForAreaAndCategory(
    String areaName,
    String categoryName,
  ) {
    final cleanArea = cleanSectorName(areaName);
    final catKey = categoryName.toLowerCase().trim();
    final coords = resolveAreaCoords(cleanArea) ?? {'lat': 33.6844, 'lng': 73.0479};

    String targetKey = 'food';
    if (catKey.contains('pharma') || catKey.contains('health') || catKey.contains('medical') || catKey.contains('chemist') || catKey.contains('medicine')) {
      targetKey = 'pharmacy';
    } else if (catKey.contains('grocer') || catKey.contains('mart') || catKey.contains('supermarket')) {
      targetKey = 'grocery';
    } else if (catKey.contains('baker') || catKey.contains('cake') || catKey.contains('bread') || catKey.contains('sweet')) {
      targetKey = 'bakery';
    } else if (catKey.contains('meat') || catKey.contains('chicken') || catKey.contains('butcher')) {
      targetKey = 'meat';
    } else if (catKey.contains('cosmetic') || catKey.contains('beauty') || catKey.contains('makeup') || catKey.contains('skin')) {
      targetKey = 'cosmetics';
    } else if (catKey.contains('stationery') || catKey.contains('book') || catKey.contains('paper')) {
      targetKey = 'stationery';
    } else if (catKey.contains('electronic') || catKey.contains('mobile') || catKey.contains('tech') || catKey.contains('computer')) {
      targetKey = 'electronics';
    } else if (catKey.contains('pet')) {
      targetKey = 'pet_supplies';
    } else if (catKey.contains('dairy') || catKey.contains('milk')) {
      targetKey = 'dairy';
    } else if (catKey.contains('fruit')) {
      targetKey = 'fruits';
    } else if (catKey.contains('veg') || catKey.contains('sabzi')) {
      targetKey = 'vegetables';
    } else if (catKey.contains('drink') || catKey.contains('soda') || catKey.contains('beverage')) {
      targetKey = 'soft_drinks';
    }

    final baseList = generalBrandStoresByCategory[targetKey] ?? generalBrandStoresByCategory['food']!;

    return List.generate(baseList.length, (idx) {
      final item = baseList[idx];
      final name = item['name'] as String;
      final displayName = name.contains(cleanArea) ? name : '$name ($cleanArea)';
      return {
        'id': 'fallback_${cleanArea.toLowerCase()}_${targetKey}_$idx',
        'placeId': 'fallback_${cleanArea.toLowerCase()}_${targetKey}_$idx',
        'name': displayName,
        'address': '$cleanArea, Islamabad',
        'area': cleanArea,
        'rating': item['rating'] ?? 4.7,
        'type': targetKey,
        'category': targetKey,
        'categoryName': targetKey,
        'lat': coords['lat'],
        'lng': coords['lng'],
        'isGoogleStore': false,
        'isFallbackStore': true,
        'isBackendStore': true,
        'isAdminStore': false,
        'active': true,
      };
    });
  }
}
