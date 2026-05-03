import 'package:supabase_flutter/supabase_flutter.dart';

class UnreadService {
  final supabase = Supabase.instance.client;

  /// Get unread message count for a circle
  Future<int> getUnreadCount(String circleId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get last seen timestamp for this circle
      final lastSeenResponse = await supabase
          .from('circle_members')
          .select('last_seen_at')
          .eq('circle_id', circleId)
          .eq('user_id', userId)
          .maybeSingle();

      final lastSeenAt = lastSeenResponse?['last_seen_at'];

      // Count messages after last seen
      final countResponse = await supabase
          .from('messages')
          .select('id', const FetchOptions(count: CountOption.exact, head: true))
          .eq('circle_id', circleId)
          .neq('user_id', userId); // Don't count own messages

      if (lastSeenAt != null) {
        // Only count messages after last seen
        final count = await supabase
            .from('messages')
            .select('id', const FetchOptions(count: CountOption.exact, head: true))
            .eq('circle_id', circleId)
            .neq('user_id', userId)
            .gt('created_at', lastSeenAt);
        
        return count.count ?? 0;
      }

      return countResponse.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get total unread count across all circles
  Future<int> getTotalUnreadCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get all user's circles
      final circlesResponse = await supabase
          .from('circle_members')
          .select('circle_id, last_seen_at')
          .eq('user_id', userId);

      int totalUnread = 0;

      for (final row in circlesResponse) {
        final circleId = row['circle_id'] as String;
        final lastSeenAt = row['last_seen_at'];

        if (lastSeenAt != null) {
          final count = await supabase
              .from('messages')
              .select('id', const FetchOptions(count: CountOption.exact, head: true))
              .eq('circle_id', circleId)
              .neq('user_id', userId)
              .gt('created_at', lastSeenAt);
          
          totalUnread += count.count ?? 0;
        } else {
          // If never seen, count all messages from others
          final count = await supabase
              .from('messages')
              .select('id', const FetchOptions(count: CountOption.exact, head: true))
              .eq('circle_id', circleId)
              .neq('user_id', userId);
          
          totalUnread += count.count ?? 0;
        }
      }

      return totalUnread;
    } catch (e) {
      print('Error getting total unread count: $e');
      return 0;
    }
  }

  /// Mark circle as read (update last_seen_at)
  Future<void> markAsRead(String circleId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('circle_members')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('circle_id', circleId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }
}
