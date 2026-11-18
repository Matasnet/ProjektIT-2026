import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../home/domain/models.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../domain/payment_settings.dart';
import '../cubit/payments_cubit.dart';

/// "1250" → "1 250 zł"
String formatMoney(int value) {
  final digits = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return '$buf zł';
}

enum PaymentStatus { paid, due, overdue }

PaymentStatus paymentStatus(
  Child child,
  DateTime month,
  PaymentSettings settings, {
  DateTime? now,
}) {
  if (child.isPaid(Dates.monthKey(month))) return PaymentStatus.paid;
  return (now ?? DateTime.now()).isAfter(settings.dueDate(month))
      ? PaymentStatus.overdue
      : PaymentStatus.due;
}

/// Zakładka Płatności – kwota, status wpłat dzieci (zaznacza admin), dane do przelewu.
class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentsCubit>().state;
    final home = context.watch<HomeCubit>().state;
    final month = DateTime(DateTime.now().year, DateTime.now().month);

    final settings = payments.settings;
    final children = home is HomeLoaded ? home.children : const <Child>[];
    final loading =
        payments.status == PaymentsStatus.loading || home is HomeLoading;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TabHeader(
            title: 'Płatności',
            subtitle: 'Miesięczna opłata za przedszkole',
            bottom: settings == null || children.isEmpty
                ? null
                : _Summary(
                    month: month,
                    settings: settings,
                    children: children,
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          sliver: SliverList.list(
            children: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (payments.status == PaymentsStatus.error)
                const EmptyCard(
                  'Nie udało się pobrać danych o opłatach',
                  icon: Icons.error_outline,
                )
              else if (settings == null)
                const EmptyCard(
                  'Przedszkole nie ustawiło jeszcze opłaty.',
                  icon: Icons.hourglass_empty,
                )
              else if (children.isEmpty)
                const EmptyCard(
                  'Brak przypisanych dzieci – skontaktuj się z przedszkolem.',
                  icon: Icons.child_care,
                )
              else ...[
                SectionTitle(Dates.monthLabel(month)),
                for (final child in children)
                  _ChildPaymentCard(
                    child: child,
                    month: month,
                    settings: settings,
                  ),
                const SizedBox(height: 12),
                const SectionTitle('Dane do przelewu'),
                _TransferCard(settings: settings),
                const SizedBox(height: 12),
                const SectionTitle('Historia'),
                _History(month: month, settings: settings, children: children),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.month,
    required this.settings,
    required this.children,
  });

  final DateTime month;
  final PaymentSettings settings;
  final List<Child> children;

  @override
  Widget build(BuildContext context) {
    final unpaid = children
        .where((c) => !c.isPaid(Dates.monthKey(month)))
        .length;
    final allPaid = unpaid == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: allPaid
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              allPaid ? Icons.check_circle_outline : Icons.payments_outlined,
              color: allPaid ? const Color(0xFF166534) : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allPaid ? 'Wszystko opłacone' : 'Do zapłaty',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                Text(
                  allPaid
                      ? Dates.monthLabel(month)
                      : formatMoney(unpaid * settings.monthlyFee),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                if (!allPaid)
                  Text(
                    'termin: ${Dates.dayMonth(settings.dueDate(month))}',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      PaymentStatus.paid => (
        'Opłacone',
        Icons.check,
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
      ),
      PaymentStatus.due => (
        'Do zapłaty',
        Icons.schedule,
        const Color(0xFFFFEDD5),
        const Color(0xFF9A3412),
      ),
      PaymentStatus.overdue => (
        'Po terminie',
        Icons.error_outline,
        const Color(0xFFFEE2E2),
        const Color(0xFFB91C1C),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildPaymentCard extends StatelessWidget {
  const _ChildPaymentCard({
    required this.child,
    required this.month,
    required this.settings,
  });

  final Child child;
  final DateTime month;
  final PaymentSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = paymentStatus(child, month, settings);
    final title =
        '${child.fullName} – ${month.month.toString().padLeft(2, '0')}/${month.year}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  child.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.violetText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      formatMoney(settings.monthlyFee),
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(status),
            ],
          ),
          if (status != PaymentStatus.paid) ...[
            const SizedBox(height: 12),
            _CopyRow(label: 'Tytuł przelewu', value: title),
          ],
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.settings});

  final PaymentSettings settings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _CopyRow(label: 'Odbiorca', value: settings.recipient),
          const SizedBox(height: 8),
          _CopyRow(
            label: 'Numer konta',
            value: settings.accountNumber,
            mono: true,
          ),
          const SizedBox(height: 8),
          _CopyRow(
            label: 'Termin',
            value: 'do ${settings.dueDay}. dnia każdego miesiąca',
            copyable: false,
          ),
        ],
      ),
    );
  }
}

/// Wiersz "etykieta / wartość" z przyciskiem kopiowania.
class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.copyable = true,
  });

  final String label;
  final String value;
  final bool mono;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: mono ? 'monospace' : null,
                    letterSpacing: mono ? 0.5 : null,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: 'Kopiuj: $label',
              icon: const Icon(Icons.copy_rounded, size: 20),
              color: AppColors.violetText,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Skopiowano: $label')));
              },
            ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({
    required this.month,
    required this.settings,
    required this.children,
  });

  final DateTime month;
  final PaymentSettings settings;
  final List<Child> children;

  @override
  Widget build(BuildContext context) {
    final months = [
      for (var i = 1; i <= 3; i++) DateTime(month.year, month.month - i),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (final m in months)
            for (final c in children)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Dates.monthLabel(m),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            c.fullName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(paymentStatus(c, m, settings)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
