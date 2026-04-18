import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SecurityBadge extends StatelessWidget {
  const SecurityBadge({
    required this.label,
    super.key,
    this.icon,
    this.color = AppColors.accentGreen,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends SecurityBadge {
  const StatusBadge({
    required super.label,
    super.key,
    super.icon,
    super.color,
  });
}
