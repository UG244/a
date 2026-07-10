import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'role';
  static const String _keyLoginTime = 'login_time';
  static const String _keyRegisteredUsers = 'registered_users';

  // Admin hardcoded
  static const Map<String, Map<String, String>> _adminUsers = {
    'admin': {'password': 'admin123', 'role': 'admin'},
  };

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final username = prefs.getString(_keyUsername);
    final role = prefs.getString(_keyRole);
    if (username == null || role == null) return null;

    return AppUser(username: username, role: role);
  }

  /// Get all registered users from SharedPreferences
  Future<Map<String, Map<String, String>>> _getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyRegisteredUsers);
    if (json == null) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, Map<String, String>.from(v as Map)),
    );
  }

  /// Save registered users to SharedPreferences
  Future<void> _saveRegisteredUsers(
    Map<String, Map<String, String>> users,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegisteredUsers, jsonEncode(users));
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return 'Username dan password tidak boleh kosong';
    }

    // Check admin first
    final adminData = _adminUsers[username.toLowerCase()];
    if (adminData != null) {
      if (adminData['password'] != password) return 'Password salah';
      return await _saveSession(username, adminData['role']!);
    }

    // Check registered users
    final registeredUsers = await _getRegisteredUsers();
    final userData = registeredUsers[username.toLowerCase()];
    if (userData == null) return 'Username tidak ditemukan';
    if (userData['password'] != password) return 'Password salah';

    return await _saveSession(username, userData['role']!);
  }

  /// Register a new user account
  Future<String?> register(String username, String password) async {
    if (username.trim().isEmpty) return 'Username tidak boleh kosong';
    if (password.length < 4) return 'Password minimal 4 karakter';

    final lower = username.trim().toLowerCase();

    // Check if username is admin
    if (_adminUsers.containsKey(lower)) return 'Username tidak tersedia';

    // Check if already registered
    final registeredUsers = await _getRegisteredUsers();
    if (registeredUsers.containsKey(lower)) return 'Username sudah terdaftar';

    // Save new user
    registeredUsers[lower] = {'password': password, 'role': 'user'};
    await _saveRegisteredUsers(registeredUsers);

    // Auto login
    await _saveSession(username.trim(), 'user');
    return null; // success
  }

  Future<String?> _saveSession(String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyLoginTime);
  }

  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.role == 'admin';
  }
}
