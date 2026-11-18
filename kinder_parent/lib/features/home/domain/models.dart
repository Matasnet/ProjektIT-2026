import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? groupId;

  /// Opłacone miesiące "RRRR-MM" – zaznacza admin w panelu (Płatności)
  final List<String> paidMonths;

  const Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.groupId,
    this.paidMonths = const [],
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}'
              '${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  bool isPaid(String monthKey) => paidMonths.contains(monthKey);

  factory Child.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Child(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      groupId: data['groupId'],
      paidMonths: List<String>.from(data['paidMonths'] ?? const []),
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, groupId, paidMonths];
}

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String groupId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.groupId,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      groupId: data['groupId'] ?? 'all',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, body, groupId, createdAt];
}
