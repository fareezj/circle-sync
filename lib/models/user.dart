import 'package:latlong2/latlong.dart';

class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['name'] == null || json['email'] == null) {
      throw FormatException('Invalid user data');
    }
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class UserLocationInfo {
  final String id;
  final String userId;
  final LatLng location;
  final String? lastUpdate;

  UserLocationInfo({
    required this.id,
    required this.userId,
    required this.location,
    required this.lastUpdate,
  });
}
