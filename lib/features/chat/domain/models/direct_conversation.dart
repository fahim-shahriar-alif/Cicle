class DirectConversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserStatus;
  final String? latestMessage;
  final DateTime? latestMessageTime;
  final int unreadCount;

  const DirectConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserStatus,
    this.latestMessage,
    this.latestMessageTime,
    this.unreadCount = 0,
  });

  factory DirectConversation.fromJson(Map<String, dynamic> json) {
    return DirectConversation(
      id: json['conversation_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUserName: json['other_user_name'] as String,
      otherUserAvatar: json['other_user_avatar'] as String?,
      otherUserStatus: json['other_user_status'] as String?,
      latestMessage: json['latest_message'] as String?,
      latestMessageTime: json['latest_message_time'] != null
          ? DateTime.parse(json['latest_message_time'] as String)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': id,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'other_user_status': otherUserStatus,
      'latest_message': latestMessage,
      'latest_message_time': latestMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  DirectConversation copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserStatus,
    String? latestMessage,
    DateTime? latestMessageTime,
    int? unreadCount,
  }) {
    return DirectConversation(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      otherUserStatus: otherUserStatus ?? this.otherUserStatus,
      latestMessage: latestMessage ?? this.latestMessage,
      latestMessageTime: latestMessageTime ?? this.latestMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DirectConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DirectConversation(id: $id, otherUserName: $otherUserName, latestMessage: $latestMessage)';
  }
}