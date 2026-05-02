import 'package:flutter/material.dart';
import '../../data/demand_service.dart';
import '../../domain/models/demand.dart';
import 'package:intl/intl.dart';

class DemandsScreen extends StatefulWidget {
  const DemandsScreen({super.key});

  @override
  State<DemandsScreen> createState() => _DemandsScreenState();
}

class _DemandsScreenState extends State<DemandsScreen>
    with SingleTickerProviderStateMixin {
  final _demandService = DemandService();
  late TabController _tabController;
  
  List<Demand> _allDemands = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDemands();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDemands() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final demands = await _demandService.getUserDemands();

      setState(() {
        _allDemands = demands;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Demand> get _pendingDemands =>
      _allDemands.where((d) => d.status == 'pending').toList();
  
  List<Demand> get _foodDemands =>
      _allDemands.where((d) => d.category == 'food').toList();
  
  List<Demand> get _pickupDemands =>
      _allDemands.where((d) => d.category == 'pickup').toList();
  
  List<Demand> get _completedDemands =>
      _allDemands.where((d) => d.status == 'completed').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Demands'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '🍕 Food'),
            Tab(text: '📦 Pickup'),
            Tab(text: '✓ Done'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF51CF66), Color(0xFF69DB7C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDemandDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Demand'),
        backgroundColor: const Color(0xFF51CF66),
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
                'Unable to load demands',
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
                onPressed: _loadDemands,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDemandsList(_pendingDemands),
        _buildDemandsList(_foodDemands),
        _buildDemandsList(_pickupDemands),
        _buildDemandsList(_completedDemands),
      ],
    );
  }

  Widget _buildDemandsList(List<Demand> demands) {
    if (demands.isEmpty) {
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
                  color: const Color(0xFF51CF66).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  size: 64,
                  color: Color(0xFF51CF66),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No demands yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first demand',
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
      onRefresh: _loadDemands,
      color: const Color(0xFF51CF66),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demands.length,
        itemBuilder: (context, index) {
          return _buildDemandCard(demands[index]);
        },
      ),
    );
  }

  Widget _buildDemandCard(Demand demand) {
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
          onTap: () => _showDemandDetails(demand),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(demand.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(demand.category),
                        color: _getCategoryColor(demand.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            demand.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF2D3436),
                              decoration: demand.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (demand.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              demand.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF636E72),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Checkbox
                    Checkbox(
                      value: demand.isCompleted,
                      onChanged: (value) async {
                        await _demandService.toggleDemandCompletion(
                          demand.id,
                          value ?? false,
                        );
                        _loadDemands();
                      },
                      activeColor: const Color(0xFF51CF66),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Footer
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(demand.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        demand.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(demand.priority),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Due Date
                    if (demand.dueDate != null)
                      Text(
                        'Due ${DateFormat('MMM d').format(demand.dueDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Creator
                    if (demand.creatorName != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF51CF66).withOpacity(0.1),
                            backgroundImage: demand.creatorAvatar != null
                                ? NetworkImage(demand.creatorAvatar!)
                                : null,
                            child: demand.creatorAvatar == null
                                ? Text(
                                    demand.creatorName!.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF51CF66),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            demand.creatorName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF636E72),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'food':
        return const Color(0xFFFF6B9D);
      case 'pickup':
        return const Color(0xFF6C5CE7);
      case 'todo':
        return const Color(0xFF00D4FF);
      default:
        return const Color(0xFF636E72);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'pickup':
        return Icons.shopping_bag_rounded;
      case 'todo':
        return Icons.check_circle_rounded;
      default:
        return Icons.list_alt_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFFF6B6B);
      case 'high':
        return const Color(0xFFFF8E9E);
      case 'medium':
        return const Color(0xFFFFB84D);
      default:
        return const Color(0xFF51CF66);
    }
  }

  void _showDemandDetails(Demand demand) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              demand.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (demand.description != null) ...[
              const SizedBox(height: 12),
              Text(
                demand.description!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _demandService.toggleDemandCompletion(
                        demand.id,
                        !demand.isCompleted,
                      );
                      Navigator.pop(context);
                      _loadDemands();
                    },
                    icon: Icon(demand.isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_rounded),
                    label: Text(demand.isCompleted ? 'Undo' : 'Complete'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    await _demandService.deleteDemand(demand.id);
                    Navigator.pop(context);
                    _loadDemands();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                  ),
                  child: const Icon(Icons.delete_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDemandDialog() {
    // TODO: Implement create demand dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create demand dialog coming soon!')),
    );
  }
}
