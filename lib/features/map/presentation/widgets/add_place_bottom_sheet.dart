import 'dart:ffi';

import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddPlaceBottomSheet extends StatefulWidget {
  final LatLng initialCenter;
  final VoidCallback onClose;
  final Function(LatLng picked, String placeName) onSave;

  const AddPlaceBottomSheet({
    super.key,
    required this.onClose,
    required this.initialCenter,
    required this.onSave,
  });

  @override
  State<AddPlaceBottomSheet> createState() => _AddPlaceBottomSheetState();
}

class _AddPlaceBottomSheetState extends State<AddPlaceBottomSheet> {
  LatLng? _pickedLocation;
  final TextEditingController _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
                onPressed: () => widget.onClose(),
                icon: Icon(Icons.chevron_left)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child:
                TextWidgets.mainSemiBold(title: 'Tap to pick your new place'),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Place Name',
                hintText: 'Enter a name for your place',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),

          // 1) the map itself
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.initialCenter,
                  initialZoom: 13,
                  onTap: (tapPos, latlng) {
                    setState(() => _pickedLocation = latlng);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),

                  // show your picked pin
                  if (_pickedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pickedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  if (_pickedLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _pickedLocation!,
                          radius: 500, // in meters
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.2),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // 2) Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _pickedLocation == null
                  ? null
                  : () =>
                      widget.onSave(_pickedLocation!, _titleController.text),
              icon: const Icon(Icons.save),
              label: const Text('Save Location'),
            ),
          ),
        ],
      ),
    );
  }
}
