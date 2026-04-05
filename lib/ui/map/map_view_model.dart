import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  String? errorMessage;

  Future<void> initialize() async {
    errorMessage = null;

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
    errorMessage = null;

    isLocationServiceEnabled = await _locationRepository
        .isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      errorMessage = 'Location services are disabled.';
      notifyListeners();
      return;
    }

    final permission = await _locationRepository.requestPermission();

    if (permission == LocationPermission.deniedForever) {
      isLocationPermissionGranted = false;
      errorMessage =
          'Location permission is permanently denied. Enable it from app settings.';
      notifyListeners();
      return;
    }

    isLocationPermissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    notifyListeners();

    if (isLocationPermissionGranted) {
      await centerOnUser();
    } else {
      errorMessage = 'Location permission was not granted.';
      notifyListeners();
    }
  }

  Future<void> centerOnUser() async {
    if (!isLocationPermissionGranted || !isLocationServiceEnabled) return;

    isLoadingLocation = true;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationRepository.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
      locationLabel = await _reverseGeocode(latitude, longitude);
    } on PermissionDeniedException {
      isLocationPermissionGranted = false;
      errorMessage = 'Location permission denied.';
    } on LocationServiceDisabledException {
      isLocationServiceEnabled = false;
      errorMessage = 'Location services are disabled.';
    } catch (e) {
      errorMessage = 'Failed to get current location: $e';
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
    return 'Current device location';
  }
}
