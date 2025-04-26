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
