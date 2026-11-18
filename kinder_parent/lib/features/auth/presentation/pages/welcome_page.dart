import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/abc_blocks.dart';
import 'login_page.dart';

/// Ekran powitalny przed logowaniem – ten sam panel marki co w logowaniu
/// do panelu admina (fioletowy gradient, klocki ABC).
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, this.signedOut = false});

  /// Pokaż potwierdzenie "Wylogowano" po wejściu na ekran
  final bool signedOut;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    if (widget.signedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wylogowano. Do zobaczenia!')),
        );
      });
    }
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandHeader(),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: AbcBlocks(scale: width < 360 ? 0.8 : 1)),
                        const SizedBox(height: 32),
                        Text(
                          'Wszystko z przedszkola w jednym miejscu',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.violetText,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sprawdzaj grupę dziecka i odbieraj powiadomienia '
                          'od przedszkola prosto na telefon.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.violetDeep,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Feature(
                              icon: Icons.sentiment_satisfied_alt_outlined,
                              label: 'Moje dzieci',
                            ),
                            _Feature(
                              icon: Icons.notifications_active_outlined,
                              label: 'Powiadomienia push',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: _openLogin,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Zaloguj się'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Dane logowania otrzymasz od przedszkola.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.violetDeep,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + nazwa aplikacji (ekran powitalny i logowanie).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.violetText.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/logo.png', width: 44, height: 44),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Kinder Info',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.violetText,
          ),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.violetText),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.violetText,
            ),
          ),
        ],
      ),
    );
  }
}
