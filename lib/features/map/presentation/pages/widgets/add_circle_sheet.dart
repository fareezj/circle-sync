import 'package:circle_sync/features/circles/presentation/providers/circle_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCircleSheet extends ConsumerStatefulWidget {
  const AddCircleSheet({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Circle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _circleNameController,
            decoration: InputDecoration(
              labelText: 'Circle Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Circle Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Handle circle creation logic here
              Navigator.pop(context);
              ref
                  .read(circleNotifierProvider.notifier)
                  .createCircle(_circleNameController.text);
            },
            child: const Text('Create Circle'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
