import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/widgets/logout_sheet.dart';
import '../../domain/models.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/start_banner.dart';
import 'home_page.dart';

/// Zakładka Start – powitanie, baner (płatność, obiad, powiadomienie) i dzieci.
class StartTab extends StatelessWidget {
  const StartTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final firstName = user?.displayName?.split(' ').first;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                user: user,
                firstName: firstName,
                state: state is HomeLoaded ? state : null,
                onOpenTab: onOpenTab,
              ),
            ),
            if (state is HomeError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(state.message)),
              )
            else if (state is! HomeLoaded)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverList.list(
                  children: [
                    StartBanner(home: state, onOpenTab: onOpenTab),
                    const SizedBox(height: 24),
                    const SectionTitle('Moje dzieci'),
                    if (state.children.isEmpty)
                      const EmptyCard(
                        'Brak przypisanych dzieci – skontaktuj się z przedszkolem.',
                      ),
                    for (final child in state.children)
                      _ChildCard(
                        child: child,
                        groupName: state.groupName(child.groupId),
                        color: GroupColors.of(state.groupNames, child.groupId),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;
  final String? firstName;
  final HomeLoaded? state;
  final ValueChanged<int> onOpenTab;

  const _Header({
    required this.user,
    required this.firstName,
    required this.state,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hello = DateTime.now().hour < 18 ? 'Dzień dobry' : 'Dobry wieczór';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.violet,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      // tło logo ma kolor nagłówka – biała obwódka je odcina
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 44,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kinder Info',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.violetText,
                    ),
                  ),
                  const Spacer(),
                  // Awatar otwiera arkusz konta z wylogowaniem
                  if (user != null)
                    Tooltip(
                      message: 'Konto i wylogowanie',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => LogoutSheet.show(context, user!),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: UserAvatar(user: user!, size: 48),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                firstName == null || firstName!.isEmpty
                    ? '$hello!'
                    : '$hello, $firstName!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.violetText,
                ),
              ),
              if (state != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(
                      icon: Icons.sentiment_satisfied_alt_outlined,
                      value: state!.children.length,
                      label: 'Dzieci',
                      onTap: null,
                    ),
                    const SizedBox(width: 12),
                    _Stat(
                      icon: Icons.notifications_none,
                      value: state!.notifications.length,
                      label: 'Powiadomienia',
                      onTap: () => onOpenTab(HomeTabs.notifications),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.violetMuted),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;
  final String groupName;
  final GroupColor color;

  const _ChildCard({
    required this.child,
    required this.groupName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        '${child.firstName.isNotEmpty ? child.firstName[0] : ''}'
                '${child.lastName.isNotEmpty ? child.lastName[0] : ''}'
            .toUpperCase();

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.avatar,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color.text,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${child.firstName} ${child.lastName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    groupName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
