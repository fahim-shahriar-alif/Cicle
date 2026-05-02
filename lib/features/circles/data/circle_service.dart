import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/circle.dart';
import '../domain/models/circle_member.dart';

class CircleService {
  final supabase = Supabase.instance.client;

  /// Get all circles for the current user
  Future<List<Circle>> getUserCircles() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('circles')
          .select('''
            *,
            circle_members!inner(user_id)
          ''')
          .eq('circle_members.user_id', userId)
          .order('created_at', ascending: false);

      // Get member counts for each circle
      final circles = <Circle>[];
      for (var circleData in response) {
        final memberCountResponse = await supabase
            .from('circle_members')
            .select('id')
            .eq('circle_id', circleData['id']);
        
        circles.add(Circle.fromJson({
          ...circleData,
          'member_count': memberCountResponse.length,
        }));
      }

      return circles;
    } catch (e) {
      throw Exception('Failed to load circles: $e');
    }
  }

  /// Create a new circle
  Future<Circle> createCircle({
    required String name,
    String? description,
    bool isDefault = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create circle
      final circleResponse = await supabase
          .from('circles')
          .insert({
            'name': name,
            'description': description,
            'created_by': userId,
            'is_default': isDefault,
          })
          .select()
          .single();

      // Add creator as admin member
      await supabase.from('circle_members').insert({
        'circle_id': circleResponse['id'],
        'user_id': userId,
        'role': 'admin',
      });

      return Circle.fromJson({...circleResponse, 'member_count': 1});
    } catch (e) {
      throw Exception('Failed to create circle: $e');
    }
  }

  /// Get circle by ID
  Future<Circle> getCircle(String circleId) async {
    try {
      final response = await supabase
          .from('circles')
          .select()
          .eq('id', circleId)
          .single();

      final memberCountResponse = await supabase
          .from('circle_members')
          .select('id')
          .eq('circle_id', circleId);

      return Circle.fromJson({
        ...response,
        'member_count': memberCountResponse.length,
      });
    } catch (e) {
      throw Exception('Failed to load circle: $e');
    }
  }

  /// Get members of a circle
  Future<List<CircleMember>> getCircleMembers(String circleId) async {
    try {
      final response = await supabase
          .from('circle_members')
          .select('''
            *,
            users!inner(
              display_name,
              email,
              avatar_url,
              status
            )
          ''')
          .eq('circle_id', circleId)
          .order('joined_at', ascending: true);

      return response.map((data) {
        final userData = data['users'];
        return CircleMember.fromJson({
          ...data,
          'display_name': userData['display_name'],
          'email': userData['email'],
          'avatar_url': userData['avatar_url'],
          'status': userData['status'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load members: $e');
    }
  }

  /// Add member to circle
  Future<void> addMember({
    required String circleId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      await supabase.from('circle_members').insert({
        'circle_id': circleId,
        'user_id': userId,
        'role': role,
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Remove member from circle
  Future<void> removeMember({
    required String circleId,
    required String userId,
  }) async {
    try {
      await supabase
          .from('circle_members')
          .delete()
          .eq('circle_id', circleId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Update circle
  Future<void> updateCircle({
    required String circleId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return;

      await supabase
          .from('circles')
          .update(updates)
          .eq('id', circleId);
    } catch (e) {
      throw Exception('Failed to update circle: $e');
    }
  }

  /// Delete circle
  Future<void> deleteCircle(String circleId) async {
    try {
      // Members will be deleted automatically via CASCADE
      await supabase
          .from('circles')
          .delete()
          .eq('id', circleId);
    } catch (e) {
      throw Exception('Failed to delete circle: $e');
    }
  }

  /// Check if user is admin of circle
  Future<bool> isUserAdmin(String circleId, String userId) async {
    try {
      final response = await supabase
          .from('circle_members')
          .select('role')
          .eq('circle_id', circleId)
          .eq('user_id', userId)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Create default "Duo Space" circle for new users
  Future<Circle> createDuoSpace() async {
    return await createCircle(
      name: 'The Duo Space',
      description: 'Your private space together ❤️',
      isDefault: true,
    );
  }
}
