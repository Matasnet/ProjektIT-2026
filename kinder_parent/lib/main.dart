import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/home/data/home_repository.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/menu/data/menu_repository.dart';
import 'features/menu/presentation/cubit/menu_cubit.dart';
import 'features/payments/data/payments_repository.dart';
import 'features/payments/presentation/cubit/payments_cubit.dart';
import 'firebase_options.dart';

/// Uruchom z emulatorami: flutter run --dart-define=USE_EMULATORS=true
const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulators) {
    // Emulator Androida widzi komputer pod adresem 10.0.2.2
    const host = '10.0.2.2';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  runApp(const KinderApp());
}

class KinderApp extends StatelessWidget {
  const KinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => HomeRepository()),
        RepositoryProvider(create: (_) => MenuRepository()),
        RepositoryProvider(create: (_) => PaymentsRepository()),
      ],
      child: BlocProvider(
        create: (context) =>
            AuthCubit(authRepository: context.read<AuthRepository>()),
        child: MaterialApp(
          title: 'Kinder Info',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Wybiera ekran na podstawie stanu logowania.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      // Loading/Failure obsługuje LoginPage – tu reagujemy tylko na wynik
      buildWhen: (prev, curr) =>
          curr is AuthAuthenticated || curr is AuthUnauthenticated,
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // Cubity zakładek żyją tak długo, jak sesja danego użytkownika
          return MultiBlocProvider(
            key: ValueKey(state.user.uid),
            providers: [
              BlocProvider(
                create: (context) => HomeCubit(
                  homeRepository: context.read<HomeRepository>(),
                  userId: state.user.uid,
                )..start(),
              ),
              BlocProvider(
                create: (context) =>
                    MenuCubit(menuRepository: context.read<MenuRepository>())
                      ..start(),
              ),
              BlocProvider(
                create: (context) => PaymentsCubit(
                  paymentsRepository: context.read<PaymentsRepository>(),
                )..start(),
              ),
            ],
            child: const HomePage(),
          );
        }
        if (state is AuthUnauthenticated) {
          return WelcomePage(signedOut: state.signedOut);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
