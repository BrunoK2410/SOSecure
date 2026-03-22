import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/sos_event.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../auth/auth_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  final SosRepository _sosRepository;
  final LocationRepository _locationRepository;
  final Uuid _uuid = const Uuid();

  bool isLocationActive = true;
  int contactsCount = 0;
  bool isSendingAlert = false;
  String? lastMessage;

  HomeViewModel(
    this._authViewModel,
    this._sosRepository,
    this._locationRepository,
  );

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

    final user = _authViewModel.currentUser;
    if (user == null) {
      lastMessage = 'Must be logged in to send SOS';
      notifyListeners();
      return;
    }

    isSendingAlert = true;
    lastMessage = null;
    notifyListeners();

    try {
      double lat = 0.0;
      double lng = 0.0;
      String locationLbl = 'Current Device Location';

      try {
        var permission = await _locationRepository.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await _locationRepository.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await _locationRepository
              .getCurrentPosition()
              .timeout(const Duration(seconds: 10));
          lat = position.latitude;
          lng = position.longitude;
          locationLbl =
              'Current Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        } else {
          locationLbl = 'Location Permission Denied';
        }
      } catch (e) {
        debugPrint('Location error during SOS: $e');
        locationLbl = 'Location Unavailable';
      }

      final newEvent = SosEvent(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        locationLabel: locationLbl,
        latitude: lat,
        longitude: lng,
        status: 'Sent',
      );

      // Fire and forget: Firestore local cache instantly populates History stream
      // but if the network is flaky, awaiting this would hang the UI forever.
      _sosRepository.addEvent(user.id, newEvent).catchError((e) {
        debugPrint('Background sync error: $e');
      });

      lastMessage = 'SOS alert triggered successfully';
    } catch (e) {
      lastMessage = 'Failed to send SOS: $e';
    } finally {
      isSendingAlert = false;
      notifyListeners();
    }
  }

  void clearMessage() {
    lastMessage = null;
    notifyListeners();
  }
}
