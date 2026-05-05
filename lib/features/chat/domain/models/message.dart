enum MessageType { group, direct }

class Message {
  final String id;
  final String? circleId; // Nullable for direct messages
  final String? conversationId; // For direct messages
  final String userId;
  final String content;
  final String? replyToId;
  final DateTime createdAt;
  final MessageType messageType;
  
  // User details (from join)
  final String? senderName;
  final String? senderAvatar;
  final String? senderStatus;

  Message({
    required this.id,
    this.circleId,
    this.conversationId,
    required this.userId,
    required this.content,
    this.replyToId,
    required this.createdAt,
    this.messageType = MessageType.group,
    this.senderName,
    this.senderAvatar,
    this.senderStatus,
  }) : assert(
         (circleId != null && conversationId == null && messageType == MessageType.group) ||
         (circleId == null && conversationId != null && messageType == MessageType.direct),
         'Message must have either circleId (for group) or conversationId (for direct), but not both'
       );

  factory Message.fromJson(Map<String, dynamic> json) {
    final circleId = json['circle_id'] as String?;
    final conversationId = json['conversation_id'] as String?;
    
    return Message(
      id: json['id'] as String,
      circleId: circleId,
      conversationId: conversationId,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      messageType: conversationId != null ? MessageType.direct : MessageType.group,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      senderStatus: json['sender_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'conversation_id': conversationId,
      'user_id': userId,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': createdAt.toIso8601String(),
      'message_type': messageType == MessageType.direct ? 'direct' : 'group',
    };
  }

  bool get isReply => replyToId != null;
  bool get isDirect => messageType == MessageType.direct;
  bool get isGroup => messageType == MessageType.group;

  Message copyWith({
    String? id,
    String? circleId,
    String? conversationId,
    String? userId,
    String? content,
    String? replyToId,
    DateTime? createdAt,
    MessageType? messageType,
    String? senderName,
    String? senderAvatar,
    String? senderStatus,
  }) {
    return Message(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderStatus: senderStatus ?? this.senderStatus,
    );
  }
}
