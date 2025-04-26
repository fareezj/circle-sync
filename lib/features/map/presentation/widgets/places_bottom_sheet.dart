import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlacesBottomSheet extends ConsumerStatefulWidget {
  final List<PlacesModel> placeList;
  const PlacesBottomSheet({super.key, required this.placeList});

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
            itemBuilder: (context, index) {
              return ListTile(
                title: TextWidgets.mainRegular(
                  title: widget.placeList[index].title,
                ),
                trailing: TextWidgets.mainRegular(
                  title: widget.placeList[index].centerGeography,
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
