import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/circle_service.dart';
import '../../domain/models/circle.dart';
import '../../domain/models/circle_member.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class CircleDetailScreen extends StatefulWidget {
  final String circleId;

  const CircleDetailScreen({
    super.key,
    required this.circleId,
  });

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  final _circleService = CircleService();
  final supabase = Supabase.instance.client;
  
  Circle? _circle;
  List<CircleMember> _members = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCircleDetails();
  }

  Future<void> _loadCircleDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final circle = await _circleService.getCircle(widget.circleId);
      final members = await _circleService.getCircleMembers(widget.circleId);
      final userId = supabase.auth.currentUser?.id;
      final isAdmin = userId != null
          ? await _circleService.isUserAdmin(widget.circleId, userId)
          : false;

      setState(() {
        _circle = circle;
        _members = members;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editCircle() async {
    if (_circle == null) return;

    final nameController = TextEditingController(text: _circle!.name);
    final descriptionController = TextEditingController(
      text: _circle!.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Circle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Circle Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _circleService.updateCircle(
          circleId: widget.circleId,
          name: nameController.text,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Circle updated!')),
          );
        }

        _loadCircleDetails();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCircle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Circle'),
        content: const Text(
          'Are you sure you want to delete this circle? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _circleService.deleteCircle(widget.circleId);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Circle deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_circle?.name ?? 'Circle'),
        actions: [
          if (_isAdmin && _circle?.isDefault != true)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editCircle();
                } else if (value == 'delete') {
                  _deleteCircle();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: _circle != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      circleId: widget.circleId,
                      circleName: _circle!.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Chat'),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCircleDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_circle == null) {
      return const Center(child: Text('Circle not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadCircleDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _circle!.isDefault
                    ? Colors.pink.shade50
                    : Colors.purple.shade50,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _circle!.isDefault
                        ? Colors.pink.shade100
                        : Colors.purple.shade100,
                    backgroundImage: _circle!.avatarUrl != null
                        ? NetworkImage(_circle!.avatarUrl!)
                        : null,
                    child: _circle!.avatarUrl == null
                        ? Icon(
                            _circle!.isDefault ? Icons.favorite : Icons.group,
                            size: 50,
                            color: _circle!.isDefault
                                ? Colors.pink
                                : Colors.purple,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _circle!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_circle!.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _circle!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_circle!.isDefault) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Default Circle',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Members Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members (${_members.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isAdmin)
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invite feature coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Invite'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._members.map((member) => _buildMemberTile(member)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(CircleMember member) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isCurrentUser = member.userId == currentUserId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.purple.shade100,
        backgroundImage:
            member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(
                member.displayName?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (member.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isCurrentUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (member.status != null) ...[
            const SizedBox(height: 4),
            Text(
              member.status!,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
