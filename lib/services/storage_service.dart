import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> storeData(String key, dynamic value) async {
    final p = await prefs;
    if (value is String) {
      await p.setString(key, value);
    } else if (value is bool) {
      await p.setBool(key, value);
    } else if (value is int) {
      await p.setInt(key, value);
    } else if (value is double) {
      await p.setDouble(key, value);
    } else if (value is List<String>) {
      await p.setStringList(key, value);
    } else {
      await p.setString(key, jsonEncode(value));
    }
  }

  static Future<dynamic> getData(String key) async {
    final p = await prefs;
    final val = p.get(key);
    if (val == null) return null;
    if (val is String) {
      try {
        return jsonDecode(val);
      } catch (_) {
        return val;
      }
    }
    return val;
  }

  static Future<void> removeData(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  static Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
