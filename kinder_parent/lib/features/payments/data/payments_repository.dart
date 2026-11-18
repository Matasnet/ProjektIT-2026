import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/payment_settings.dart';

/// Odczyt ustawień opłaty. Status "opłacone" jest w children.paidMonths
/// (przychodzi razem z dziećmi z HomeRepository).
class PaymentsRepository {
  final FirebaseFirestore _firestore;

  PaymentsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// null = admin jeszcze nie ustawił opłaty
  Stream<PaymentSettings?> watchSettings() {
    return _firestore.collection('settings').doc('payments').snapshots().map((
      doc,
    ) {
      final data = doc.data();
      return data == null ? null : PaymentSettings.fromMap(data);
    });
  }
}
