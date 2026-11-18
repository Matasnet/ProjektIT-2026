import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _authSub;
  bool _signingOut = false;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    _authSub = _authRepository.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      emit(AuthUnauthenticated(signedOut: _signingOut));
      _signingOut = false;
      return;
    }
    try {
      if (await _authRepository.isParent(user.uid)) {
        emit(AuthAuthenticated(user: user));
      } else {
        await _authRepository.signOut();
        emit(const AuthFailure(message: 'To konto nie jest kontem rodzica'));
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(email: email, password: password);
      // Sukces obsłuży _onAuthChanged (stream authStateChanges)
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code)));
    } catch (_) {
      emit(const AuthFailure(message: 'Wystąpił nieoczekiwany błąd'));
    }
  }

  Future<void> signOut() async {
    _signingOut = true;
    await NotificationService.unsubscribeFromAll();
    await _authRepository.signOut();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Nieprawidłowy email lub hasło';
      case 'invalid-email':
        return 'Nieprawidłowy format emaila';
      case 'user-disabled':
        return 'Konto zostało zablokowane';
      case 'too-many-requests':
        return 'Zbyt wiele prób. Spróbuj później';
      case 'network-request-failed':
        return 'Brak połączenia z internetem';
      default:
        return 'Błąd logowania: $code';
    }
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
