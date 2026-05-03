import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../circles/data/circle_service.dart';
import '../../../circles/domain/models/circle.dart';
import 'chat_screen.dart';

class CirclesChatList extends StatefulWidget {
  const CirclesChatList({super.key});

  @override
  State<CirclesChatList> createState() => _CirclesChatListState();
}

class _CirclesChatListState extends State<CirclesChatList> {
  final _circleService = CircleService();
  List<Circle> _circles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final circles = await _circleService.getUserCircles();
      
      // If no circles exist, create default Duo Space
      if (circles.isEmpty) {
        await _circleService.createDuoSpace();
        final updatedCircles = await _circleService.getUserCircles();
        setState(() {
          _circles = updatedCircles;
          _isLoading = false;
        });
      } else {
        setState(() {
          _circles = circles;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCircleDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Circle'),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
              const SizedBox(height: 16),
              const Text(
                'Unable to load chats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF636E72)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadCircles,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_circles.isEmpty) {
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
                padding: const EdgeInsets.all(20),
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
                'No chats yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a circle first to start chatting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF636E72),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCircles,
      color: const Color(0xFF6C5CE7),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _circles.length,
        itemBuilder: (context, index) {
          final circle = _circles[index];
          return _buildChatCard(circle);
        },
      ),
    );
  }

  Widget _buildChatCard(Circle circle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  circleId: circle.id,
                  circleName: circle.name,
                ),
              ),
            );
          },
          onLongPress: () {
            _showCircleOptions(circle);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: circle.isDefault
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: circle.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            circle.avatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          circle.isDefault
                              ? Icons.favorite_rounded
                              : Icons.groups_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        circle.description ?? 'Tap to start chatting',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF636E72),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${circle.memberCount} ${circle.memberCount == 1 ? 'member' : 'members'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                const Icon(
                  Icons.chat_bubble_rounded,
                  color: Color(0xFF6C5CE7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCircleOptions(Circle circle) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_rounded, color: Color(0xFF6C5CE7)),
              title: const Text('Invite User'),
              subtitle: const Text('Add someone to this circle'),
              onTap: () {
                Navigator.pop(context);
                _showInviteUserDialog(circle);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_rounded, color: Color(0xFF6C5CE7)),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      circleId: circle.id,
                      circleName: circle.name,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCircleDialog() async {
    final nameController = TextEditingController();
    final themeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Circle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Circle Name',
                hintText: 'e.g., Family, Friends, Work',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: themeController,
              decoration: const InputDecoration(
                labelText: 'Theme (optional)',
                hintText: 'e.g., Travel, Planning',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await _circleService.createCircle(
          name: nameController.text,
          type: 'themed',
          theme: themeController.text.isEmpty ? null : themeController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Circle created! 🎉')),
          );
        }
        
        _loadCircles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showInviteUserDialog(Circle circle) async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite to ${circle.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the email address of the user you want to invite:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty) {
      try {
        // Get user ID by email using the database function
        final supabase = Supabase.instance.client;
        
        final response = await supabase.rpc('get_user_id_by_email', params: {
          'email_param': emailController.text.trim(),
        });

        if (response == null || (response is List && response.isEmpty)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found. Make sure they have signed up first!')),
            );
          }
          return;
        }

        final userId = response is List ? response.first['user_id'] : response['user_id'];

        // Add user to circle
        await _circleService.addMember(
          circleId: circle.id,
          userId: userId,
          role: 'member',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${emailController.text} added to circle! 🎉')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().contains('duplicate') ? 'User is already in this circle' : e}')),
          );
        }
      }
    }
  }
}
