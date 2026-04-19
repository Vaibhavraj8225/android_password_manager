import 'package:flutter/material.dart';

import 'presentation/pages/create_account_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/recovery_delay_page.dart';
import 'presentation/pages/recovery_page.dart';
import 'presentation/pages/reset_password_page.dart';
import 'presentation/pages/security_center_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/security/app_lifecycle_handler.dart';
import 'presentation/state/account_controller.dart';
import 'presentation/state/account_scope.dart';
import 'presentation/theme/app_theme.dart';

class VeyloxApp extends StatelessWidget {
  const VeyloxApp({required this.accountController, super.key});

  final AccountController accountController;
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AccountScope(
      controller: accountController,
      child: MaterialApp(
        navigatorKey: _rootNavigatorKey,
        title: 'Veylox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashPage(),
          '/home': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const CreateAccountPage(),
          '/recover': (context) => const RecoveryPage(),
          '/recovery-delay': (context) => const RecoveryDelayPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/security-center': (context) => const SecurityCenterPage(),
        },
        builder: (context, child) {
          return AppLifecycleHandler(
            controller: accountController,
            navigatorKey: _rootNavigatorKey,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

