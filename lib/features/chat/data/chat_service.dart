import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/message.dart';

class ChatService {
  final supabase = Supabase.instance.client;

  /// Get messages for a circle with real-time updates
  Stream<List<Message>> getMessagesStream(String circleId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  /// Get messages for a circle (one-time fetch)
  Future<List<Message>> getMessages(String circleId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('*')
          .eq('circle_id', circleId)
          .order('created_at', ascending: true);

      // Get user details separately for each message
      final messages = <Message>[];
      for (final data in response) {
        try {
          // Get user details from users table
          final userResponse = await supabase
              .from('users')
              .select('display_name, avatar_url, status')
              .eq('id', data['user_id'])
              .maybeSingle();

          messages.add(Message.fromJson({
            ...data,
            'sender_name': userResponse?['display_name'],
            'sender_avatar': userResponse?['avatar_url'],
            'sender_status': userResponse?['status'],
          }));
        } catch (e) {
          // If user fetch fails, add message without user details
          messages.add(Message.fromJson(data));
        }
      }

      return messages;
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required String circleId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final messageData = {
        'circle_id': circleId,
        'user_id': userId,
        'content': content,
        'type': 'text',
      };

      // Add reply_to_id if provided (requires reply_to_id column in database)
      if (replyToId != null) {
        messageData['reply_to_id'] = replyToId;
      }

      final response = await supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get a single message (for replies)
  Future<Message?> getMessage(String messageId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('*')
          .eq('id', messageId)
          .single();

      // Get user details from users table
      final userResponse = await supabase
          .from('users')
          .select('display_name, avatar_url, status')
          .eq('id', response['user_id'])
          .maybeSingle();

      return Message.fromJson({
        ...response,
        'sender_name': userResponse?['display_name'],
        'sender_avatar': userResponse?['avatar_url'],
        'sender_status': userResponse?['status'],
      });
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to new messages in a circle
  RealtimeChannel subscribeToMessages(
    String circleId,
    void Function(Message message) onMessage,
  ) {
    final channel = supabase.channel('messages:$circleId');
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'circle_id',
            value: circleId,
          ),
          callback: (payload) async {
            final message = await getMessage(payload.newRecord['id'] as String);
            if (message != null) {
              onMessage(message);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from messages
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await supabase.removeChannel(channel);
  }
}
