import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VaultBackground extends StatelessWidget {
  const VaultBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  const Color(0xFF0B1020),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -100,
          left: -70,
          child: _GlowOrb(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        Positioned(
          bottom: -120,
          right: -60,
          child: _GlowOrb(color: AppColors.accentCyan.withValues(alpha: 0.16)),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

