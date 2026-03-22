import 'package:flutter/foundation.dart';

import '../auth_view_model.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;

  LoginViewModel(this._authViewModel);

  bool isLoading = false;

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    notifyListeners();

    final success = await _authViewModel.login(
      email: email,
      password: password,
    );

    isLoading = false;
    notifyListeners();

    return success;
  }
}
