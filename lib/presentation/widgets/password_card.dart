import 'package:flutter/material.dart';

class PasswordCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const PasswordCard(this.entry, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(entry['app'] ?? ''),
        subtitle: Text(entry['username'] ?? ''),
        trailing: const Icon(Icons.lock_outline),
      ),
    );
  }
}
