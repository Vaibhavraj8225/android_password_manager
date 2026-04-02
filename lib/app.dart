import 'package:flutter/material.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/state/account_controller.dart';
import 'presentation/state/account_scope.dart';

class VaultXApp extends StatelessWidget {
  const VaultXApp({
    required this.accountController,
    super.key,
  });

  final AccountController accountController;

  @override
  Widget build(BuildContext context) {
    return AccountScope(
      controller: accountController,
      child: MaterialApp(
        title: 'VaultX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccountScope.of(context).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AccountScope.of(context);
    if (!controller.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return controller.isAuthenticated ? const HomePage() : const LoginPage();
  }
}
