import 'dart:io';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void addPostDialog({
  required BuildContext context,
  required VoidCallback onClickGallery,
  required VoidCallback onClickCamera,
  File? chosenImage,
  required Function(String, DateTime) onCreate, // Updated to include DateTime
}) {
  TextEditingController controller = TextEditingController();
  DateTime selectedTime = DateTime.now(); // Move outside to preserve state

  // Validation state variables - declared here to persist
  String? textError;
  String? imageError;

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Consumer(
          builder: (context, ref, child) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.blueBorder,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Create New Post',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
              content: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.9, // 90% of screen width
                height: MediaQuery.of(context).size.height *
                    0.7, // 70% of screen height
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Post Title',
                            hintText: 'What\'s on your mind?',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: textError != null
                                    ? Colors.red
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: textError != null
                                    ? Colors.red
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: textError != null
                                    ? Colors.red
                                    : AppColors.blueBorder,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      // Text field error message
                      if (textError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                textError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Time Picker Section
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
                                  Icons.access_time,
                                  color: AppColors.blueBorder,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Post Time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Time Options
                            Row(
                              children: [
                                // Now Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedTime = DateTime.now();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                                Colors.green.withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Now',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Custom Time Button
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final TimeOfDay? picked =
                                          await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: AppColors.blueBorder,
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          selectedTime = DateTime(
                                            selectedTime.year,
                                            selectedTime.month,
                                            selectedTime.day,
                                            picked.hour,
                                            picked.minute,
                                          );
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.blueBorder
                                                .withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.access_time_outlined,
                                            color: AppColors.blueBorder,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Pick Time',
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

                            // Selected time display
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.blueBorder.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.blueBorder,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Selected: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: AppColors.blueBorder,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Photo Section
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.blueBorder
                                                .withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
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
                                      onClickCamera();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.blueBorder
                                                .withOpacity(0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
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

                      const SizedBox(height: 16),

                      // Image Preview Section
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: imageError != null
                                ? Colors.red
                                : Colors.grey[300]!,
                            style: BorderStyle.solid,
                            width: imageError != null ? 2 : 1.5,
                          ),
                        ),
                        child: ref.watch(mapNotifierProvider).chosenPostImage !=
                                null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Image.file(
                                      ref
                                          .watch(mapNotifierProvider)
                                          .chosenPostImage!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    // Remove image button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          // Clear the chosen image
                                          ref
                                              .read(
                                                  mapNotifierProvider.notifier)
                                              .clearChosenImage();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: imageError != null
                                          ? Colors.red
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No image selected',
                                      style: TextStyle(
                                        color: imageError != null
                                            ? Colors.red
                                            : Colors.grey[500],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap camera or gallery above',
                                      style: TextStyle(
                                        color: imageError != null
                                            ? Colors.red
                                            : Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      // Image error message
                      if (imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                imageError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Input validation guard
                            final postText = controller.text.trim();
                            final hasImage = ref
                                    .watch(mapNotifierProvider)
                                    .chosenPostImage !=
                                null;

                            // Check validations
                            String? newTextError;
                            String? newImageError;

                            if (postText.isEmpty) {
                              newTextError = 'Please enter a post title';
                            }

                            if (!hasImage) {
                              newImageError =
                                  'Please select an image for your post';
                            }

                            // If there are any errors, update the state to show them
                            if (newTextError != null || newImageError != null) {
                              setState(() {
                                textError = newTextError;
                                imageError = newImageError;
                              });
                              return; // Stop execution if validation fails
                            }

                            // Clear any previous errors and create the post
                            setState(() {
                              textError = null;
                              imageError = null;
                            });
                            onCreate(postText, selectedTime);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blueBorder,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Create Post',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
