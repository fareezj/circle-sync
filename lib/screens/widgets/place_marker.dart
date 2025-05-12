import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';

class PlaceMarker extends StatelessWidget {
  final PlacesModel place;
  final bool isSelected;

  const PlaceMarker({
    super.key,
    required this.place,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          Transform.translate(
            offset: const Offset(0, -10), // Move label upward
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextWidgets.mainBold(title: place.title, fontSize: 20),
            ),
          ),
        const Icon(
          Icons.place,
          size: 30,
          color: Colors.red,
        ),
      ],
    );
  }
}
