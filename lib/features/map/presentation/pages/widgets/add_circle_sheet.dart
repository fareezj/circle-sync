import 'package:circle_sync/features/circles/presentation/providers/circle_providers.dart';
import 'package:circle_sync/features/map/presentation/routers/circle_navigation_router.dart';
import 'package:circle_sync/widgets/confirm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCircleSheet extends ConsumerStatefulWidget {
  final AddCircleArgs args;
  const AddCircleSheet({super.key, required this.args});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddCircleSheetState();
}

class _AddCircleSheetState extends ConsumerState<AddCircleSheet> {
  final TextEditingController _circleNameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
              onPressed: () {
                circleSheetNavKey.currentState!.pop();
              },
              icon: Icon(Icons.chevron_left)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Circle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _circleNameController,
            decoration: InputDecoration(
              labelText: 'Circle Name',
              border: OutlineInputBorder(),
            ),
          ),
          Spacer(),
          ConfirmButton(
            onClick: () async {
              await ref
                  .read(circleNotifierProvider.notifier)
                  .createCircle(ref, _circleNameController.text, () {
                widget.args.onAddedCircle();
              });
            },
            title: 'Create Circle',
          ),
        ],
      ),
    );
  }
}
