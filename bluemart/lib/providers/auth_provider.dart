import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Centralized auth state with ChangeNotifier for Provider pattern.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoading => _isLoading;

  /// Initialize session on app start.
  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.getCurrentUser();
      _currentUser = user;
    } catch (_) {
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Login a user. Returns null on success, or error message string on failure.
  Future<String?> login(String username, String password) async {
    final error = await _authService.login(username, password);
    if (error == null) {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    }
    return error;
  }

  /// Register a new user. Returns null on success, or error message string.
  Future<String?> register(String username, String password) async {
    final error = await _authService.register(username, password);
    if (error == null) {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    }
    return error;
  }

  /// Logout the current user and clear session.
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Route guard: returns false if user should be redirected to login.
  bool guardAdmin() {
    if (_currentUser == null || _currentUser!.role != 'admin') {
      return false;
    }
    return true;
  }

  /// Route guard: returns false if no user is logged in.
  bool guardUser() {
    if (_currentUser == null) {
      return false;
    }
    return true;
  }
}
