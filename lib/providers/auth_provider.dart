// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _selectedRole;
  bool _isLoading = false;
  String? _error;
  String? _passwordResetToken;

  // ==================== GETTERS ====================
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String? get selectedRole => _selectedRole;
  String? get passwordResetToken => _passwordResetToken;

  // Role helpers
  bool get isAdmin => _user?.role == 'admin';
  bool get isVendor => _user?.role == 'vendor';
  bool get isTourist => _user?.role == 'tourist';

  // ==================== INIT ====================
  AuthProvider() {
    checkAuthStatus();
  }

  // ==================== PRIVATE HELPERS ====================
  Future<void> _saveUserLocally(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.userKey, json.encode(user.toJson()));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.tokenKey, token);
  }

  // ==================== LOGIN ====================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'];
      _selectedRole = _user?.role;
      await _saveUserLocally(_user!);
      await _saveToken(result['token']);
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  // ==================== REGISTER TOURIST ====================
  Future<bool> registerTourist({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.registerTourist(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'];
      _selectedRole = _user?.role;
      await _saveUserLocally(_user!);
      await _saveToken(result['token']);
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  // ==================== REGISTER VENDOR ====================
  Future<bool> registerVendor({
    required String name,
    required String email,
    required String password,
    required String businessName,
    String? phone,
    String? businessPhone,
    String? businessAddress,
    String? businessType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.registerVendor(
      name: name,
      email: email,
      password: password,
      businessName: businessName,
      phone: phone,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
      businessType: businessType,
    );

    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _user = result['user'];
      _selectedRole = _user?.role;
      await _saveUserLocally(_user!);
      await _saveToken(result['token']);
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  // ==================== CHECK AUTH STATUS ====================
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn && _user == null) {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(Constants.userKey);
      if (userData != null) {
        try {
          _user = User.fromJson(json.decode(userData));
          _selectedRole = _user?.role;
        } catch (e) {
          debugPrint("Error decoding user: $e");
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    }
    _isLoading = false;
    notifyListeners();
    return isLoggedIn;
  }

  // ==================== LOGOUT ====================
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _selectedRole = null;
    notifyListeners();
  }

  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    _passwordResetToken = null;
    notifyListeners();

    final result = await _authService.requestPasswordReset(email);

    _isLoading = false;

    if (result['success'] == true) {
      _passwordResetToken = result['resetToken']?.toString();
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Failed to request password reset';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _passwordResetToken = null;
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Failed to reset password';
      notifyListeners();
      return false;
    }
  }

  // ==================== GET TOKEN ====================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.tokenKey);
  }

  // ==================== CLEAR ERROR ====================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPasswordResetToken() {
    _passwordResetToken = null;
    notifyListeners();
  }

  void switchToAdmin() {
    _loginAs('admin');
  }

  void switchToVendor() {
    _loginAs('vendor');
  }

  void switchToTourist() {
    _loginAs('tourist');
  }

  void _loginAs(String role) {
    _selectedRole = role;
    _user = User(
      id: 'dev-user-id',
      name: 'Dev ${role[0].toUpperCase()}${role.substring(1)}',
      email: '$role@example.com',
      role: role,
      verified: role != 'vendor',
    );
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
