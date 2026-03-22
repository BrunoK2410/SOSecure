import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService;
  final FirestoreService _firestoreService;

  AuthRepository(this._firebaseAuthService, this._firestoreService);

  Stream<AppUser?> get userStream {
    return _firebaseAuthService.authStateChanges.asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;
      // Fetch full user profile from Firestore
      return await _firestoreService.getUser(firebaseUser.uid);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _firebaseAuthService.signInWithEmailAndPassword(email, password);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuthService.createUserWithEmailAndPassword(email, password);
    final firebaseUser = userCredential.user;
    
    if (firebaseUser != null) {
      final newUser = AppUser(
        id: firebaseUser.uid,
        fullName: fullName,
        email: email,
      );
      await _firestoreService.saveUser(newUser);
    }
  }

  Future<void> logout() async {
    await _firebaseAuthService.signOut();
  }
}
