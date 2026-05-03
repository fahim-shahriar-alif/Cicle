class Photo {
  final String id;
  final String circleId;
  final String userId;
  final String url;
  final String? caption;
  final String? location;
  final DateTime takenAt;
  final DateTime createdAt;
  
  // User details
  final String? uploaderName;
  final String? uploaderAvatar;

  Photo({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.url,
    this.caption,
    this.location,
    required this.takenAt,
    required this.createdAt,
    this.uploaderName,
    this.uploaderAvatar,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      circleId: json['circle_id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String,
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      takenAt: DateTime.parse(json['taken_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      uploaderName: json['uploader_name'] as String?,
      uploaderAvatar: json['uploader_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'user_id': userId,
      'url': url,
      'caption': caption,
      'location': location,
      'taken_at': takenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
