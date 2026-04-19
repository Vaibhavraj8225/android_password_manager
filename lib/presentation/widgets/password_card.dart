import 'package:flutter/material.dart';

import 'password_tile.dart';

class PasswordCard extends StatelessWidget {
  const PasswordCard(
    this.entry, {
    required this.onDelete,
    this.onEdit,
    this.isDeleting = false,
    super.key,
  });

  final Map<String, dynamic> entry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return PasswordTile(
      entry: entry,
      onDelete: onDelete,
      onEdit: onEdit,
      isDeleting: isDeleting,
    );
  }
}

