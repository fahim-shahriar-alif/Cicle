import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/demand.dart';

class DemandService {
  final supabase = Supabase.instance.client;

  /// Get demands for a circle
  Future<List<Demand>> getCircleDemands(String circleId) async {
    try {
      final response = await supabase
          .from('demands')
          .select('''
            *,
            users!inner(
              display_name,
              avatar_url
            )
          ''')
          .eq('circle_id', circleId)
          .order('created_at', ascending: false);

      return response.map((data) {
        final userData = data['users'];
        return Demand.fromJson({
          ...data,
          'creator_name': userData['display_name'],
          'creator_avatar': userData['avatar_url'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load demands: $e');
    }
  }

  /// Get all demands for user's circles
  Future<List<Demand>> getUserDemands() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's circles
      final circlesResponse = await supabase
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId);

      final circleIds = circlesResponse
          .map((row) => row['circle_id'] as String)
          .toList();

      if (circleIds.isEmpty) return [];

      // Get demands from those circles
      final response = await supabase
          .from('demands')
          .select('''
            *,
            users!inner(
              display_name,
              avatar_url
            )
          ''')
          .inFilter('circle_id', circleIds)
          .order('created_at', ascending: false);

      return response.map((data) {
        final userData = data['users'];
        return Demand.fromJson({
          ...data,
          'creator_name': userData['display_name'],
          'creator_avatar': userData['avatar_url'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load demands: $e');
    }
  }

  /// Create a demand
  Future<Demand> createDemand({
    required String circleId,
    required String title,
    String? description,
    required String category,
    required String priority,
    DateTime? dueDate,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('demands')
          .insert({
            'circle_id': circleId,
            'user_id': userId,
            'title': title,
            'description': description,
            'category': category,
            'priority': priority,
            'status': 'pending',
            'due_date': dueDate?.toIso8601String(),
          })
          .select()
          .single();

      return Demand.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create demand: $e');
    }
  }

  /// Update demand status
  Future<void> updateDemandStatus(String demandId, String status) async {
    try {
      await supabase
          .from('demands')
          .update({'status': status})
          .eq('id', demandId);
    } catch (e) {
      throw Exception('Failed to update demand: $e');
    }
  }

  /// Delete demand
  Future<void> deleteDemand(String demandId) async {
    try {
      await supabase
          .from('demands')
          .delete()
          .eq('id', demandId);
    } catch (e) {
      throw Exception('Failed to delete demand: $e');
    }
  }

  /// Toggle demand completion
  Future<void> toggleDemandCompletion(String demandId, bool isCompleted) async {
    await updateDemandStatus(
      demandId,
      isCompleted ? 'completed' : 'pending',
    );
  }

  /// Add reaction to demand
  Future<void> addReaction(String demandId, String emoji) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await supabase.from('demand_reactions').insert({
        'demand_id': demandId,
        'user_id': userId,
        'emoji': emoji,
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Remove reaction
  Future<void> removeReaction(String demandId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from('demand_reactions')
          .delete()
          .eq('demand_id', demandId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }
}
