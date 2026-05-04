import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/notification_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final NotificationService _notificationService;
  final FirestoreService _firestoreService;
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  AppUser? _currentUser;
  bool _isInitialized = false;

  AuthViewModel(
    this._authRepository,
    this._notificationService,
    this._firestoreService,
  ) {
    _init();
  }

  void _init() {
    _userSubscription = _authRepository.userStream.listen((user) {
      _currentUser = user;
      _isInitialized = true;
      if (user != null) {
        _syncFcmToken();
      }
      notifyListeners();
    });

    // Re-sync token whenever Firebase rotates it — prevents stale tokens
    _tokenRefreshSubscription = _notificationService.onTokenRefresh.listen((newToken) {
      if (_currentUser != null) {
        debugPrint('FCM Token rotated, re-syncing...');
        _firestoreService.updateFcmToken(_currentUser!.id, newToken);
      }
    });
  }

  Future<void> _syncFcmToken() async {
    if (_currentUser == null) return;
    try {
      final token = await _notificationService.getToken();
      if (token != null) {
        await _firestoreService.updateFcmToken(_currentUser!.id, token);
        debugPrint('FCM Token synced: $token');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
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
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}

