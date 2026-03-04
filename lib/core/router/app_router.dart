import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/charts/screens/charts_landing_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/gantt/screens/gantt_screen.dart';
import '../../features/pareto/screens/pareto_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/wip/screens/wip_screen.dart';
import '../../shared/app_shell.dart';
import '../../shared/placeholder_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),

      // Bottom navigation shell (5 tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Gantt
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gantt',
                builder: (_, __) => const GanttScreen(),
              ),
            ],
          ),
          // Tab 2: Charts (TabBar: Material | Staff | FG | Trucks)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/charts',
                builder: (_, __) => const ChartsLandingScreen(),
              ),
            ],
          ),
          // Tab 3: Pareto Explorer
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pareto',
                builder: (_, __) => const ParetoScreen(),
              ),
            ],
          ),
          // Tab 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail routes (pushed on top of shell)
      GoRoute(
        path: '/schedules',
        builder: (_, __) => const PlaceholderScreen(
          title: 'Schedule Selector',
          subtitle: 'Use the bottom sheet',
        ),
      ),
      GoRoute(
        path: '/wip',
        builder: (_, __) => const WipCurveScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (_, __) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (_, state) => PlaceholderScreen(
          title: 'Alert #${state.pathParameters['id']}',
          subtitle: 'Disruption detail',
          icon: Icons.notification_important,
        ),
      ),
    ],
  );
}
