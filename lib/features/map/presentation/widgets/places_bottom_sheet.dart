import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/utils/coordinate_extractor.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class PlacesBottomSheet extends ConsumerStatefulWidget {
  final List<PlacesModel> placeList;
  final Function(LatLng) onClickPlace;
  final VoidCallback onClickAddPlace;
  const PlacesBottomSheet({
    super.key,
    required this.placeList,
    required this.onClickPlace,
    required this.onClickAddPlace,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PlacesBottomSheetState();
}

class _PlacesBottomSheetState extends ConsumerState<PlacesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextWidgets.mainSemiBold(title: 'Places'),
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.placeList.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final location = widget.placeList[index].centerGeography;
                    final latLng = LatLngExtractor.extractLatLng(location);
                    print(latLng);
                    widget.onClickPlace(latLng);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: TextWidgets.mainRegular(
                          title: widget.placeList[index].title,
                        ),
                      ),
                      Expanded(
                        child: TextWidgets.mainRegular(
                          title: widget.placeList[index].centerGeography,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ElevatedButton(
                onPressed: () => widget.onClickAddPlace(),
                child: Text('Add places')),
          ],
        ),
      ),
    );
  }
}
