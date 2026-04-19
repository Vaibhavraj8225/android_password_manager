import 'package:flutter/material.dart';

import '../../domain/usecases/account_usecases.dart';
import '../state/account_controller.dart';
import 'session_lock_screen.dart';

class AppLifecycleHandler extends StatefulWidget {
  const AppLifecycleHandler({
    required this.controller,
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final AccountController controller;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  static const String _lockRouteName = '/session-lock';

  bool _lockRequired = false;
  bool _isInBackground = false;
  bool _isLockRouteVisible = false;
  bool _isPushScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.controller.isAuthenticated) {
      _lockRequired = false;
      _isInBackground = false;
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _isInBackground = true;
        _lockRequired = true;
        break;
      case AppLifecycleState.resumed:
        if (_isInBackground) {
          _isInBackground = false;
          _scheduleLockRoutePush();
        }
        break;
      case AppLifecycleState.detached:
        _isInBackground = true;
        _lockRequired = true;
        break;
    }
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    if (!widget.controller.isAuthenticated) {
      _lockRequired = false;
      _isInBackground = false;
    }
  }

  void _scheduleLockRoutePush() {
    if (!mounted || !_lockRequired || _isLockRouteVisible || _isPushScheduled) {
      return;
    }
    _isPushScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPushScheduled = false;
      _pushLockRouteIfNeeded();
    });
  }

  Future<void> _pushLockRouteIfNeeded() async {
    if (!mounted || !_lockRequired || _isLockRouteVisible) {
      return;
    }
    if (!widget.controller.isAuthenticated) {
      _lockRequired = false;
      return;
    }

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      _scheduleLockRoutePush();
      return;
    }

    _isLockRouteVisible = true;
    final unlocked = await navigator.push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: _lockRouteName),
        builder: (_) => SessionLockScreen(
          onUnlock: _verifyAndUnlock,
        ),
      ),
    );
    _isLockRouteVisible = false;

    if (unlocked == true) {
      _lockRequired = false;
      return;
    }

    if (mounted && widget.controller.isAuthenticated && _lockRequired) {
      _scheduleLockRoutePush();
    }
  }

  Future<bool> _verifyAndUnlock(String password) async {
    final account = widget.controller.activeAccount;
    if (account == null) {
      return false;
    }

    try {
      await widget.controller.unlockActiveAccount(
        username: account.username,
        password: password,
      );
      if (!mounted) {
        return false;
      }
      _lockRequired = false;
      return true;
    } on AccountException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

