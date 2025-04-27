import 'package:latlong2/latlong.dart';

class LatLngExtractor {
  static LatLng extractLatLng(String point) {
    // Remove "POINT" and parentheses, e.g., "POINT(101.6684557 3.062425)" -> "101.6684557 3.062425"
    final coordinates = point.replaceAll('POINT(', '').replaceAll(')', '');

    // Split by space to separate longitude and latitude
    final coordsList = coordinates.split(' ');

    // Ensure we have exactly 2 values (longitude, latitude)
    if (coordsList.length != 2) {
      throw FormatException('Invalid POINT format: $point');
    }

    // Parse the strings into doubles
    final latitude = double.parse(coordsList[0].trim());
    final longitude = double.parse(coordsList[1].trim());

    // Return as LatLng object
    return LatLng(latitude, longitude);
  }
}
