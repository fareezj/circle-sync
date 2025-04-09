import 'package:circle_sync/models/map_state_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final MapState mapState;
  final bool hasCircle;
  final VoidCallback onCurrentLocationTap;
  final Function(String, LatLng) onOtherUserTap;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.mapState,
    required this.hasCircle,
    required this.onCurrentLocationTap,
    required this.onOtherUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: mapState.currentLocation ?? LatLng(0, 0),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.yourapp',
        ),
        if (hasCircle && mapState.osrmRoutePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: mapState.osrmRoutePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        if (hasCircle && mapState.trackingPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: mapState.trackingPoints,
                strokeWidth: 3.0,
                color: Colors.orange,
              ),
            ],
          ),
        if (hasCircle)
          MarkerLayer(
            markers: mapState.otherUsersLocations.entries.map((entry) {
              return Marker(
                point: entry.value,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => onOtherUserTap(entry.key, entry.value),
                  child: Stack(
                    children: [
                      const Icon(Icons.person_pin_circle,
                          color: Colors.red, size: 40),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        MarkerLayer(
          markers: [
            if (mapState.currentLocation != null)
              Marker(
                point: mapState.currentLocation!,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: onCurrentLocationTap,
                  child: Stack(
                    children: [
                      const Icon(Icons.my_location,
                          color: Colors.green, size: 30),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasCircle && mapState.destinationLocation != null)
              Marker(
                point: mapState.destinationLocation!,
                child:
                    const Icon(Icons.location_pin, color: Colors.red, size: 30),
              ),
          ],
        ),
      ],
    );
  }
}
