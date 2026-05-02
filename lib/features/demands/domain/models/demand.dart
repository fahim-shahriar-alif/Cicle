class Demand {
  final String id;
  final String circleId;
  final String userId;
  final String title;
  final String? description;
  final String category; // 'food', 'pickup', 'todo', 'other'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final DateTime? dueDate;
  final DateTime createdAt;
  final int reactionCount;
  
  // User details
  final String? creatorName;
  final String? creatorAvatar;

  Demand({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.reactionCount = 0,
    this.creatorName,
    this.creatorAvatar,
  });

  factory Demand.fromJson(Map<String, dynamic> json) {
    return Demand(
      id: json['id'] as String,
      circleId: json['circle_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      reactionCount: json['reaction_count'] as int? ?? 0,
      creatorName: json['creator_name'] as String?,
      creatorAvatar: json['creator_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isUrgent => priority == 'urgent';
  bool get isFood => category == 'food';
  bool get isPickup => category == 'pickup';
}
