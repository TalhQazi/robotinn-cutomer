import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/store_model.dart';
import '../constants/app_constants.dart';
import '../utils/category_matcher.dart';
import '../utils/area_helper.dart';

class StoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<StoreModel>> _googleCache = {};

  /// Normalizes category search keyword for Google Places
  static String _getGoogleSearchKeyword(String cleanCat) {
    final lower = cleanCat.toLowerCase();
    if (lower.contains('grocer') || lower.contains('mart')) {
      return 'grocery supermarket store mart';
    } else if (lower.contains('food') || lower.contains('restaur')) {
      return 'restaurant fast food eatery cafe';
    } else if (lower.contains('vegetable') || lower.contains('sabzi')) {
      return 'vegetables sabzi fresh produce';
    } else if (lower.contains('fruit')) {
      return 'fresh fruits produce market';
    } else if (lower.contains('baker') || lower.contains('cake')) {
      return 'bakery sweets cakes bread';
    } else if (lower.contains('pharma') || lower.contains('medic')) {
      return 'pharmacy medical chemist store';
    } else if (lower.contains('meat') || lower.contains('butcher')) {
      return 'meat butcher chicken shop';
    } else if (lower.contains('cosmetic') || lower.contains('beauty')) {
      return 'cosmetics beauty makeup store';
    } else if (lower.contains('stationery') || lower.contains('book')) {
      return 'stationery books book shop';
    } else if (lower.contains('electronic') || lower.contains('mobile')) {
      return 'electronics mobile phones shop';
    }
    return cleanCat;
  }

  /// Fetches Google Places (New) stores matching category and area
  static Future<List<StoreModel>> fetchNearbyStoresFromGoogle({
    required String areaName,
    required String categoryName,
    double? userLat,
    double? userLng,
  }) async {
    final cleanArea = AreaHelper.cleanSectorName(areaName);
    final cleanCat = CategoryMatcher.cleanCategory(categoryName);
    final cacheKey = '${cleanCat.toLowerCase()}_${cleanArea.toLowerCase()}';

    if (_googleCache.containsKey(cacheKey) && _googleCache[cacheKey]!.isNotEmpty) {
      return _googleCache[cacheKey]!;
    }

    double targetLat = userLat ?? 0;
    double targetLng = userLng ?? 0;

    final resolved = AreaHelper.resolveAreaCoords(cleanArea);
    if (resolved != null) {
      targetLat = resolved['lat']!;
      targetLng = resolved['lng']!;
    } else if (targetLat == 0 || targetLng == 0) {
      targetLat = 33.6844;
      targetLng = 73.0479;
    }

    final isSector = RegExp(r'^[E-Ie-i]-?[0-9]+').hasMatch(cleanArea.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''));
    final radius = isSector ? 1800 : 3500;

    final keyword = _getGoogleSearchKeyword(cleanCat);
    final textQuery = '$keyword in $cleanArea Islamabad';

    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.rating,places.userRatingCount,places.types,places.location,places.currentOpeningHours',
        },
        body: jsonEncode({
          'textQuery': textQuery,
          'maxResultCount': 20,
          'locationBias': {
            'circle': {
              'center': {'latitude': targetLat, 'longitude': targetLng},
              'radius': radius,
            },
          },
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final places = json['places'] as List?;

        if (places != null && places.isNotEmpty) {
          final List<StoreModel> results = [];
          final Set<String> seenNames = {};

          for (final place in places) {
            final displayName = place['displayName']?['text']?.toString() ?? '';
            if (displayName.trim().isEmpty) continue;

            final address = place['formattedAddress']?.toString() ?? '$cleanArea, Islamabad';
            final loc = place['location'];
            final pLat = loc != null ? double.tryParse(loc['latitude'].toString()) : null;
            final pLng = loc != null ? double.tryParse(loc['longitude'].toString()) : null;

            final typesList = (place['types'] as List?)?.map((t) => t.toString()).toList();

            final store = StoreModel(
              id: place['id']?.toString() ?? 'google_${displayName.hashCode}',
              placeId: place['id']?.toString(),
              name: displayName,
              address: address,
              area: cleanArea,
              type: cleanCat,
              category: cleanCat,
              rating: double.tryParse(place['rating']?.toString() ?? '4.5') ?? 4.5,
              userRatingsTotal: int.tryParse(place['userRatingCount']?.toString() ?? ''),
              isOpen: place['currentOpeningHours']?['openNow'],
              lat: pLat,
              lng: pLng,
              isGoogleStore: true,
              isBackendStore: false,
              isAdminStore: false,
              active: true,
              supportedCategories: typesList,
            );

            // Filter with sector isolation and category keyword matching
            final areaMatch = AreaHelper.isStoreInTargetArea(
              store,
              cleanArea,
              targetLat: targetLat,
              targetLng: targetLng,
            );
            final catMatch = CategoryMatcher.doesStoreMatchCategory(store, cleanCat);

            if (areaMatch && catMatch) {
              final key = displayName.toLowerCase().trim();
              if (!seenNames.contains(key)) {
                seenNames.add(key);
                results.add(store);
              }
            }
          }

          if (results.isNotEmpty) {
            _googleCache[cacheKey] = results;
            return results;
          }
        }
      }
    } catch (e) {
      // Continue without error if Google fetch fails/times out
    }

    return [];
  }

  /// Fetches admin and backend stores from Firestore (`areas` and `stores` collections)
  static Future<List<StoreModel>> fetchFirestoreStores({
    required String areaName,
    String? categoryId,
    String? categoryName,
  }) async {
    final cleanArea = AreaHelper.cleanSectorName(areaName);
    final targetCat = categoryName ?? categoryId ?? '';
    final List<StoreModel> list = [];
    final Set<String> seenNames = {};

    // 1. Query Firestore 'areas' collection (Admin stores saved in area documents)
    try {
      final areasSnap = await _firestore.collection('areas').get();
      for (final doc in areasSnap.docs) {
        final data = doc.data();
        final docAreaName = (data['name'] ?? '').toString().trim();
        final docId = doc.id.trim();

        final areaMatches = docAreaName.toLowerCase() == cleanArea.toLowerCase() ||
            docId.toLowerCase() == cleanArea.toLowerCase() ||
            AreaHelper.cleanSectorName(docAreaName).toLowerCase() == cleanArea.toLowerCase() ||
            AreaHelper.cleanSectorName(docId).toLowerCase() == cleanArea.toLowerCase();

        if (areaMatches && data['stores'] is List) {
          final storesArray = data['stores'] as List;
          for (var i = 0; i < storesArray.length; i++) {
            final item = storesArray[i];
            if (item == null) continue;

            Map<String, dynamic> storeMap;
            if (item is String) {
              storeMap = {
                'id': 'area_${doc.id}_$i',
                'name': item,
                'type': targetCat,
                'category': targetCat,
                'address': '$cleanArea, Islamabad',
                'area': cleanArea,
                'rating': 4.8,
                'active': true,
                'isAdminStore': true,
                'isBackendStore': true,
              };
            } else if (item is Map) {
              if (item['active'] == false) continue;
              storeMap = Map<String, dynamic>.from(item);
              storeMap['id'] ??= 'area_${doc.id}_$i';
              storeMap['address'] ??= '$cleanArea, Islamabad';
              storeMap['area'] ??= cleanArea;
              storeMap['isAdminStore'] = true;
              storeMap['isBackendStore'] = true;
            } else {
              continue;
            }

            final name = (storeMap['name'] ?? storeMap['storeName'] ?? '').toString().trim();
            if (name.isEmpty) continue;

            if (CategoryMatcher.doesStoreMatchCategory(storeMap, targetCat)) {
              final key = name.toLowerCase();
              if (!seenNames.contains(key)) {
                seenNames.add(key);
                list.add(StoreModel.fromMap(storeMap, docId: storeMap['id']));
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Query standalone 'stores' collection
    try {
      final storesSnap = await _firestore.collection('stores').get();
      for (final doc in storesSnap.docs) {
        final data = doc.data();
        if (data['active'] == false) continue;

        final storeArea = (data['area'] ?? '').toString().trim();
        final areaMatches = data['allAreas'] == true ||
            storeArea.toLowerCase() == cleanArea.toLowerCase() ||
            AreaHelper.cleanSectorName(storeArea).toLowerCase() == cleanArea.toLowerCase();

        if (areaMatches && CategoryMatcher.doesStoreMatchCategory(data, targetCat)) {
          final name = (data['name'] ?? data['storeName'] ?? '').toString().trim();
          final key = name.toLowerCase();
          if (name.isNotEmpty && !seenNames.contains(key)) {
            seenNames.add(key);
            list.add(StoreModel.fromMap(data, docId: doc.id));
          }
        }
      }
    } catch (_) {}

    return list;
  }

  /// Immediate instant stores (Firestore + local fallback for this sector & category)
  static Future<List<StoreModel>> getImmediateStores({
    required String areaName,
    String? categoryId,
    String? categoryName,
  }) async {
    final cleanArea = AreaHelper.cleanSectorName(areaName);
    final targetCat = categoryName ?? categoryId ?? '';

    // Fetch from Firestore
    final firestoreStores = await fetchFirestoreStores(
      areaName: cleanArea,
      categoryId: categoryId,
      categoryName: targetCat,
    );

    // Get fallback stores tailored to sector and category
    final fallbacks = AreaHelper.getFallbackStoresForAreaAndCategory(cleanArea, targetCat)
        .map((m) => StoreModel.fromMap(m, docId: m['id']))
        .toList();

    // Deduplicate and merge
    final Map<String, StoreModel> uniqueMap = {};
    for (final s in firestoreStores) {
      final key = s.name.trim().toLowerCase();
      if (key.isNotEmpty) uniqueMap[key] = s;
    }
    for (final s in fallbacks) {
      final key = s.name.trim().toLowerCase();
      if (key.isNotEmpty && !uniqueMap.containsKey(key)) {
        uniqueMap[key] = s;
      }
    }

    return uniqueMap.values.toList();
  }

  /// Full resolution: Immediate stores + Google Places background results
  static Future<List<StoreModel>> getAllStoresForAreaAndCategory({
    required String areaName,
    String? categoryId,
    String? categoryName,
    double? userLat,
    double? userLng,
  }) async {
    final cleanArea = AreaHelper.cleanSectorName(areaName);
    final targetCat = categoryName ?? categoryId ?? '';

    final immediate = await getImmediateStores(
      areaName: cleanArea,
      categoryId: categoryId,
      categoryName: targetCat,
    );

    final google = await fetchNearbyStoresFromGoogle(
      areaName: cleanArea,
      categoryName: targetCat,
      userLat: userLat,
      userLng: userLng,
    );

    final Map<String, StoreModel> uniqueMap = {};

    // Put Google stores (real local shops) and Admin stores
    for (final s in google) {
      final key = s.name.trim().toLowerCase();
      if (key.isNotEmpty) uniqueMap[key] = s;
    }

    for (final s in immediate) {
      final key = s.name.trim().toLowerCase();
      if (key.isNotEmpty) {
        if (s.isAdminStore || !uniqueMap.containsKey(key)) {
          uniqueMap[key] = s;
        }
      }
    }

    return uniqueMap.values.toList();
  }
}
