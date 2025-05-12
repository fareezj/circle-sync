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
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextWidgets.mainBold(title: 'Places', fontSize: 20.0),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => widget.onClickAddPlace(),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: widget.placeList.length,
              physics: ClampingScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  title: TextWidgets.mainSemiBold(
                      title: widget.placeList[index].title,
                      textAlign: TextAlign.start),
                  subtitle: TextWidgets.mainRegular(
                      title: widget.placeList[index].centerGeography,
                      textAlign: TextAlign.start),
                  onTap: () {
                    final location = widget.placeList[index].centerGeography;
                    final latLng = LatLngExtractor.extractLatLng(location);
                    print(latLng);
                    widget.onClickPlace(latLng);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
