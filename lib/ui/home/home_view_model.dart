import 'dart:async';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  bool isLocationActive = true;
  int contactsCount = 0;
  bool isSendingAlert = false;
  String? lastMessage;

  void setLocationActive(bool value) {
    isLocationActive = value;
    notifyListeners();
  }

  void setContactsCount(int value) {
    contactsCount = value;
    notifyListeners();
  }

  Future<void> triggerSos() async {
    if (isSendingAlert) return;

    isSendingAlert = true;
    lastMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    isSendingAlert = false;
    lastMessage = 'SOS alert triggered successfully';
    notifyListeners();
  }

  void clearMessage() {
    lastMessage = null;
    notifyListeners();
  }
}
