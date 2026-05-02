class CircleMember {
  final String id;
  final String circleId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  
  // User details (from join)
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? status;

  CircleMember({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.status,
  });

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    return CircleMember(
      id: json['id'] as String,
      circleId: json['circle_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
}
