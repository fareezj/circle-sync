import 'package:cloud_firestore/cloud_firestore.dart';

class Circle {
  final String id;
  final String name;
  final String createdBy;
  final DateTime dateCreated;
  final List<String> members;

  Circle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.dateCreated,
    required this.members,
  });

  // Convert Circle to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'members': members,
    };
  }

  // Create Circle from Firestore document
  factory Circle.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Circle(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      dateCreated: (data['dateCreated'] as Timestamp).toDate(),
      members: List<String>.from(data['members'] ?? []),
    );
  }
}
