// If using profiles table approach:
Future<List<CircleMembersModel>> getCircleMembers(String circleId) async {
  try {
    // 1) Fetch circle members + join on profiles to get name
    final response = await _supabase.from('circle_members').select('''
      user_id,
      role,
      profiles ( name )
    ''').eq('circle_id', circleId);

    // 2) Map the result into your model
    final members = (response as List<dynamic>).map((item) {
      return CircleMembersModel(
        userId: item['user_id'] as String,
        name: (item['profiles'] as Map<String, dynamic>)['name'] as String,
        role: item['role'] as String,
      );
    }).toList();

    return members;
  } catch (e) {
    debugPrint('Error fetching circle members: $e');
    return [];
  }
}
