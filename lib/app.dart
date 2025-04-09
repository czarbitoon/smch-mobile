import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/device_management_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/api_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    refreshListenable: router,
    debugLogDiagnostics: true,
    routes: router.routes,
    redirect: router.redirectLogic,
    initialLocation: '/',
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isInitialized = false;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  String? redirectLogic(BuildContext context, GoRouterState state) {
    if (!_isInitialized) {
      return '/splash';
    }

    final isAuth = _ref.read(authStateProvider);
    final isSplash = state.location == '/splash';
    final isLoggingIn = state.location == '/login';

    if (isSplash) {
      return null;
    }

    if (isAuth == null) {
      return '/splash';
    }

    if (!isAuth && !isLoggingIn) {
      return '/login';
    }

    if (isAuth && isLoggingIn) {
      return '/';
    }

    return null;
  }

  List<RouteBase> get routes => [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'devices',
              builder: (context, state) => const DeviceManagementScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    ),
  ];

  Future<void> initializeApp() async {
    await Future.wait([
      _ref.read(apiServiceProvider).initialize(),
      _ref.read(authStateProvider.notifier).initialize(),
    ]);
    _isInitialized = true;
    notifyListeners();
  }
}

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).location;
    if (location.startsWith('/devices')) return 1;
    if (location.startsWith('/notifications')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/devices');
        break;
      case 2:
        context.go('/notifications');
        break;
    }
  }
} 