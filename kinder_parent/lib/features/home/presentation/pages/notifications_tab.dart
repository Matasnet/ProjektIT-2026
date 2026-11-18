import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// Zakładka Powiadomienia – wszystkie komunikaty dla rodzica (najnowsze pierwsze).
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: TabHeader(
                title: 'Powiadomienia',
                subtitle:
                    'Komunikaty od przedszkola dla Ciebie i grup Twoich dzieci',
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
                    if (state.notifications.isEmpty)
                      const EmptyCard(
                        'Brak powiadomień. Gdy przedszkole coś wyśle, zobaczysz to tutaj.',
                        icon: Icons.notifications_none,
                      ),
                    for (final n in state.notifications)
                      NotificationCard(
                        notification: n,
                        groupName: state.groupName(n.groupId),
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

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String groupName;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = notification.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(notification.body, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(
                  '$groupName · $date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
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
