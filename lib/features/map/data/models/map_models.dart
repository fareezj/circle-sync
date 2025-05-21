class Zone {
  final double lat;
  final double lon;
  final double radius;
  final String title;

  Zone({
    required this.lat,
    required this.lon,
    required this.radius,
    required this.title,
  });

  /// if your API returns "POINT(lat lon)" strings:
  factory Zone.fromPostgis(Map<String, dynamic> row) {
    // e.g. row['center_geography'] == "POINT(3.0620 101.6721)"
    final pt = (row['center_geography'] as String)
        .replaceAll(RegExp(r'POINT\(|\)'), '')
        .split(' ');
    return Zone(
      lat: double.parse(pt[0]),
      lon: double.parse(pt[1]),
      radius: (row['radius_m'] as num).toDouble(),
      title: row['title'] as String,
    );
  }
}

class PlacesModel {
  final String geofenceId;
  final String circleId;
  final String centerGeography;
  final double radiusM;
  final String title;
  final String message;

  PlacesModel({
    required this.geofenceId,
    required this.circleId,
    required this.centerGeography,
    required this.radiusM,
    required this.title,
    required this.message,
  });

  // Factory method to create Geofence from JSON
  factory PlacesModel.fromJson(Map<String, dynamic> json) {
    return PlacesModel(
      geofenceId: json['geofence_id'] as String,
      circleId: json['circle_id'] as String,
      centerGeography: json['center_geography'] as String,
      radiusM: (json['radius_m'] as num).toDouble(),
      title: json['title'] as String,
      message: json['message'] as String,
    );
  }

  // Method to convert Geofence to JSON
  Map<String, dynamic> toJson() {
    return {
      'geofence_id': geofenceId,
      'circle_id': circleId,
      'center_geography': centerGeography,
      'radius_m': radiusM,
      'title': title,
      'message': message,
    };
  }
}
