import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  Future<List<LatLng>> getRoute(
      double startLat, double startLon, double endLat, double endLon) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> coordinates = data["routes"][0]["geometry"]["coordinates"];
      return coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();
    } else {
      throw Exception('Failed to load route');
    }
  }
}
