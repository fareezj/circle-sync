class CirclePageState {
  bool isLoading;
  CirclePageState(this.isLoading);

  CirclePageState copyWith({bool? isLoading}) {
    return CirclePageState(
      isLoading ?? this.isLoading,
    );
  }
}

class CircleMembersModel {
  final String userId;
  final String name;
  final String role;

  CircleMembersModel({
    required this.userId,
    required this.name,
    required this.role,
  });

  /// Create a CircleMembersModel from a JSON map
  factory CircleMembersModel.fromJson(Map<String, dynamic> json) {
    return CircleMembersModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  /// Convert a CircleMembersModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'role': role,
    };
  }
}
