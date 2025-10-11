class PostModel {
  final String? id;
  final String circleId;
  final String userId;
  final String name;
  final String? image;
  final double lat;
  final double lng;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    this.id,
    required this.circleId,
    required this.userId,
    required this.name,
    this.image,
    required this.lat,
    required this.lng,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create PostModel from JSON (for Supabase responses)
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString(),
      circleId: json['circle_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convert PostModel to JSON (for Supabase inserts/updates)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'circle_id': circleId,
      'user_id': userId,
      'name': name,
      if (image != null) 'image': image,
      'lat': lat,
      'lng': lng,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  PostModel copyWith({
    String? id,
    String? circleId,
    String? userId,
    String? name,
    String? image,
    double? lat,
    double? lng,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      image: image ?? this.image,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Factory constructor for creating a new post
  factory PostModel.create({
    required String circleId,
    required String userId,
    required String name,
    String? image,
    required double lat,
    required double lng,
    required String createdBy,
  }) {
    final now = DateTime.now();
    return PostModel(
      circleId: circleId,
      userId: userId,
      name: name,
      image: image,
      lat: lat,
      lng: lng,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if post has an image
  bool get hasImage => image != null && image!.isNotEmpty;

  /// Get formatted creation date
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() {
    return 'PostModel(id: $id, circleId: $circleId, userId: $userId, name: $name, lat: $lat, lng: $lng, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel &&
        other.id == id &&
        other.circleId == circleId &&
        other.userId == userId &&
        other.name == name &&
        other.image == image &&
        other.lat == lat &&
        other.lng == lng &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        circleId.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        image.hashCode ^
        lat.hashCode ^
        lng.hashCode ^
        createdBy.hashCode;
  }
}
