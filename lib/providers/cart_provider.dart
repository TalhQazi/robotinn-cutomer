import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class CartOrderGroup {
  final String id;
  final String store;
  final String pickup;
  final String area;
  final String address;
  final List<OrderItemModel> items;
  final double estimatedPrice;
  final String notes;
  final dynamic location;
  final String createdAt;

  CartOrderGroup({
    required this.id,
    required this.store,
    required this.pickup,
    this.area = 'N/A',
    this.address = 'N/A',
    required this.items,
    this.estimatedPrice = 0.0,
    this.notes = '',
    this.location,
    required this.createdAt,
  });

  factory CartOrderGroup.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] is List ? map['items'] as List : [];
    final itemsList = rawItems
        .map((i) => i is Map<String, dynamic> ? OrderItemModel.fromMap(i) : null)
        .whereType<OrderItemModel>()
        .toList();

    return CartOrderGroup(
      id: map['id']?.toString() ?? 'cart-ord-${DateTime.now().millisecondsSinceEpoch}',
      store: map['store']?.toString() ?? map['pickup']?.toString() ?? 'Store',
      pickup: map['pickup']?.toString() ?? map['store']?.toString() ?? 'Store',
      area: map['area']?.toString() ?? 'N/A',
      address: map['address']?.toString() ?? 'N/A',
      items: itemsList,
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes']?.toString() ?? '',
      location: map['location'],
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store': store,
      'pickup': pickup,
      'area': area,
      'address': address,
      'items': items.map((i) => i.toMap()).toList(),
      'estimatedPrice': estimatedPrice,
      'notes': notes,
      'location': location,
      'createdAt': createdAt,
    };
  }
}

class CartProvider extends ChangeNotifier {
  List<CartOrderGroup> _cartOrders = [];

  List<CartOrderGroup> get cartOrders => _cartOrders;
  int get itemCount => _cartOrders.fold(0, (sum, order) => sum + order.items.length);
  int get orderCount => _cartOrders.length;

  Future<void> loadCart() async {
    final raw = await StorageService.getData(AppConstants.cart);
    if (raw is List) {
      _cartOrders = raw
          .map((e) => e is Map<String, dynamic> ? CartOrderGroup.fromMap(e) : null)
          .whereType<CartOrderGroup>()
          .toList();
      _cartOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }
  }

  Future<void> addOrderToCart(CartOrderGroup order) async {
    _cartOrders.insert(0, order);
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeOrder(String orderId) async {
    _cartOrders.removeWhere((o) => o.id == orderId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartOrders.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    await StorageService.storeData(
      AppConstants.cart,
      _cartOrders.map((o) => o.toMap()).toList(),
    );
  }
}
