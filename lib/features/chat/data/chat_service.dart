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
      // Use database function to get messages with user details in one query
      final response = await supabase.rpc('get_messages_with_users', params: {
        'circle_id_param': circleId,
      });

      if (response == null) return [];

      final messages = (response as List).map((data) {
        return Message.fromJson({
          'id': data['id'],
          'circle_id': data['circle_id'],
          'user_id': data['user_id'],
          'content': data['content'],
          'reply_to_id': data['reply_to_id'],
          'created_at': data['created_at'],
          'sender_name': data['sender_name'],
          'sender_avatar': data['sender_avatar'],
          'sender_status': data['sender_status'],
        });
      }).toList();

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

  /// Get a single message (for replies and real-time)
  Future<Message?> getMessage(String messageId) async {
    try {
      // Use the database function to get message with user details
      final response = await supabase.rpc('get_message_with_user', params: {
        'message_id_param': messageId,
      });

      if (response == null || (response is List && response.isEmpty)) {
        return null;
      }

      final data = response is List ? response.first : response;

      return Message.fromJson({
        'id': data['id'],
        'circle_id': data['circle_id'],
        'user_id': data['user_id'],
        'content': data['content'],
        'reply_to_id': null,
        'created_at': data['created_at'],
        'sender_name': data['sender_name'],
        'sender_avatar': data['sender_avatar'],
        'sender_status': data['sender_status'],
      });
    } catch (e) {
      print('Error fetching message: $e');
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
