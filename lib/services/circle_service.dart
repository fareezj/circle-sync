import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:circle_sync/models/circle_model.dart';

class CircleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. Create a new circle, return its ID
  Future<String> createCircle(String name, List<String> memberIds) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Insert and get back the new record
    final rows = await _supabase.from('circles').insert({
      'name': name,
      'created_by': user.id,
      'date_created': DateTime.now().toIso8601String(),
      'members': [user.id, ...memberIds],
    }).select(); // returns List<dynamic> :contentReference[oaicite:3]{index=3}

    // rows is List<dynamic>, so cast to List<Map>
    if (rows.isEmpty) {
      throw Exception('Failed to create circle');
    }
    final circleId = (rows.first)['circle_id'] as String;
    return circleId;
  }

  /// 2. Fetch one circle by ID
  Future<CircleModel> getCircle(String circleId) async {
    try {
      final row = await _supabase
          .from('circles')
          .select()
          .eq('circle_id', circleId)
          .single(); // returns Map<String, dynamic> :contentReference[oaicite:4]{index=4}

      return CircleModel.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception(
          'Failed to load circle: ${e.message}'); // thrown on error :contentReference[oaicite:5]{index=5}
    }
  }

  /// 3. Send an invitation
  Future<void> addMember(String circleId, String inviteeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('circle_invitations').insert({
        'circle_id': circleId,
        'user_id': inviteeId,
        'invited_by': user.id,
        'status': 'pending',
      });
      // insert throws on error; no need to check .error :contentReference[oaicite:6]{index=6}
    } catch (e) {
      throw Exception('Failed to send invitation: $e');
    }
  }

  /// 4. Accept an invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      // a) Mark invitation accepted & return updated row
      final updated = await _supabase
          .from('circle_invitations')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('invitation_id', invitationId)
          .single(); // Map<String,dynamic> :contentReference[oaicite:7]{index=7}

      final circleId = (updated)['circle_id'] as String;
      final userId = updated['user_id'] as String;

      // b) Fetch current members array
      final circleRow = await _supabase
          .from('circles')
          .select('members')
          .eq('circle_id', circleId)
          .single();

      final members = List<String>.from((circleRow)['members']);

      // c) Append if missing
      if (!members.contains(userId)) {
        members.add(userId);
        await _supabase
            .from('circles')
            .update({'members': members}).eq('circle_id', circleId);
      }
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// 5. Decline an invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase.from('circle_invitations').update({
        'status': 'declined',
        'responded_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('invitation_id', invitationId);
    } catch (e) {
      throw Exception('Failed to decline invitation: $e');
    }
  }

  /// 6. List circles the user belongs to
  Future<List<CircleModel>> getUserCircles(String userId) async {
    List<Map<String, dynamic>> rows = [];
    // Returns List<dynamic>
    print('Getting user circle: $userId');

    try {
      rows = await _supabase.from('circles').select();

      print(rows);
    } catch (e) {
      print(e);
    }

    return (rows as List)
        .map((e) => CircleModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// 7. List pending invitations for the user
  Future<List<Map<String, dynamic>>> getInvitations(String userId) async {
    final invites = await _supabase
        .from('circle_invitations')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending'); // List<dynamic>

    final details = <Map<String, dynamic>>[];
    for (final inv in invites as List) {
      final mapInv = inv as Map<String, dynamic>;
      final circleId = mapInv['circle_id'] as String;
      final circRow = await _supabase
          .from('circles')
          .select()
          .eq('circle_id', circleId)
          .single(); // Map<String,dynamic>

      details.add({
        'invitationId': mapInv['invitation_id'],
        'circle': CircleModel.fromMap(circRow),
        'invitedBy': mapInv['invited_by'],
        'invitedAt': mapInv['invited_at'],
      });
    }
    return details;
  }

  /// 8. Combined info
  Future<Map<String, dynamic>> getCircleInfo() async {
    final user = _supabase.auth.currentUser;

    print('Getting user circle info');
    print(user);

    if (user == null) {
      return {
        'joinedCircles': <CircleModel>[],
        'invitations': <Map<String, dynamic>>[],
      };
    }
    final circles = await getUserCircles(user.id);
    final invites = await getInvitations(user.id);
    return {
      'joinedCircles': circles,
      'invitations': invites,
    };
  }
}
