class CircleModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime dateCreated;

  CircleModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.dateCreated,
  });

  /// Converts this model into a Map suitable for inserting/updating Supabase.
  Map<String, dynamic> toMap() {
    return {
      'circle_id': id,
      'name': name,
      'created_by': createdBy,
      'date_created': dateCreated.toUtc().toIso8601String(),
    };
  }

  /// Constructs a CircleModel from a Map<String, dynamic>,
  /// e.g. a row returned by Supabase (.select()).
  factory CircleModel.fromMap(Map<String, dynamic> map) {
    return CircleModel(
      id: map['circle_id'] as String,
      name: map['name'] as String,
      createdBy: map['created_by'] as String,
      dateCreated: DateTime.parse(map['date_created'] as String),
    );
  }
}
