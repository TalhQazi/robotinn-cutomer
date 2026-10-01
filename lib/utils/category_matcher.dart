// Robust category matching & filtering helper for RobotInn Customer App
// Ported from React Native src/utils/categoryMatching.js

class CategoryMatcher {
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}|\u{1F900}-\u{1F9FF}|\u{1FA70}-\u{1FAFF}]',
    unicode: true,
  );

  static String cleanCategory(String? targetCategory) {
    if (targetCategory == null) return '';
    return targetCategory.replaceAll(_emojiRegex, '').trim();
  }

  static String getCanonicalCategoryKey(String? targetCategory) {
    final targetRaw = cleanCategory(targetCategory).toLowerCase();
    if (targetRaw.isEmpty || targetRaw == 'all' || targetRaw == 'other' || targetRaw == 'general') {
      return '';
    }

    if (targetRaw.contains('pharma') ||
        targetRaw.contains('health') ||
        targetRaw.contains('medical') ||
        targetRaw.contains('chemist') ||
        targetRaw.contains('medicine')) {
      return 'pharmacy';
    } else if (targetRaw.contains('food') ||
        targetRaw.contains('restaurant') ||
        targetRaw.contains('fast') ||
        targetRaw.contains('diner') ||
        targetRaw.contains('cafe') ||
        targetRaw.contains('burger') ||
        targetRaw.contains('pizza')) {
      return 'food';
    } else if (targetRaw.contains('grocer') ||
        targetRaw.contains('mart') ||
        targetRaw.contains('supermarket')) {
      return 'grocery';
    } else if (targetRaw.contains('baker') ||
        targetRaw.contains('cake') ||
        targetRaw.contains('bread') ||
        targetRaw.contains('sweet')) {
      return 'bakery';
    } else if (targetRaw.contains('meat') ||
        targetRaw.contains('chicken') ||
        targetRaw.contains('butcher')) {
      return 'meat';
    } else if (targetRaw.contains('cosmetic') ||
        targetRaw.contains('beauty') ||
        targetRaw.contains('makeup') ||
        targetRaw.contains('skin')) {
      return 'cosmetics';
    } else if (targetRaw.contains('stationery') ||
        targetRaw.contains('book') ||
        targetRaw.contains('paper')) {
      return 'stationery';
    } else if (targetRaw.contains('electronic') ||
        targetRaw.contains('mobile') ||
        targetRaw.contains('tech') ||
        targetRaw.contains('computer')) {
      return 'electronics';
    } else if (targetRaw.contains('pet')) {
      return 'pet_supplies';
    } else if (targetRaw.contains('dairy') || targetRaw.contains('milk')) {
      return 'dairy';
    } else if (targetRaw.contains('fruit')) {
      return 'fruits';
    } else if (targetRaw.contains('veg') || targetRaw.contains('sabzi')) {
      return 'vegetables';
    } else if (targetRaw.contains('drink') ||
        targetRaw.contains('soda') ||
        targetRaw.contains('beverage')) {
      return 'soft_drinks';
    }

    return targetRaw;
  }

  static const Map<String, List<String>> keywordsByCat = {
    'pharmacy': [
      'chemist', 'pharmacy', 'medical', 'medicos', 'pharma', 'dr.', 'd.watson',
      'watson', 'shaheen', 'servaid', 'shifa', 'health', 'disprin', 'panadol',
      'brufen', 'medicine', 'medicines', 'clinic', 'hospital', 'drug', 'drugs',
      'care', 'surgical', 'metro pharmacy', 'city pharmacy'
    ],
    'food': [
      'food', 'foods', 'restaurant', 'fast food', 'biryani', 'karahi', 'tikka',
      'bbq', 'nihari', 'pulao', 'roll', 'shawarma', 'grill', 'eatery', 'diner',
      'cafe', 'coffee', 'tea', 'burger', 'pizza', 'kfc', 'mcdonald', 'subway',
      'dunkin', 'cheezious', 'howdy', 'savour', 'kabab', 'kebab', 'haleem',
      'fish', 'broast', 'snack', 'paratha', 'chai', 'dhaba', 'kitchen', 'hotel',
      'baskin', 'tehzeeb', 'steak', 'dastarkhwan', 'balto', 'rumba', 'momento'
    ],
    'grocery': [
      'mart', 'supermarket', 'store', 'cash & carry', 'cash and carry', 'savemart',
      'imtiaz', 'greenvalley', 'punjab cash', 'grocery', 'general store',
      'carrefour', 'al-fatah', 'karyana', 'provision', 'bazaar', 'super store',
      'mini mart', 'wholesale', 'retail', 'saladin', 'esajee'
    ],
    'bakery': [
      'bakery', 'bakers', 'sweets', 'confectionery', 'patisserie', 'tehzeeb',
      'rahat', 'layered', 'kitchen cuisine', 'gourmet', 'bread', 'cake', 'cakes',
      'pastry', 'nimco', 'sweet', 'mithai', 'halwa', 'bread chef'
    ],
    'meat': [
      'meat', 'butcher', 'poultry', 'chicken', 'meat one', 'kausar', 'mutton',
      'beef', 'fish', 'prawn', 'al-makkah meat', 'al madina meat', 'gosht'
    ],
    'cosmetics': [
      'cosmetics', 'beauty', 'scentsation', 'saeed ghani', 'makeup', 'nivea',
      'skincare', 'glamour', 'perfume', 'fragrance', 'salon'
    ],
    'stationery': [
      'book', 'stationery', 'paper', 'books', 'saeed book', 'london book',
      'copy', 'book store', 'photocopy', 'pen'
    ],
    'electronics': [
      'electronic', 'electronics', 'mobile', 'samsung', 'apple', 'mi',
      'computer', 'tech', 'gadget', 'cellular', 'telecom'
    ],
    'pet_supplies': [
      'pet', 'vet', 'animal', 'dog', 'cat', 'litter', 'birds', 'aquarium'
    ],
    'dairy': [
      'dairy', 'milk', 'dahi', 'yogurt', 'butter', 'cheese', 'creamer',
      'milk shop', 'fresh milk'
    ],
    'fruits': [
      'fruit', 'fruits', 'apple', 'banana', 'mango', 'orange', 'fruit shop',
      'fresh fruits', 'produce', 'fruit stall'
    ],
    'vegetables': [
      'vegetable', 'vegetables', 'veggie', 'sabzi', 'sabzi mandi', 'potato',
      'onion', 'tomato', 'fresh veg', 'palace', 'bio-organic', 'organic', 'farm',
      'green fresh', 'fresh produce'
    ],
    'soft_drinks': [
      'drink', 'drinks', 'beverage', 'coke', 'pepsi', 'sprite', '7up', 'sting',
      'redbull', 'soda', 'juice', 'shake'
    ],
  };

  /// Evaluates whether a given store (StoreModel, Map, or String) matches the category.
  static bool doesStoreMatchCategory(dynamic store, String? targetCategory) {
    if (targetCategory == null || targetCategory.trim().isEmpty) return true;
    final targetRaw = cleanCategory(targetCategory).toLowerCase().trim();
    if (targetRaw.isEmpty || targetRaw == 'all' || targetRaw == 'other' || targetRaw == 'general') {
      return true;
    }

    String storeName = '';
    String storeType = '';
    List<String> supported = [];
    bool isGoogleStore = false;
    bool isBackendStore = false;

    if (store is String) {
      storeName = store.toLowerCase().trim();
    } else if (store is Map) {
      storeName = (store['name'] ?? store['storeName'] ?? '').toString().toLowerCase().trim();
      storeType = (store['type'] ?? store['category'] ?? store['categoryName'] ?? store['categoryId'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final supp = store['supportedCategories'] ?? store['types'];
      if (supp is List) {
        supported = supp.map((c) => c.toString().toLowerCase()).toList();
      }
      isGoogleStore = store['isGoogleStore'] == true;
      isBackendStore = store['isBackendStore'] == true;
    } else {
      // StoreModel or object
      try {
        storeName = (store.name ?? '').toString().toLowerCase().trim();
        storeType = (store.type ?? store.category ?? store.categoryId ?? '').toString().toLowerCase().trim();
        if (store.supportedCategories is List) {
          supported = (store.supportedCategories as List).map((c) => c.toString().toLowerCase()).toList();
        }
        isGoogleStore = store.isGoogleStore == true;
        isBackendStore = store.isBackendStore == true;
      } catch (_) {}
    }

    final targetCatKey = getCanonicalCategoryKey(targetRaw);

    // 1. Check supportedCategories array if specified
    if (supported.isNotEmpty) {
      if (targetCatKey.isNotEmpty &&
          supported.any((s) => s.contains(targetCatKey) || targetCatKey.contains(s))) {
        return true;
      }
      if (supported.any((s) => s.contains(targetRaw) || targetRaw.contains(s))) {
        return true;
      }
    }

    // 2. Check storeType string
    if (storeType.isNotEmpty) {
      if (targetCatKey.isNotEmpty &&
          (storeType.contains(targetCatKey) || targetCatKey.contains(storeType))) {
        return true;
      }
      if (storeType.contains(targetRaw) || targetRaw.contains(storeType)) {
        return true;
      }
    }

    // 3. Keyword check on storeName
    final keyList = targetCatKey.isNotEmpty ? (keywordsByCat[targetCatKey] ?? []) : [];
    if (keyList.any((k) => storeName.contains(k))) {
      return true;
    }

    // 4. Fallback for Google/Backend stores specifically fetched for this category
    if (isGoogleStore || isBackendStore) {
      if (storeType.isEmpty ||
          storeType == 'store' ||
          storeType == 'general' ||
          storeType.contains(targetCatKey) ||
          targetCatKey.contains(storeType)) {
        return true;
      }
    }

    // 5. Fallback substring match
    if (storeType.isEmpty || storeType == 'store' || storeType == 'general') {
      if (storeName.isEmpty) return true;
      return storeName.contains(targetRaw) || targetRaw.contains(storeName);
    }

    return false;
  }
}
