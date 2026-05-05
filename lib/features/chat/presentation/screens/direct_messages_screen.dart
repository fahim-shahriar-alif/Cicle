import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/direct_message_service.dart';
import '../../domain/models/direct_conversation.dart';
import 'direct_chat_screen.dart';
import 'user_search_screen.dart';
import 'package:intl/intl.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final _directMessageService = DirectMessageService();
  final supabase = Supabase.instance.client;
  
  List<DirectConversation> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToConversations();
  }

  @override
  void dispose() {
    if (_channel != null) {
      _directMessageService.unsubscribe(_channel!);
    }
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() => _isLoading = true);
      final conversations = await _directMessageService.getDirectConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  void _subscribeToConversations() {
    _channel = _directMessageService.subscribeToConversations(() {
      _loadConversations();
    });
  }

  Future<void> _startNewChat() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const UserSearchScreen(),
      ),
    );

    if (result != null) {
      // User selected someone to chat with
      try {
        final conversationId = await _directMessageService.getOrCreateConversation(result);
        
        if (mounted) {
          // Navigate directly to the chat screen
          // The chat screen will load the user details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectChatScreen(
                conversationId: conversationId,
                otherUserName: 'Loading...', // Will be updated in the chat screen
                otherUserId: result,
              ),
            ),
          );
          
          // Refresh conversations list to show the new conversation
          _loadConversations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting chat: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : _conversations.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadConversations,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    return _buildConversationTile(conversation);
                  },
                ),
              );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation with someone!',
              style: TextStyle(
                color: Color(0xFF636E72),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(DirectConversation conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
          backgroundImage: conversation.otherUserAvatar != null
              ? NetworkImage(conversation.otherUserAvatar!)
              : null,
          child: conversation.otherUserAvatar == null
              ? Text(
                  conversation.otherUserName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversation.otherUserStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  conversation.otherUserStatus!,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6C5CE7).withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (conversation.latestMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.latestMessage!,
                      style: const TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (conversation.latestMessageTime != null)
                    Text(
                      _formatTime(conversation.latestMessageTime!),
                      style: const TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectChatScreen(
                conversationId: conversation.id,
                otherUserName: conversation.otherUserName,
                otherUserId: conversation.otherUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}