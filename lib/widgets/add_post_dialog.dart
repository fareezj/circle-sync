import 'dart:io';

import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void addPostDialog({
  required BuildContext context,
  required VoidCallback onClickGallery,
  required VoidCallback onClickCamera,
  File? chosenImage,
  required Function(String) onCreate,
}) {
  TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, child) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Add new post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter your post here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    onClickGallery();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.image),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextWidgets.mainRegular(
                              title: 'choose_from_gallery',
                              textAlign: TextAlign.start),
                        )
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onClickCamera();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.camera),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextWidgets.mainRegular(
                              title: 'take_picture',
                              textAlign: TextAlign.start),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (ref.watch(mapNotifierProvider).chosenPostImage != null)
              Image.file(
                ref.watch(mapNotifierProvider).chosenPostImage!,
                height: 100,
                width: double.maxFinite,
                fit: BoxFit.fitWidth,
              )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => onCreate(controller.text),
            child: const Text('Create'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
