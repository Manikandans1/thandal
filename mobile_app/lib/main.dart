import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apps/admin/theme/app_theme.dart' as admin_theme;
import 'apps/agent/state/app_scope.dart';
import 'apps/agent/state/app_state.dart';
import 'apps/agent/theme/app_theme.dart' as agent_theme;
import 'apps/customer/screens/splash/splash_screen.dart';
import 'apps/customer/theme/app_theme.dart' as customer_theme;
import 'core/api/api_client.dart';
import 'core/auth/login_screen.dart';
import 'core/auth/session.dart';
import 'core/nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ThandalApp());
}

/// The single Thandal app. Splash -> one shared login -> the customer, agent
/// or admin experience, depending on whose credentials were entered.
class ThandalApp extends StatefulWidget {
  const ThandalApp({super.key});

  @override
  State<ThandalApp> createState() => _ThandalAppState();
}

class _ThandalAppState extends State<ThandalApp> {
  // The agent app's state lives above MaterialApp (and its Navigator) so every
  // pushed agent route can call AppScope.of(context) - same as the standalone
  // agent app.
  late final AppState _agentState = AppState.instance;

  bool _bouncingToLogin = false;

  @override
  void initState() {
    super.initState();
    // If the server ever rejects the saved token (expired, revoked by an admin PIN
    // reset, another device logged in, ...), send the person back to the login screen
    // instead of leaving a broken screen on show.
    ApiClient.instance.onUnauthorized = () {
      if (_bouncingToLogin || Session.role.value == null) return;
      _bouncingToLogin = true;
      Session.forceReset();
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      _bouncingToLogin = false;
    };
  }

  // Each role keeps its own original theme; built once.
  late final ThemeData _customerTheme = customer_theme.AppTheme.light;
  late final ThemeData _agentTheme = agent_theme.AppTheme.light();
  late final ThemeData _adminTheme = admin_theme.AppTheme.light;

  ThemeData _themeFor(UserRole? role) {
    switch (role) {
      case UserRole.agent:
        return _agentTheme;
      case UserRole.admin:
        return _adminTheme;
      case UserRole.customer:
      case null:
        // Splash, login and forgot-PIN use the customer theme (the login
        // screen is the customer app's original one).
        return _customerTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      appState: _agentState,
      child: ValueListenableBuilder<UserRole?>(
        valueListenable: Session.role,
        builder: (context, role, _) => MaterialApp(
          title: 'Thandal',
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          theme: _themeFor(role),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
