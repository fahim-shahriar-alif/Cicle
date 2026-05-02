class Message {
  final String id;
  final String circleId;
  final String userId;
  final String content;
  final String? replyToId;
  final DateTime createdAt;
  
  // User details (from join)
  final String? senderName;
  final String? senderAvatar;
  final String? senderStatus;

  Message({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.content,
    this.replyToId,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.senderStatus,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      circleId: json['circle_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      senderStatus: json['sender_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'user_id': userId,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isReply => replyToId != null;
}
