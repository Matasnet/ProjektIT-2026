import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';

/// Konto i wylogowanie – ten sam układ co okno wylogowania w panelu (App.vue).
class LogoutSheet extends StatefulWidget {
  const LogoutSheet({super.key, required this.user});

  final User user;

  static Future<void> show(BuildContext context, User user) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      // Arkusz dostaje AuthCubit z ekranu, z którego go otwarto
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: LogoutSheet(user: user),
      ),
    );
  }

  @override
  State<LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<LogoutSheet> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    final navigator = Navigator.of(context);
    await context.read<AuthCubit>().signOut();
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.user.displayName ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(user: widget.user, size: 72),
            const SizedBox(height: 16),
            Text(
              'Wylogować się?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            Text(
              widget.user.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.violetMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Na tym telefonie przestaniesz dostawać powiadomienia '
              'z przedszkola, dopóki nie zalogujesz się ponownie.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loggingOut
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.border, width: 2),
                      foregroundColor: AppColors.ink,
                    ),
                    child: const Text(
                      'Anuluj',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loggingOut ? null : _logout,
                    icon: _loggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Wyloguj się'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Inicjały użytkownika na fioletowym kafelku (nagłówek i arkusz wylogowania).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 44});

  final User user;
  final double size;

  String get _initials {
    final source = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim().split(RegExp(r'\s+'))
        : (user.email ?? '').split('@').first.split(RegExp(r'[.\-_]'));
    final letters = source.where((p) => p.isNotEmpty).take(2).map((p) => p[0]);
    final text = letters.join().toUpperCase();
    return text.isEmpty ? '?' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.violet,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w900,
          color: AppColors.violetText,
        ),
      ),
    );
  }
}
