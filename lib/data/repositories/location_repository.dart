import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationRepository {
  final LocationService _locationService;
  Position? currentPosition;

  LocationRepository(this._locationService);

  Future<bool> isLocationServiceEnabled() {
    return _locationService.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return _locationService.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return _locationService.requestPermission();
  }

  Future<Position> getCurrentPosition() async {
    final pos = await _locationService.getCurrentPosition();
    currentPosition = pos;
    return pos;
  }
}
