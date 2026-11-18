import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dekoracja "klocki ABC i słońce" – ten sam motyw co w panelu admina
/// (kinder_admin: LoginView.vue, DashboardView.vue). Klocki delikatnie się unoszą,
/// chyba że w systemie wyłączono animacje.
class AbcBlocks extends StatefulWidget {
  const AbcBlocks({super.key, this.scale = 1});

  final double scale;

  @override
  State<AbcBlocks> createState() => _AbcBlocksState();
}

class _AbcBlocksState extends State<AbcBlocks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return ExcludeSemantics(
      child: SizedBox(
        width: 260 * s,
        height: 170 * s,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Każdy klocek w innej fazie – płynnie unoszą się o 6 px po kolei
            double lift(double phase) =>
                3 *
                s *
                (1 - math.cos((_controller.value + phase) * 2 * math.pi));

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 10 * s,
                  child: Container(
                    width: 80 * s,
                    height: 80 * s,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCD34D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFCD34D,
                          ).withValues(alpha: 0.35),
                          spreadRadius: 14 * s,
                        ),
                      ],
                    ),
                  ),
                ),
                _Block(
                  left: 50,
                  bottom: 76 + lift(0.6) / s,
                  angle: 6,
                  scale: s,
                  bg: const Color(0xFFF9A8D4),
                  fg: const Color(0xFF9D174D),
                  icon: Icons.favorite,
                ),
                _Block(
                  left: 10,
                  bottom: lift(0) / s,
                  angle: -8,
                  scale: s,
                  bg: const Color(0xFFC4B5FD),
                  fg: const Color(0xFF5B21B6),
                  letter: 'A',
                ),
                _Block(
                  left: 88,
                  bottom: lift(0.2) / s,
                  angle: 4,
                  scale: s,
                  bg: const Color(0xFF86EFAC),
                  fg: const Color(0xFF166534),
                  letter: 'B',
                ),
                _Block(
                  left: 166,
                  bottom: lift(0.4) / s,
                  angle: -3,
                  scale: s,
                  bg: const Color(0xFFFDBA74),
                  fg: const Color(0xFF9A3412),
                  letter: 'C',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.left,
    required this.bottom,
    required this.angle,
    required this.scale,
    required this.bg,
    required this.fg,
    this.letter,
    this.icon,
  });

  final double left;
  final double bottom;
  final double angle;
  final double scale;
  final Color bg;
  final Color fg;
  final String? letter;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final size = 70 * scale;
    return Positioned(
      left: left * scale,
      bottom: bottom * scale,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18 * scale),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4C1D95).withValues(alpha: 0.15),
                blurRadius: 18 * scale,
                offset: Offset(0, 8 * scale),
              ),
            ],
          ),
          child: letter != null
              ? Text(
                  letter!,
                  style: TextStyle(
                    fontSize: 32 * scale,
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                )
              : Icon(icon, size: 30 * scale, color: fg),
        ),
      ),
    );
  }
}
