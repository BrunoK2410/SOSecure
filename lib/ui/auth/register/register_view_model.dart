import 'package:flutter/foundation.dart';

import '../auth_view_model.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;

  RegisterViewModel(this._authViewModel);

  bool isLoading = false;

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    isLoading = true;
    notifyListeners();

    final success = await _authViewModel.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    isLoading = false;
    notifyListeners();

    return success;
  }
}
