import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../menu/presentation/cubit/menu_cubit.dart';
import '../../../payments/presentation/cubit/payments_cubit.dart';
import '../../../payments/presentation/pages/payments_tab.dart';
import '../cubit/home_state.dart';
import '../pages/home_page.dart';

/// Karuzela banerów na zakładce Start: płatność, dzisiejszy obiad, najnowsze
/// powiadomienie. Przewija się sama co 6 s (chyba że animacje są wyłączone).
class StartBanner extends StatefulWidget {
  const StartBanner({super.key, required this.home, required this.onOpenTab});

  final HomeLoaded home;
  final ValueChanged<int> onOpenTab;

  @override
  State<StartBanner> createState() => _StartBannerState();
}

class _StartBannerState extends State<StartBanner> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  int _count =
      0; // liczba slajdów z ostatniego build (timer nie może wołać watch)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) => _next());
    }
  }

  void _next() {
    if (!mounted || !_controller.hasClients) return;
    if (_count < 2) return;
    _controller.animateToPage(
      (_page + 1) % _count,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<_Slide> _slides(BuildContext context) {
    final home = widget.home;
    final settings = context.watch<PaymentsCubit>().state.settings;
    final menu = context.watch<MenuCubit>().state;
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final slides = <_Slide>[];

    // 1. Płatność za bieżący miesiąc
    if (settings != null && home.children.isNotEmpty) {
      final unpaid = home.children
          .where((c) => !c.isPaid(Dates.monthKey(month)))
          .toList();
      final overdue = now.isAfter(settings.dueDate(month));
      slides.add(
        unpaid.isEmpty
            ? _Slide(
                tag: Dates.monthLabel(month),
                title: 'Wszystko opłacone',
                subtitle: 'Dziękujemy! Opłata zaksięgowana.',
                icon: Icons.verified_outlined,
                colors: const [Color(0xFFBBF7D0), Color(0xFFDCFCE7)],
                fg: const Color(0xFF14532D),
                tab: HomeTabs.payments,
              )
            : _Slide(
                tag: overdue
                    ? 'Po terminie'
                    : 'Opłata za ${Dates.monthLabel(month).toLowerCase()}',
                title: formatMoney(unpaid.length * settings.monthlyFee),
                subtitle:
                    '${overdue ? 'Termin minął' : 'Termin'} ${Dates.dayMonth(settings.dueDate(month))} · ${unpaid.length} × ${formatMoney(settings.monthlyFee)}',
                icon: Icons.account_balance_wallet_outlined,
                colors: overdue
                    ? const [Color(0xFFFECACA), Color(0xFFFFE4E6)]
                    : const [Color(0xFFFED7AA), Color(0xFFFFEDD5)],
                fg: overdue ? const Color(0xFF7F1D1D) : const Color(0xFF7C2D12),
                tab: HomeTabs.payments,
              ),
      );
    }

    // 2. Dzisiejszy obiad
    final today = menu.days[Dates.dayKey(now)];
    if (today != null) {
      slides.add(
        _Slide(
          tag: 'Dziś na obiad',
          title: today.main.name,
          subtitle: today.soup.name,
          icon: Icons.restaurant_outlined,
          colors: const [Color(0xFFFDE68A), Color(0xFFFEF3C7)],
          fg: const Color(0xFF713F12),
          tab: HomeTabs.menu,
        ),
      );
    }

    // 3. Najnowsze powiadomienie (albo powitanie, gdy brak)
    final latest = home.notifications.isEmpty ? null : home.notifications.first;
    slides.add(
      latest == null
          ? const _Slide(
              tag: 'Kinder Info',
              title: 'Wszystko z przedszkola w jednym miejscu',
              subtitle: 'Powiadomienia zobaczysz tu od razu',
              icon: Icons.favorite_outline,
              colors: [Color(0xFFDDD6FE), Color(0xFFEDE9FE)],
              fg: AppColors.violetText,
              tab: HomeTabs.notifications,
            )
          : _Slide(
              tag: 'Najnowsze · ${home.groupName(latest.groupId)}',
              title: latest.title,
              subtitle: latest.body,
              icon: Icons.notifications_active_outlined,
              colors: const [Color(0xFFDDD6FE), Color(0xFFEDE9FE)],
              fg: AppColors.violetText,
              tab: HomeTabs.notifications,
            ),
    );
    return slides;
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);
    _count = slides.length;
    final page = _page.clamp(0, slides.length - 1);

    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _BannerCard(
                slide: slides[i],
                onTap: () => widget.onOpenTab(slides[i].tab),
              ),
            ),
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == page ? AppColors.violetText : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Slide {
  const _Slide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.fg,
    required this.tab,
  });

  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color fg;
  final int tab;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.slide, required this.onTap});

  final _Slide slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${slide.tag}. ${slide.title}. ${slide.subtitle}',
      child: ExcludeSemantics(
        child: Material(
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: slide.colors,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  // Dekoracyjne kółka w tle (jak słońce z motywu klocków ABC)
                  Positioned(
                    right: -30,
                    top: -30,
                    child: _Circle(
                      size: 130,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    bottom: -40,
                    child: _Circle(
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  slide.tag,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: slide.fg,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: slide.fg,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slide.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: slide.fg.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: slide.fg.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 32, color: slide.fg),
                        ),
                      ],
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

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
