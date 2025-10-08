import 'package:latlong2/latlong.dart';

class LatLngExtractor {
  static LatLng extractLatLng(String point) {
    print('🔍 Extracting coordinates from: $point');

    // Remove "POINT" and parentheses, e.g., "POINT(3.1390 101.6869)" -> "3.1390 101.6869"
    final coordinates = point.replaceAll('POINT(', '').replaceAll(')', '');

    // Split by space to separate coordinates
    final coordsList = coordinates.split(' ');

    // Ensure we have exactly 2 values
    if (coordsList.length != 2) {
      throw FormatException('Invalid POINT format: $point');
    }

    // Parse the strings into doubles
    // Based on sample data: POINT(3.1390 101.6869) = POINT(latitude longitude)
    final latitude = double.parse(coordsList[0].trim());
    final longitude = double.parse(coordsList[1].trim());

    print('   → Extracted: lat=$latitude, lng=$longitude');

    // Return as LatLng object
    return LatLng(latitude, longitude);
  }
}
