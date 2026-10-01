class CategoryMatchResult {
  final String categoryId;
  final String categoryName;
  final String icon;

  CategoryMatchResult({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
  });
}

class CategoryDetectionService {
  static const List<String> pharmacyKeywords = [
    'disprean', 'disprin', 'dispirin', 'panadol', 'brufen', 'paracetamol', 'medicine', 'medicines',
    'tablet', 'tablets', 'syrup', 'syrups', 'bandaid', 'bandage', 'vitamin', 'vitamins', 'health',
    'pharmacy', 'medical', 'dettol', 'sanitizer', 'mask', 'insulin', 'cream', 'lotion', 'ointment',
    'augmentin', 'flagyl', 'arinac', 'ponstan', 'calpol', 'gaviscon', 'sancos', 'cough', 'drops',
  ];

  static const List<String> groceryKeywords = [
    'milk', 'eggs', 'egg', 'bread', 'butter', 'cheese', 'yogurt', 'curd', 'rice', 'flour', 'atta',
    'sugar', 'salt', 'oil', 'ghee', 'tea', 'chai', 'coffee', 'pulses', 'daal', 'dal', 'biscuit',
    'biscuits', 'snack', 'snacks', 'chips', 'lays', 'ketchup', 'mayo', 'mayonnaise', 'soap', 'surf',
    'detergent', 'shampoo', 'toothpaste', 'brush', 'tissue', 'tissues', 'grocery', 'supermarket',
    'olpers', 'nestle', 'nurpur', 'dalda', 'habib', 'tapal', 'lipton', 'coca cola', 'pepsi', 'sprite',
  ];

  static const List<String> freshBazaarKeywords = [
    'apple', 'apples', 'banana', 'bananas', 'orange', 'oranges', 'mango', 'mangoes', 'grapes',
    'potato', 'potatoes', 'aloo', 'onion', 'onions', 'pyaz', 'tomato', 'tomatoes', 'tamatar',
    'chilli', 'mirch', 'ginger', 'adrak', 'garlic', 'lehsun', 'coriander', 'dhaniya', 'mint', 'pudina',
    'vegetable', 'vegetables', 'fruit', 'fruits', 'subzi', 'sabzi', 'phul', 'fresh', 'bazaar',
  ];

  static const List<String> meatKeywords = [
    'chicken', 'mutton', 'beef', 'meat', 'gosht', 'fish', 'prawn', 'prawns', 'keema', 'mince',
    'tikka', 'boti', 'wings', 'drumstick', 'boneless', 'marrow', 'nalli',
  ];

  static const List<String> bakeryKeywords = [
    'cake', 'cakes', 'pastry', 'pastries', 'rusk', 'patties', 'patty', 'croissant', 'donut', 'donuts',
    'cookie', 'cookies', 'bakery', 'brownie', 'brownies', 'pie', 'tart', 'bread loaf',
  ];

  static const List<String> cosmeticsKeywords = [
    'lipstick', 'foundation', 'eyeliner', 'mascara', 'perfume', 'fragrance', 'makeup', 'nail polish',
    'face wash', 'sunscreen', 'scrub', 'moisturizer', 'cosmetic', 'beauty',
  ];

  static CategoryMatchResult detectCategory(String itemText) {
    if (itemText.trim().isEmpty) {
      return CategoryMatchResult(categoryId: 'food', categoryName: 'Food', icon: '🍔');
    }

    final lower = itemText.toLowerCase();

    for (var kw in pharmacyKeywords) {
      if (lower.contains(kw)) {
        return CategoryMatchResult(categoryId: 'pharmacy', categoryName: 'Pharmacy', icon: '💊');
      }
    }

    for (var kw in freshBazaarKeywords) {
      if (lower.contains(kw)) {
        return CategoryMatchResult(categoryId: 'fresh-bazaar', categoryName: 'Fresh Bazaar', icon: '🥬');
      }
    }

    for (var kw in meatKeywords) {
      if (lower.contains(kw)) {
        return CategoryMatchResult(categoryId: 'meat', categoryName: 'Meat', icon: '🥩');
      }
    }

    for (var kw in groceryKeywords) {
      if (lower.contains(kw)) {
        return CategoryMatchResult(categoryId: 'groceries', categoryName: 'Groceries', icon: '🛒');
      }
    }

    for (var kw in bakeryKeywords) {
      if (lower.contains(kw)) {
        return CategoryMatchResult(categoryId: 'bakery', categoryName: 'Bakery', icon: '🥐');
      }
    }

    for (var kw in cosmeticsKeywords) {
      if (lower.contains(kw)) {
        return CategoryMatchResult(categoryId: 'cosmetics', categoryName: 'Cosmetics', icon: '💄');
      }
    }

    return CategoryMatchResult(categoryId: 'food', categoryName: 'Food', icon: '🍔');
  }
}
