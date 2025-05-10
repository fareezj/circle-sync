import 'package:circle_sync/models/circle_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircleListSheet extends ConsumerStatefulWidget {
  final Function(CircleModel) onCircleTap;
  final List<CircleModel> circleList;

  const CircleListSheet(
      {super.key, required this.onCircleTap, required this.circleList});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CircleListSheetState();
}

class _CircleListSheetState extends ConsumerState<CircleListSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Circles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Handle add circle action
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // List of circles will be displayed here
          Expanded(
            child: ListView.builder(
              itemCount:
                  widget.circleList.length, // Replace with actual circle count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(widget.circleList[index]
                      .name), // Replace with actual circle name
                  onTap: () {
                    widget.onCircleTap(widget.circleList[index]);
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
