import 'package:flutter/material.dart';

<<<<<<< HEAD
import 'presentation/pages/create_account_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/recovery_delay_page.dart';
import 'presentation/pages/recovery_page.dart';
import 'presentation/pages/reset_password_page.dart';
=======
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
import 'presentation/state/account_controller.dart';
import 'presentation/state/account_scope.dart';

class VaultXApp extends StatelessWidget {
<<<<<<< HEAD
  const VaultXApp({required this.accountController, super.key});
=======
  const VaultXApp({
    required this.accountController,
    super.key,
  });
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c

  final AccountController accountController;

  @override
  Widget build(BuildContext context) {
    return AccountScope(
      controller: accountController,
      child: MaterialApp(
        title: 'VaultX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
<<<<<<< HEAD
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const CreateAccountPage(),
          '/recover': (context) => const RecoveryPage(),
          '/recovery-delay': (context) => const RecoveryDelayPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
          '/dashboard': (context) => const DashboardPage(),
        },
=======
        home: const _AppShell(),
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
      ),
    );
  }
}
<<<<<<< HEAD
=======

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
>>>>>>> 7940fbee775e5489d06b54124daab217969bae7c
