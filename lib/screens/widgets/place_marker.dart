import 'package:circle_sync/screens/widgets/custom_marker.dart';
import 'package:circle_sync/utils/app_colors.dart';
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
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isSelected)
          Transform.translate(
            offset: const Offset(0, 0), // Move label upward
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  child: TextWidgets.mainBold(
                      title: place.title,
                      textAlign: TextAlign.center,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.blueBorder, // your dark green
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.landscape_outlined,
              color: AppColors.white,
            )),
        ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            width: 16,
            height: 12,
            color: AppColors.blueBorder,
          ),
        ),
      ],
    );
  }
}
