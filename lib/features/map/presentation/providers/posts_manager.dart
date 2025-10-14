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

  // Cache for user names to avoid repeated database queries
  final Map<String, String> _userNamesCache = {};
  DateTime? _cacheLastUpdated;

  /// Adds a new post to the database
  Future<void> addPost(PostModel post) async {
    try {
      await _locationService.addPost(post: post);
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow;
    }
  }

  /// Subscribes to posts updates for a specific circle with enriched creator names
  void subscribeToPostsUpdates({
    required String circleId,
    required Function(Map<String, PostModel>) onPostsUpdate,
  }) {
    try {
      _locationService.subscribeToPost(
        circleId: circleId,
        onPostsUpdate: (posts) async {
          // Enrich posts with creator names before passing to callback
          final enrichedPosts = await enrichPostsWithCreatorNames(posts);
          onPostsUpdate(enrichedPosts);
        },
      );
    } catch (e) {
      debugPrint('Error subscribing to posts: $e');
    }
  }

  /// Fetches user names for a list of user IDs with caching
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    try {
      // Check cache validity (refresh every 10 minutes)
      final now = DateTime.now();
      final cacheValid = _cacheLastUpdated != null &&
          now.difference(_cacheLastUpdated!).inMinutes < 10;

      // Find user IDs that are not in cache or cache is invalid
      final missingUserIds = <String>[];
      final result = <String, String>{};

      for (final userId in userIds) {
        if (cacheValid && _userNamesCache.containsKey(userId)) {
          result[userId] = _userNamesCache[userId]!;
        } else {
          missingUserIds.add(userId);
        }
      }

      // Fetch missing user names from database
      if (missingUserIds.isNotEmpty) {
        final freshUserNames =
            await _locationService.getUserNames(missingUserIds);

        // Update cache
        _userNamesCache.addAll(freshUserNames);
        _cacheLastUpdated = now;

        // Add to result
        result.addAll(freshUserNames);
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching user names: $e');
      return {};
    }
  }

  /// Clears the user names cache
  void clearUserNamesCache() {
    _userNamesCache.clear();
    _cacheLastUpdated = null;
  }

  /// Enriches posts with creator names
  Future<Map<String, PostModel>> enrichPostsWithCreatorNames(
    Map<String, PostModel> posts,
  ) async {
    if (posts.isEmpty) return posts;

    try {
      print('AWOW PSOT: $posts');
      // Get unique user IDs from all posts
      final userIds = posts.values.map((post) => post.userId).toSet().toList();

      print('AWOW USER IDS: $userIds');

      // Fetch user names in batch
      final userNames = await getUserNames(userIds);

      print('AWOW NAME: $userNames');

      // Create enriched posts with creator names
      final Map<String, PostModel> enrichedPosts = {};
      posts.forEach((id, post) {
        final creatorName = userNames[post.userId] ?? 'Unknown User';
        enrichedPosts[id] = post.copyWith(creatorName: creatorName);
      });

      return enrichedPosts;
    } catch (e) {
      debugPrint('Error enriching posts with creator names: $e');
      // Return original posts if enrichment fails
      return posts;
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

  /// Gets posts for a specific circle with creator names (for initial loading)
  Future<Map<String, PostModel>> getPostsWithCreatorNames(
      String circleId) async {
    try {
      // First, get all posts for the circle
      // Note: You might need to add this method to LocationService if it doesn't exist
      // For now, this is a placeholder - you'd implement the actual query

      // This would be implemented as a direct query to get posts
      // Then enrich them with creator names
      debugPrint('Getting posts for circle: $circleId');

      // Placeholder - in real implementation, you'd query posts from database
      final Map<String, PostModel> posts = {};

      return await enrichPostsWithCreatorNames(posts);
    } catch (e) {
      debugPrint('Error getting posts with creator names: $e');
      return {};
    }
  }
}
