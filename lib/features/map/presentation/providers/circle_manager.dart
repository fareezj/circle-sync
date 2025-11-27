// Flutter imports
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local imports
import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';

/// Result class for loading circles
class CircleLoadResult {
  final CircleModel? selectedCircle;
  final List<CircleModel> allCircles;

  CircleLoadResult({
    this.selectedCircle,
    required this.allCircles,
  });

  bool get hasCircles => allCircles.isNotEmpty;
  bool get hasSelectedCircle => selectedCircle != null;
}

/// Manages circle-related operations for the map feature
class CircleManager {
  final Ref ref;
  final CircleUsecase circleUsecase;

  CircleManager(this.ref, this.circleUsecase);

  /// Loads the initial circle for the user
  Future<CircleLoadResult> loadInitialCircle({
    bool getLatestCircle = false,
  }) async {
    try {
      final result = await circleUsecase.getJoinedCircles(ref);

      return result.fold(
        (failure) {
          debugPrint('Failed to load circles: ${failure.errorMessage}');
          return CircleLoadResult(allCircles: []);
        },
        (circles) async {
          if (circles.isEmpty) {
            return CircleLoadResult(allCircles: []);
          }

          final selectedCircle = await _selectCircle(circles, getLatestCircle);
          await _saveCurrentCircleId(selectedCircle.id);

          return CircleLoadResult(
            selectedCircle: selectedCircle,
            allCircles: circles,
          );
        },
      );
    } catch (e) {
      debugPrint('Error loading initial circle: $e');
      return CircleLoadResult(allCircles: []);
    }
  }

  /// Gets circle members for a specific circle
  Future<List<CircleMembersModel>> getCircleMembers(String circleId) async {
    try {
      final result = await circleUsecase.getCircleMembers(circleId);

      return result.fold(
        (failure) {
          debugPrint('Failed to load members: ${failure.errorMessage}');
          return <CircleMembersModel>[];
        },
        (members) => members,
      );
    } catch (e) {
      debugPrint('Error getting circle members: $e');
      return <CircleMembersModel>[];
    }
  }

  /// Gets current user information
  Future<CircleMembersModel?> getCurrentUserInfo() async {
    try {
      final username = await ref.read(getUsernameProvider.future);
      final userId = await ref.read(getUserIdProvider.future);

      if (username != null && userId != null) {
        return CircleMembersModel(
          userId: userId,
          name: username,
          role: 'member', // Default role
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user info: $e');
      return null;
    }
  }

  /// Selects which circle to use (latest or saved)
  Future<CircleModel> _selectCircle(
    List<CircleModel> circles,
    bool getLatestCircle,
  ) async {
    if (getLatestCircle) {
      // Get the most recently created circle
      return circles.reduce(
        (a, b) => a.dateCreated.isAfter(b.dateCreated) ? a : b,
      );
    }

    // Try to load the previously saved circle
    try {
      final savedCircleId = await ref.read(getCurrentCircleId.future);
      if (savedCircleId != null) {
        final savedCircle = circles.firstWhere(
          (circle) => circle.id == savedCircleId,
          orElse: () => circles.first,
        );
        return savedCircle;
      }
    } catch (e) {
      debugPrint('Error loading saved circle: $e');
    }

    // Fallback to first circle
    return circles.first;
  }

  /// Saves the current circle ID to secure storage
  Future<void> _saveCurrentCircleId(String circleId) async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.writeData('currentCircleId', circleId);
    } catch (e) {
      debugPrint('Error saving current circle ID: $e');
    }
  }
}
