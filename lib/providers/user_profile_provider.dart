import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class UserProfileProvider extends ChangeNotifier {
  UserModel? _user;
  int _totalOrders = 0;
  int _activeOrders = 0;
  int _completedOrders = 0;

  UserModel? get user => _user;
  int get totalOrders => _totalOrders;
  int get activeOrders => _activeOrders;
  int get completedOrders => _completedOrders;

  Future<void> loadProfile() async {
    final cached = await StorageService.getData(AppConstants.userData);
    if (cached is Map<String, dynamic>) {
      _user = UserModel.fromMap(cached);
      notifyListeners();
    }

    try {
      final fresh = await ApiService.getMe();
      if (fresh != null) {
        _user = fresh;
        await StorageService.storeData(AppConstants.userData, fresh.toMap());
        notifyListeners();
      }
    } catch (_) {}
  }

  void setStats({required int total, required int active, required int completed}) {
    _totalOrders = total;
    _activeOrders = active;
    _completedOrders = completed;
    notifyListeners();
  }

  Future<void> updateAvatar(File file) async {
    final url = await ApiService.uploadProfileAvatar(file);
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        uid: _user!.uid,
        email: _user!.email,
        name: _user!.name,
        phone: _user!.phone,
        type: _user!.type,
        types: _user!.types,
        avatar: url,
        addresses: _user!.addresses,
      );
      await StorageService.storeData(AppConstants.userData, _user!.toMap());
      notifyListeners();
    }
  }

  Future<void> updateDetails({required String name, required String phone}) async {
    await ApiService.updateProfile({'name': name, 'phone': phone});
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        uid: _user!.uid,
        email: _user!.email,
        name: name,
        phone: phone,
        type: _user!.type,
        types: _user!.types,
        avatar: _user!.avatar,
        addresses: _user!.addresses,
      );
      await StorageService.storeData(AppConstants.userData, _user!.toMap());
      notifyListeners();
    }
  }
}
