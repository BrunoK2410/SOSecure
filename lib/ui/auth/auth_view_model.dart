import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _userSubscription;

  AppUser? _currentUser;
  bool _isInitialized = false;

  AuthViewModel(this._authRepository) {
    _init();
  }

  void _init() {
    _userSubscription = _authRepository.userStream.listen((user) {
      _currentUser = user;
      _isInitialized = true;
      notifyListeners();
    });
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  Future<bool> login({required String email, required String password}) async {
    try {
      await _authRepository.login(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
