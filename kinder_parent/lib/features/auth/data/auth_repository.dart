import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Jedyne miejsce w aplikacji, które rozmawia z Firebase Auth.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream zmian stanu logowania (null = wylogowany)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      // Data ostatniego logowania (reguły pozwalają rodzicowi zmienić tylko to pole)
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  /// Sprawdza, czy konto ma rolę rodzica.
  Future<bool> isParent(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final roles = List<String>.from(doc.data()?['roles'] ?? []);
    return roles.contains('parent');
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
