import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/monitoring/monitoring_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/alert_details/alert_details_screen.dart';
import '../widgets/bottom_nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        int index = 0;
        final location = state.uri.toString();
        if (location.startsWith('/monitoring')) {
          index = 1;
        } else if (location.startsWith('/alerts')) {
          index = 2;
        }

        return BottomNavShell(
          currentIndex: index,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.go('/monitoring');
                break;
              case 2:
                context.go('/alerts');
                break;
            }
          },
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/monitoring',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MonitoringScreen(),
          ),
        ),
        GoRoute(
          path: '/alerts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AlertsScreen(),
          ),
        ),
      ],
    ),

    GoRoute(
      path: '/alert/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final alertId = state.pathParameters['id']!;
        return AlertDetailsScreen(alertId: alertId);
      },
    ),
  ],
);
