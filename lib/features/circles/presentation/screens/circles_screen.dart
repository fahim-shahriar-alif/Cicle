import 'package:flutter/material.dart';
import '../../data/circle_service.dart';
import '../../domain/models/circle.dart';
import 'circle_detail_screen.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
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

  Future<void> _createCircle() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

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
                hintText: 'e.g., Future Travel',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What is this circle for?',
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await _circleService.createCircle(
          name: nameController.text,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Circle created!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createCircle,
            tooltip: 'Create Circle',
          ),
        ],
      ),
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
              onPressed: _loadCircles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_circles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No circles yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first circle to get started',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createCircle,
              icon: const Icon(Icons.add),
              label: const Text('Create Circle'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCircles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _circles.length,
        itemBuilder: (context, index) {
          final circle = _circles[index];
          return _buildCircleCard(circle);
        },
      ),
    );
  }

  Widget _buildCircleCard(Circle circle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: circle.isDefault
              ? Colors.pink.shade100
              : Colors.purple.shade100,
          backgroundImage:
              circle.avatarUrl != null ? NetworkImage(circle.avatarUrl!) : null,
          child: circle.avatarUrl == null
              ? Icon(
                  circle.isDefault ? Icons.favorite : Icons.group,
                  color: circle.isDefault ? Colors.pink : Colors.purple,
                  size: 30,
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                circle.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (circle.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (circle.description != null) ...[
              const SizedBox(height: 4),
              Text(
                circle.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${circle.memberCount} ${circle.memberCount == 1 ? 'member' : 'members'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CircleDetailScreen(circleId: circle.id),
            ),
          );
        },
      ),
    );
  }
}
