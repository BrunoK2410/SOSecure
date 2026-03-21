import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/location_repository.dart';

class MapViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;

  MapViewModel(this._locationRepository);

  bool isLocationPermissionGranted = false;
  bool isLocationServiceEnabled = false;
  bool isLoadingLocation = false;

  double latitude = 45.8150;
  double longitude = 15.9819;
  String locationLabel = 'Unknown location';

  Future<void> initialize() async {
    isLocationServiceEnabled = await _locationRepository
        .isLocationServiceEnabled();

    final permission = await _locationRepository.checkPermission();
    isLocationPermissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    notifyListeners();

    if (isLocationPermissionGranted && isLocationServiceEnabled) {
      await centerOnUser();
    }
  }

  Future<void> requestLocationAccess() async {
    isLocationServiceEnabled = await _locationRepository
        .isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      notifyListeners();
      return;
    }

    final permission = await _locationRepository.requestPermission();
    isLocationPermissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    notifyListeners();

    if (isLocationPermissionGranted) {
      await centerOnUser();
    }
  }

  Future<void> centerOnUser() async {
    if (!isLocationPermissionGranted) return;

    isLoadingLocation = true;
    notifyListeners();

    try {
      final position = await _locationRepository.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
      locationLabel = 'Current device location';
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }
}
