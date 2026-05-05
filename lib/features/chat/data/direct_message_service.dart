import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/message.dart';
import '../domain/models/direct_conversation.dart';
import '../domain/models/user_search_result.dart';

class DirectMessageService {
  final supabase = Supabase.instance.client;

  /// Get all direct conversations for the current user
  Future<List<DirectConversation>> getDirectConversations() async {
    try {
      final response = await supabase.rpc('get_user_direct_conversations');

      if (response == null) return [];

      final conversations = (response as List).map((data) {
        return DirectConversation.fromJson(data);
      }).toList();

      return conversations;
    } catch (e) {
      throw Exception('Failed to load direct conversations: $e');
    }
  }

  /// Get or create a direct conversation with another user
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      final response = await supabase.rpc('get_or_create_direct_conversation', params: {
        'other_user_id': otherUserId,
      });

      if (response == null) {
        throw Exception('Failed to create conversation');
      }

      return response as String;
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  /// Get messages for a direct conversation
  Future<List<Message>> getDirectMessages(String conversationId) async {
    try {
      final response = await supabase.rpc('get_direct_messages_with_users', params: {
        'conversation_id_param': conversationId,
      });

      if (response == null) return [];

      final messages = (response as List).map((data) {
        return Message.fromJson({
          'id': data['id'],
          'circle_id': null, // Direct messages don't have circle_id
          'conversation_id': data['conversation_id'],
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
      throw Exception('Failed to load direct messages: $e');
    }
  }

  /// Send a direct message
  Future<Message> sendDirectMessage({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final messageData = {
        'conversation_id': conversationId,
        'user_id': userId,
        'content': content,
        'type': 'text',
        'message_type': 'direct',
      };

      // Add reply_to_id if provided
      if (replyToId != null) {
        messageData['parent_id'] = replyToId;
      }

      final response = await supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send direct message: $e');
    }
  }

  /// Search users for starting new conversations
  Future<List<UserSearchResult>> searchUsers(String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) return [];

      final response = await supabase.rpc('search_users_for_dm', params: {
        'search_term': searchTerm.trim(),
      });

      if (response == null) return [];

      final users = (response as List).map((data) {
        return UserSearchResult.fromJson(data);
      }).toList();

      return users;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get a single direct message (for replies and real-time)
  Future<Message?> getDirectMessage(String messageId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('''
            id,
            conversation_id,
            user_id,
            content,
            parent_id,
            created_at,
            users!inner(
              display_name,
              avatar_url,
              status,
              email
            )
          ''')
          .eq('id', messageId)
          .eq('message_type', 'direct')
          .single();

      final userData = response['users'] as Map<String, dynamic>;

      return Message.fromJson({
        'id': response['id'],
        'circle_id': null,
        'conversation_id': response['conversation_id'],
        'user_id': response['user_id'],
        'content': response['content'],
        'reply_to_id': response['parent_id'],
        'created_at': response['created_at'],
        'sender_name': userData['display_name'] ?? userData['email']?.split('@')[0],
        'sender_avatar': userData['avatar_url'],
        'sender_status': userData['status'],
      });
    } catch (e) {
      print('Error fetching direct message: $e');
      return null;
    }
  }

  /// Subscribe to new direct messages in a conversation
  RealtimeChannel subscribeToDirectMessages(
    String conversationId,
    void Function(Message message) onMessage,
  ) {
    final channel = supabase.channel('direct_messages:$conversationId');
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            // Only handle direct messages
            if (payload.newRecord['message_type'] == 'direct') {
              final message = await getDirectMessage(payload.newRecord['id'] as String);
              if (message != null) {
                onMessage(message);
              }
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to direct conversation updates
  RealtimeChannel subscribeToConversations(
    void Function() onUpdate,
  ) {
    final channel = supabase.channel('direct_conversations');
    
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_conversations',
          callback: (payload) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'message_type',
            value: 'direct',
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();

    return channel;
  }

  /// Delete a direct message
  Future<void> deleteDirectMessage(String messageId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('message_type', 'direct');
    } catch (e) {
      throw Exception('Failed to delete direct message: $e');
    }
  }

  /// Unsubscribe from messages
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await supabase.removeChannel(channel);
  }
}