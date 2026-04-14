import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pass_manager/presentation/widgets/password_card.dart';

void main() {
  testWidgets('PasswordCard shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordCard(const {
            'app': 'VaultX',
            'username': 'rookie@example.com',
            'password': 'Secret123',
          }, onDelete: () {}),
        ),
      ),
    );

    expect(find.text('VaultX'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });
}
