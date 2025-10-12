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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: AppColors.blueBorder,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gallery and Camera Buttons
                  Row(
                    children: [
                      // Gallery Button
                      Expanded(
                        child: GestureDetector(
                          onTap: onClickGallery,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.blueBorder.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  color: AppColors.blueBorder,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gallery',
                                  style: TextStyle(
                                    color: AppColors.blueBorder,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Camera Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onClickCamera();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.blueBorder.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppColors.blueBorder,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Camera',
                                  style: TextStyle(
                                    color: AppColors.blueBorder,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
