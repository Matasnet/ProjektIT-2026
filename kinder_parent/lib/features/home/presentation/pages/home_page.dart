import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../menu/presentation/pages/menu_tab.dart';
import '../../../payments/presentation/cubit/payments_cubit.dart';
import '../../../payments/presentation/pages/payments_tab.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'notifications_tab.dart';
import 'start_tab.dart';

/// Indeksy zakładek dolnego paska
abstract final class HomeTabs {
  static const start = 0;
  static const notifications = 1;
  static const menu = 2;
  static const payments = 3;
}

/// Ekran po zalogowaniu: dolny pasek z zakładkami Start, Powiadomienia,
/// Jadłospis i Płatności. Zakładki trzymają stan (IndexedStack).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StreamSubscription<RemoteNotification> _foregroundSub;
  int _index = HomeTabs.start;

  @override
  void initState() {
    super.initState();
    // Gdy aplikacja jest otwarta, system nie pokazuje powiadomienia – robimy SnackBar
    _foregroundSub = NotificationService.foregroundMessages.listen((n) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'),
          action: SnackBarAction(
            label: 'Pokaż',
            textColor: AppColors.accent,
            onPressed: () => _open(HomeTabs.notifications),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _foregroundSub.cancel();
    super.dispose();
  }

  void _open(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final settings = context.watch<PaymentsCubit>().state.settings;
    final month = Dates.monthKey(DateTime.now());
    final unpaid = home is HomeLoaded && settings != null
        ? home.children.where((c) => !c.isPaid(month)).length
        : 0;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              StartTab(onOpenTab: _open),
              const NotificationsTab(),
              const MenuTab(),
              const PaymentsTab(),
            ],
          ),
          // Fioletowy pasek pod paskiem stanu – przewijana treść nie wjeżdża pod zegar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top,
            child: const ColoredBox(color: AppColors.violet),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _open,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Powiadomienia',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Jadłospis',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unpaid > 0,
              label: Text('$unpaid'),
              child: const Icon(Icons.account_balance_wallet_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unpaid > 0,
              label: Text('$unpaid'),
              child: const Icon(Icons.account_balance_wallet),
            ),
            label: 'Płatności',
            tooltip: unpaid > 0 ? 'Płatności – $unpaid do zapłaty' : null,
          ),
        ],
      ),
    );
  }
}
