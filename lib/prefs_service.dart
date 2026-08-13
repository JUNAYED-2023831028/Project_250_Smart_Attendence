import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserUid = 'user_uid';
  static const String _keyUserName = 'user_name';
  static const String _keyUserId = 'user_id';

  static Future<void> saveUserSession({
    required String uid,
    required String role,
    required String name,
    required String id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserUid, uid);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserId, id);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? '';
  }

  static Future<Map<String, dynamic>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString(_keyUserUid) ?? '',
      'role': prefs.getString(_keyUserRole) ?? '',
      'name': prefs.getString(_keyUserName) ?? '',
      'id': prefs.getString(_keyUserId) ?? '',
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}