import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationUnreadProvider extends ChangeNotifier {
  int _unreadCount = 0;
  StreamSubscription<List<NotificationModel>>? _sub;

  int get unreadCount => _unreadCount;

  void startListening(String userId) {
    _sub?.cancel();
    _sub = ApiService.streamNotifications(userId).listen((list) {
      _unreadCount = list.where((n) => !n.read).length;
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
