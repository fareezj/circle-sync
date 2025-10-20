import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:circle_sync/features/circles/data/datasources/circle_service.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CircleBottomSheet extends StatefulWidget {
  final VoidCallback onCreateCircle;
  final MapController mapController;

  const CircleBottomSheet({
    super.key,
    required this.onCreateCircle,
    required this.mapController,
  });

  @override
  State<CircleBottomSheet> createState() => _CircleBottomSheetState();
}

class _CircleBottomSheetState extends State<CircleBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CircleService _circleService = CircleService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedCircle = ref.watch(mapNotifierProvider).selectedCircle;
        final hasCircle = ref.watch(mapNotifierProvider).hasCircle;
        final circleMembers = ref.watch(mapNotifierProvider).circleMembers;
        final joinedCircles = ref.watch(mapNotifierProvider).joinedCircles;

        // Safe access to owner name
        String ownerName = 'Unknown';
        if (circleMembers.isNotEmpty) {
          try {
            final owner = circleMembers.firstWhere(
              (member) => member.userId == selectedCircle?.createdBy,
              orElse: () =>
                  CircleMembersModel(userId: '', name: 'Unknown', role: ''),
            );
            ownerName = owner.name;
          } catch (e) {
            ownerName = 'Unknown';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Current Circle Info (if has circle)
              if (hasCircle)
                _buildCurrentCircleInfo(
                    selectedCircle, ownerName, circleMembers),

              const SizedBox(height: 16),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.blueBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  tabs: const [
                    Tab(text: 'My Circles'),
                    Tab(text: 'Create'),
                    Tab(text: 'Join'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyCirclesTab(joinedCircles, ref),
                    _buildCreateCircleTab(ref),
                    _buildJoinCircleTab(ref),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentCircleInfo(CircleModel? selectedCircle, String ownerName,
      List<CircleMembersModel> circleMembers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueBorder.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blueBorder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.group,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidgets.mainBold(
                  title: selectedCircle?.name ?? 'Current Circle',
                  fontSize: 16.0,
                ),
                const SizedBox(height: 4),
                TextWidgets.mainSemiBold(
                  title: 'Created by: $ownerName',
                  fontSize: 12.0,
                ),
                if (selectedCircle?.dateCreated != null)
                  TextWidgets.mainSemiBold(
                    title:
                        'Created: ${DateFormat('dd MMM yyyy').format(selectedCircle!.dateCreated)}',
                    fontSize: 12.0,
                  ),
                TextWidgets.mainSemiBold(
                  title: 'Members: ${circleMembers.length}',
                  fontSize: 12.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCirclesTab(List<CircleModel> circles, WidgetRef ref) {
    if (circles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            TextWidgets.mainSemiBold(
              title: 'No circles yet',
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a circle to get started',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: circles.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final circle = circles[index];
        final isSelected =
            ref.watch(mapNotifierProvider).selectedCircle?.id == circle.id;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blueBorder.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blueBorder : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.group,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            title: TextWidgets.mainBold(title: circle.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidgets.mainSemiBold(
                  title:
                      'Created: ${DateFormat('dd MMM').format(circle.dateCreated)}',
                  fontSize: 12.0,
                ),
                FutureBuilder<int>(
                  future: _getCircleMemberCount(circle.id),
                  builder: (context, snapshot) {
                    final memberCount = snapshot.data ?? 0;
                    return TextWidgets.mainSemiBold(
                      title: 'Members: $memberCount',
                      fontSize: 12.0,
                    );
                  },
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: AppColors.blueBorder)
                : Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            onTap: isSelected ? null : () => _switchToCircle(circle, ref),
          ),
        );
      },
    );
  }

  Widget _buildCreateCircleTab(WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48,
            color: AppColors.blueBorder,
          ),
          const SizedBox(height: 16),
          TextWidgets.mainBold(title: 'Create New Circle', fontSize: 18),
          const SizedBox(height: 8),
          Text(
            'Start a new circle to share your location with friends and family',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Circle Name',
              hintText: 'Enter circle name...',
              prefixIcon: Icon(Icons.group, color: AppColors.blueBorder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.blueBorder, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _createCircle(nameController.text, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueBorder,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  TextWidgets.mainBold(
                      title: 'Create Circle', color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCircleTab(WidgetRef ref) {
    final TextEditingController codeController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.group_add,
            size: 48,
            color: AppColors.blueBorder,
          ),
          const SizedBox(height: 16),
          TextWidgets.mainBold(title: 'Join Existing Circle', fontSize: 18),
          const SizedBox(height: 8),
          Text(
            'Enter a circle code or ID to join an existing circle',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: 'Circle ID or Code',
              hintText: 'Enter circle ID...',
              prefixIcon: Icon(Icons.qr_code, color: AppColors.blueBorder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.blueBorder, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _joinCircle(codeController.text, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_add, size: 20),
                  const SizedBox(width: 8),
                  TextWidgets.mainBold(
                      title: 'Join Circle', color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCircle(String name, WidgetRef ref) async {
    if (name.trim().isEmpty) {
      _showError('Please enter a circle name');
      return;
    }

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        _showError('User not authenticated');
        return;
      }

      await _circleService.createCircle(name.trim());
      // Refresh the circles list to pick up the new circle
      await ref
          .read(mapNotifierProvider.notifier)
          .loadInitialCircle(getLatestCircle: true);

      _showSuccess('Circle "$name" created successfully!');
      _tabController.animateTo(0); // Switch to My Circles tab
    } catch (e) {
      _showError('Failed to create circle: $e');
    }
  }

  Future<void> _joinCircle(String circleId, WidgetRef ref) async {
    if (circleId.trim().isEmpty) {
      _showError('Please enter a circle ID');
      return;
    }

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        _showError('User not authenticated');
        return;
      }

      // Try to get the circle to see if it exists
      CircleModel circle;
      try {
        circle = await _circleService.getCircle(circleId.trim());
      } catch (e) {
        _showError('Circle not found');
        return;
      }

      await _circleService.addMember(circleId.trim(), currentUserId);
      // Refresh the circles list to update with the new joined circle
      await ref
          .read(mapNotifierProvider.notifier)
          .loadInitialCircle(getLatestCircle: true);

      _showSuccess('Successfully joined "${circle.name}"!');
      _tabController.animateTo(0); // Switch to My Circles tab
    } catch (e) {
      _showError('Failed to join circle: $e');
    }
  }

  Future<void> _switchToCircle(CircleModel circle, WidgetRef ref) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Switch to the selected circle by saving it as current and reloading
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.writeData('currentCircleId', circle.id);

      // Refresh the map with the new circle
      await ref.read(mapNotifierProvider.notifier).loadInitialCircle();
      await ref
          .read(mapNotifierProvider.notifier)
          .loadCircleDetails(circle, widget.mapController);

      _showSuccess('Switched to "${circle.name}"');
    } catch (e) {
      _showError('Failed to switch circle: $e');
    }
  }

  Future<int> _getCircleMemberCount(String circleId) async {
    try {
      final members = await _circleService.getCircleMembers(circleId);
      return members.length;
    } catch (e) {
      debugPrint('Error getting member count: $e');
      return 0;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
