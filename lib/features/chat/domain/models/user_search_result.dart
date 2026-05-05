class UserSearchResult {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? status;

  const UserSearchResult({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.status,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['user_id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'status': status,
    };
  }

  UserSearchResult copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? status,
  }) {
    return UserSearchResult(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSearchResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserSearchResult(id: $id, displayName: $displayName, email: $email)';
  }
}