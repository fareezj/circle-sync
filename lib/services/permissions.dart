import 'package:location/location.dart';

class Permissions {
  static Future<bool> requestLocationPermissions() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return false;
    }

    // Check and request location permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    // Request background location permission (Android 10+)
    if (await location.isBackgroundModeEnabled() == false) {
      await location.enableBackgroundMode(enable: true);
    }

    return true;
  }
}
