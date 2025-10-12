// Alternative approach if you don't want to create profiles table yet
Future<List<CircleMembersModel>> getCircleMembers(String circleId) async {
  try {
    // 1) First, fetch circle members
    final response = await _supabase
        .from('circle_members')
        .select('user_id, role')
        .eq('circle_id', circleId);

    // 2) Get user IDs
    final userIds = (response as List<dynamic>)
        .map((item) => item['user_id'] as String)
        .toList();

    if (userIds.isEmpty) return [];

    // 3) Fetch user details from auth.users using the admin client or RPC
    // Since we can't directly query auth.users from client,
    // you'll need to create an RPC function in Supabase

    // For now, return with placeholder names
    final members = (response).map((item) {
      return CircleMembersModel(
        userId: item['user_id'] as String,
        name:
            'User ${item['user_id'].toString().substring(0, 8)}', // Placeholder
        role: item['role'] as String,
      );
    }).toList();

    return members;
  } catch (e) {
    debugPrint('Error fetching circle members: $e');
    return [];
  }
}
