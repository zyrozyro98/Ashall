import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final Location _location = Location();

  // Check Permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    // Check if permission is granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  // Get current location
  Future<LatLng?> getCurrentLocation() async {
    LocationData locData = await _location.getLocation();
    return LatLng(locData.latitude!, locData.longitude!);
  }

  // Stream location updates (for driver)
  Stream<LocationData> streamLocationUpdates() {
    _location.changeSettings(accuracy: LocationAccuracy.high, interval: 10000, distanceFilter: 10);
    return _location.onLocationChanged;
  }
}
