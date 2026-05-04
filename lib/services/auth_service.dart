import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'api_token';
  static const String _userNicknameKey = 'user_nickname';
  static const String _userIdKey = 'user_id';
  static const String _isAdminKey = 'is_admin';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> saveUserNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNicknameKey, nickname);
  }

  static Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
  }

  static Future<void> saveIsAdmin(int isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_isAdminKey, isAdmin);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNicknameKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<int?> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_isAdminKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNicknameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_isAdminKey);
  }
}