import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Start aplikacji – jeszcze nie wiadomo, czy ktoś jest zalogowany
class AuthInitial extends AuthState {}

/// Trwa logowanie (spinner na przycisku)
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user.uid];
}

class AuthUnauthenticated extends AuthState {
  /// true = użytkownik sam się wylogował (ekran powitalny pokazuje potwierdzenie)
  final bool signedOut;

  const AuthUnauthenticated({this.signedOut = false});

  @override
  List<Object?> get props => [signedOut];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
