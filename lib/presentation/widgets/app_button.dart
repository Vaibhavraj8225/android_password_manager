import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonStyle { primary, secondary, ghost, danger }

class GlowButton extends StatefulWidget {
  const GlowButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.isLoading = false,
    this.isExpanded = true,
    this.style = AppButtonStyle.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isLoading;
  final bool isExpanded;
  final AppButtonStyle style;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  double _scale = 1;

  (Color, Color) _gradientColors() {
    switch (widget.style) {
      case AppButtonStyle.primary:
        return (AppColors.primary, AppColors.accentCyan);
      case AppButtonStyle.secondary:
        return (AppColors.accentGreen, AppColors.accentCyan);
      case AppButtonStyle.ghost:
        return (AppColors.cardSurface, AppColors.glassCard);
      case AppButtonStyle.danger:
        return (AppColors.danger, const Color(0xFFFF8A80));
    }
  }

  Color _foregroundColor() {
    if (widget.style == AppButtonStyle.ghost) {
      return AppColors.text;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    final (from, to) = _gradientColors();

    final button = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [from, to]),
          boxShadow: widget.style == AppButtonStyle.ghost
              ? const []
              : [
                  BoxShadow(
                    color: from.withValues(alpha: disabled ? 0.08 : 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: _foregroundColor(),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.style == AppButtonStyle.ghost
                    ? AppColors.border
                    : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          onPressed: disabled ? null : widget.onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _foregroundColor(),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Text(widget.label),
            ],
          ),
        ),
      ),
    );

    final wrapped = GestureDetector(
      onTapDown: disabled
          ? null
          : (_) {
              setState(() {
                _scale = 0.98;
              });
            },
      onTapCancel: disabled
          ? null
          : () {
              setState(() {
                _scale = 1;
              });
            },
      onTapUp: disabled
          ? null
          : (_) {
              setState(() {
                _scale = 1;
              });
            },
      child: button,
    );

    if (!widget.isExpanded) {
      return wrapped;
    }
    return SizedBox(width: double.infinity, child: wrapped);
  }
}

class AppButton extends GlowButton {
  const AppButton({
    required super.label,
    required super.onPressed,
    super.key,
    super.leading,
    super.isLoading,
    super.isExpanded,
    super.style,
  });
}
