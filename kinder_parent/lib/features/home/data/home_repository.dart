import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';

/// Odczyt danych rodzica z Firestore (dzieci, grupy, powiadomienia).
class HomeRepository {
  final FirebaseFirestore _firestore;

  HomeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Dzieci przypisane do rodzica (pole parentIds w dokumencie dziecka).
  Stream<List<Child>> watchChildren(String parentId) {
    return _firestore
        .collection('children')
        .where('parentIds', arrayContains: parentId)
        .snapshots()
        .map((snap) => snap.docs.map(Child.fromDoc).toList());
  }

  /// Mapa groupId → nazwa grupy.
  Future<Map<String, String>> getGroupNames() async {
    final snap = await _firestore.collection('groups').get();
    return {
      for (final doc in snap.docs) doc.id: (doc.data()['name'] ?? '') as String,
    };
  }

  /// Powiadomienia dla wszystkich + dla grup dzieci (najnowsze pierwsze).
  Stream<List<AppNotification>> watchNotifications(List<String> groupIds) {
    final targets = {'all', ...groupIds}.toList();
    return _firestore
        .collection('notifications')
        .where('groupId', whereIn: targets)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AppNotification.fromDoc).toList();
          // Sortowanie po stronie klienta – nie wymaga indeksu złożonego
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
