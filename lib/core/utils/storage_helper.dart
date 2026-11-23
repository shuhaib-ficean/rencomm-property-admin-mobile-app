import 'package:admin_mobile_app/utils/debug_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user_model.dart';

class StorageHelper {
  static const _storage = FlutterSecureStorage();

  // Token storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token.trim());
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }

  // Refresh Token storage
  static Future<void> saveRefreshToken(String token) async {
    consoleLog('refresh token being saved $token');
    await _storage.write(key: 'refreshToken', value: token.trim());
  }

  static Future<String?> getRefreshToken() async {
    consoleLog('refresh token being get ');

    return await _storage.read(key: 'refreshToken');
  }

  static Future<void> deleteRefreshToken() async {
    consoleLog('refresh token being deleted ');
    await _storage.delete(key: 'refreshToken');
  }

  // User storage
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  static Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  // Clear all data
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteRefreshToken();
    await deleteUser();
  }
}
