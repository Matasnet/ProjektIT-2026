import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/menu_day.dart';
import '../cubit/menu_cubit.dart';

/// Zakładka Jadłospis – tydzień Pn–Pt i posiłki wybranego dnia.
class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, state) {
        final day = state.selectedDay;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TabHeader(
                title: 'Jadłospis',
                subtitle: 'Co dziś na talerzu w przedszkolu',
                bottom: _WeekPicker(state: state),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList.list(
                children: [
                  SectionTitle(
                    '${Dates.weekdays[state.selected.weekday - 1]}, '
                    '${Dates.dayMonth(state.selected)}',
                  ),
                  if (state.status == MenuStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == MenuStatus.error)
                    const EmptyCard(
                      'Nie udało się pobrać jadłospisu',
                      icon: Icons.error_outline,
                    )
                  else if (day == null)
                    const EmptyCard(
                      'Brak jadłospisu na ten dzień',
                      icon: Icons.no_meals_outlined,
                    )
                  else ...[
                    _MealCard(
                      label: 'Śniadanie',
                      time: '8:30',
                      icon: Icons.wb_sunny_outlined,
                      bg: const Color(0xFFFEF9C3),
                      fg: const Color(0xFF854D0E),
                      meal: day.breakfast,
                    ),
                    _MealCard(
                      label: 'Zupa',
                      time: '11:30',
                      icon: Icons.soup_kitchen_outlined,
                      bg: const Color(0xFFDCFCE7),
                      fg: const Color(0xFF166534),
                      meal: day.soup,
                    ),
                    _MealCard(
                      label: 'Drugie danie',
                      time: '12:00',
                      icon: Icons.restaurant_outlined,
                      bg: const Color(0xFFFFEDD5),
                      fg: const Color(0xFF9A3412),
                      meal: day.main,
                    ),
                    _MealCard(
                      label: 'Podwieczorek',
                      time: '14:30',
                      icon: Icons.bakery_dining_outlined,
                      bg: const Color(0xFFFCE7F3),
                      fg: const Color(0xFF9D174D),
                      meal: day.snack,
                    ),
                    const SizedBox(height: 4),
                    const _AllergenNote(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({required this.state});

  final MenuState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MenuCubit>();
    final today = Dates.dateOnly(DateTime.now());
    final friday = state.weekStart.add(const Duration(days: 4));

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Poprzedni tydzień',
              color: AppColors.violetText,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => cubit.shiftWeek(-1),
            ),
            Expanded(
              child: Text(
                '${Dates.dayMonth(state.weekStart)} – ${Dates.dayMonth(friday)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.violetText,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Następny tydzień',
              color: AppColors.violetText,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => cubit.shiftWeek(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in state.weekdays)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _DayChip(
                    day: d,
                    selected: d == state.selected,
                    isToday: d == today,
                    onTap: () => cubit.selectDay(d),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.violetText;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${Dates.weekdays[day.weekday - 1]} ${Dates.dayMonth(day)}'
          '${isToday ? ', dziś' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? AppColors.violetText
              : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    Dates.weekdaysShort[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
                  ),
                  // Kropka pod dzisiejszym dniem
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? (selected ? AppColors.accent : AppColors.primary)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.label,
    required this.time,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.meal,
  });

  final String label;
  final String time;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (meal.allergens.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in meal.allergens)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.soft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenNote extends StatelessWidget {
  const _AllergenNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Szare etykiety to alergeny. Dieta specjalna? '
            'Ustal szczegóły z przedszkolem.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}
