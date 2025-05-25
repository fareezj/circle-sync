import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureAlwaysLocation() async {
  // 0️⃣ Make sure device‐level services are on
  if (!await Geolocator.isLocationServiceEnabled()) {
    // Prompt user to enable GPS
    await _showLocationServiceDialog();
    return false;
  }

  // 1️⃣ Request “When In Use”
  var status = await Permission.locationWhenInUse.status;
  if (status != PermissionStatus.granted) {
    status = await Permission.locationWhenInUse.request();
    if (status != PermissionStatus.granted) {
      await _showSettingsDialog(
        title: 'Location Required',
        message:
            'Circle Sync needs location while you’re using the app to share your position.',
      );
      return false;
    }
  }

  // 2️⃣ Request “Always”
  status = await Permission.locationAlways.status;
  if (status != PermissionStatus.granted) {
    status = await Permission.locationAlways.request();
    if (status != PermissionStatus.granted) {
      await _showSettingsDialog(
        title: 'Background Location Required',
        message:
            'To keep your circle updated when the app is backgrounded, please enable “Always Allow.”',
      );
      return false;
    }
  }

  return true;
}

Future<void> _showSettingsDialog({
  required String title,
  required String message,
}) async {
  // Show a dialog with “Go to Settings” → openAppSettings()
}

Future<void> _showLocationServiceDialog() async {
  // Show a dialog with “Enable Location Services” → Geolocator.openLocationSettings()
  Geolocator.openLocationSettings();
}
