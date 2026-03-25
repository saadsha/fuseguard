import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  int _totalUsers = 0;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUsers => _totalUsers;

  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isEngineer => _currentUser?.role == 'Engineer';

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _currentUser = await _authService.getCurrentUser();
    if (_currentUser != null && isAdmin) {
      _fetchTotalUsers();
    }
    notifyListeners();
  }

  Future<void> _fetchTotalUsers() async {
    _totalUsers = await _authService.getTotalUsers();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      _isLoading = false;
      if (isAdmin) _fetchTotalUsers();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _isLoading = false;
      if (isAdmin) _fetchTotalUsers();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
