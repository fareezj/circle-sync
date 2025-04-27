import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/utils/coordinate_extractor.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class PlacesBottomSheet extends ConsumerStatefulWidget {
  final List<PlacesModel> placeList;
  final Function(LatLng) onClickPlace;
  const PlacesBottomSheet(
      {super.key, required this.placeList, required this.onClickPlace});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PlacesBottomSheetState();
}

class _PlacesBottomSheetState extends ConsumerState<PlacesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextWidgets.mainSemiBold(title: 'Places'),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.placeList.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final location = widget.placeList[index].centerGeography;
                  print('MEOW: $location');
                  final latLng = LatLngExtractor.extractLatLng(location);
                  widget.onClickPlace(latLng);
                },
                child: ListTile(
                  title: TextWidgets.mainRegular(
                    title: widget.placeList[index].title,
                  ),
                  trailing: TextWidgets.mainRegular(
                    title: widget.placeList[index].centerGeography,
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
