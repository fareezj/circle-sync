// Dart imports
import 'dart:convert';
import 'dart:io';

// Flutter imports
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

// Local imports
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/services/location_service.dart';

/// Manages post-related operations for the map feature
class PostsManager {
  final LocationService _locationService = LocationService();

  /// Adds a new post to the database
  Future<void> addPost(PostModel post) async {
    try {
      await _locationService.addPost(post: post);
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow;
    }
  }

  /// Subscribes to posts updates for a specific circle
  void subscribeToPostsUpdates({
    required String circleId,
    required Function(Map<String, PostModel>) onPostsUpdate,
  }) {
    try {
      _locationService.subscribeToPost(
        circleId: circleId,
        onPostsUpdate: onPostsUpdate,
      );
    } catch (e) {
      debugPrint('Error subscribing to posts: $e');
    }
  }

  /// Processes and validates an image file for posting
  Future<File?> processImageForPost(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked == null) return null;

      final file = File(picked.path);

      // Validate file size (optional - you can add limits)
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;

      // Example: limit to 10MB
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Image file is too large. Maximum size is 10MB.');
      }

      // Validate MIME type (optional)
      final mimeType = lookupMimeType(picked.path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        throw Exception('Selected file is not a valid image.');
      }

      return file;
    } catch (e) {
      debugPrint('Error processing image: $e');
      rethrow;
    }
  }

  /// Converts an image file to base64 string
  Future<String?> convertImageToBase64(File? imageFile) async {
    try {
      if (imageFile == null) return null;

      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      return null;
    }
  }
}
