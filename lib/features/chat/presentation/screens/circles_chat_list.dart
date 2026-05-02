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
}
