import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/menu_day.dart';

/// Odczyt jadłospisu z Firestore (kolekcja menu/, ID dokumentu = RRRR-MM-DD).
class MenuRepository {
  final FirebaseFirestore _firestore;

  MenuRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Dni z zakresu [from, to] (klucze RRRR-MM-DD, porównywane jako tekst).
  Stream<List<MenuDay>> watchRange(String from, String to) {
    return _firestore
        .collection('menu')
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(MenuDay.fromDoc).toList());
  }
}
