import 'package:circle_sync/features/circles/data/models/circle_model.dart';
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

  Future<void> joinCircle(String joinCode) async {
    try {
      print('JOIN CODE: $joinCode');
      // 1) Lookup the circle by code
      final circle = await _supabase
          .from('circles')
          .select('circle_id')
          .eq('join_code', joinCode)
          .maybeSingle();

      if (circle != null) {
        // 2) Insert membership
        await _supabase.from('circle_members').insert({
          'circle_id': circle['circle_id'],
          'user_id': _supabase.auth.currentUser!.id,
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> getCircles() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

// 1) Query circle_members + FK-join into circles
      final response = await _supabase.from('circle_members').select(r'''
      circle_id,
      circles (        
        circle_id,
        name,
        members,
        created_by,
        date_created
      )
    ''').eq('user_id', userId);

// 2) Pull out the raw rows
      final rows = response;

// 3) Check if they’ve joined anything
      final hasJoinedAny = rows.isNotEmpty;

      if (!hasJoinedAny) {
        print('User has not joined any circles');
        // you can return [] or handle the “none joined” case here
      } else {
        // 4) Map each nested circles object into your model
        final joinedCircles = rows.map((r) {
          final c = r['circles'] as Map<String, dynamic>;
          return CircleModel.fromMap(c);
        }).toList();

        print('User has joined ${joinedCircles.length} circles:');
        for (var c in joinedCircles) {
          print(' • ${c.name} (id=${c.id})');
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<List<CircleMembersModel>> getCircleMembers(String circleId) async {
    try {
      // 1) Fetch circle members + join on users to get name
      final response = await _supabase.from('circle_members').select('''
    user_id,
    role,
    users ( name )
  ''').eq('circle_id', circleId);

      // 2) Map the result into your model
      final members = (response as List<dynamic>).map((item) {
        return CircleMembersModel(
          userId: item['user_id'] as String,
          name: (item['users'] as Map<String, dynamic>)['name'] as String,
          role: item['role'] as String,
        );
      }).toList();

      return members;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<List<CircleModel>> getJoinedCircles() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1) Query circle_members and FK-join into circles
      final response = await _supabase.from('circle_members').select(r'''
        circles (
          circle_id,
          name,
          members,
          created_by,
          date_created
        )
      ''').eq('user_id', userId);

      // 2) Unwrap & map into your CircleModel
      return response.map((row) {
        final json = row['circles'] as Map<String, dynamic>;
        return CircleModel.fromMap(json);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching joined circles: $e');
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    // 1) Mark the invitation accepted and grab its circle_id & user_id
    final invite = await _supabase
        .from('circle_invitations')
        .update({'status': 'accepted'})
        .eq('invitation_id', invitationId)
        .select('circle_id,user_id')
        .single();
    final circleId = invite['circle_id'] as String;
    final userId = invite['user_id'] as String;

    // 2) Fetch the current members array
    final circleRow = await _supabase
        .from('circles')
        .select('members')
        .eq('circle_id', circleId)
        .single();
    final members = List<String>.from(circleRow['members'] as List);

    // 3) Only append if they’re not already in the list
    if (!members.contains(userId)) {
      members.add(userId);

      // 4) Upsert on the primary key, merging only the members field
      await _supabase.from('circles').upsert(
        {
          'circle_id': circleId,
          'members': members,
        },
        onConflict: 'circle_id', // use your PK here
      ).select(); // optional: returns the updated row
    }
  }

  /// 5. Decline an invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase
          .from('circle_invitations')
          .update({'status': 'declined'}).eq('invitation_id', invitationId);
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
      rows = await _supabase.from('circles').select().eq('user_id', userId);
      if (rows.isNotEmpty) {
        return rows.map((e) => CircleModel.fromMap(e)).toList();
      } else {
        return [];
      }
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
