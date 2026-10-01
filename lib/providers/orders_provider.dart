import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../constants/order_status.dart';

class OrdersProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  StreamSubscription<List<OrderModel>>? _sub;
  bool _isLoading = true;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  List<OrderModel> get activeOrders => _orders.where((o) => OrderStatusHelper.isActive(o.status)).toList();
  List<OrderModel> get pastOrders => _orders.where((o) => !OrderStatusHelper.isActive(o.status)).toList();
  List<OrderModel> get openOrders => _orders.where((o) => OrderStatusHelper.isOpen(o.status)).toList();

  void startListening(String userId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = ApiService.streamCustomerOrders(userId).listen((list) {
      _orders = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
