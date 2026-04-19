import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VaultTextField extends StatelessWidget {
  const VaultTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIconColor: AppColors.subtext,
      ),
    );
  }
}

class AppTextField extends VaultTextField {
  const AppTextField({
    required super.controller,
    required super.label,
    super.key,
    super.hint,
    super.obscureText,
    super.enabled,
    super.keyboardType,
    super.textCapitalization,
    super.suffixIcon,
    super.helperText,
  });
}

