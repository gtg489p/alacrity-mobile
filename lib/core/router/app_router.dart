import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
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
                builder: (_, __) => const PlaceholderScreen(
                  title: 'Gantt Chart',
                  subtitle: 'Coming in Phase 2',
                  icon: Icons.view_timeline,
                ),
              ),
            ],
          ),
          // Tab 2: Charts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/charts',
                builder: (_, __) => const PlaceholderScreen(
                  title: 'Charts',
                  subtitle: 'Coming in Phase 3',
                  icon: Icons.bar_chart,
                ),
                routes: [
                  GoRoute(
                    path: 'material',
                    builder: (_, __) => const PlaceholderScreen(
                      title: 'Material Inventory',
                      subtitle: 'Coming in Phase 3',
                    ),
                  ),
                  GoRoute(
                    path: 'staff',
                    builder: (_, __) => const PlaceholderScreen(
                      title: 'Staff / Labor',
                      subtitle: 'Coming in Phase 3',
                    ),
                  ),
                  GoRoute(
                    path: 'fg',
                    builder: (_, __) => const PlaceholderScreen(
                      title: 'Finished Goods',
                      subtitle: 'Coming in Phase 3',
                    ),
                  ),
                  GoRoute(
                    path: 'trucks',
                    builder: (_, __) => const PlaceholderScreen(
                      title: 'Trucks / Shipping',
                      subtitle: 'Coming in Phase 3',
                    ),
                  ),
                  GoRoute(
                    path: 'wip',
                    builder: (_, __) => const PlaceholderScreen(
                      title: 'WIP Curve',
                      subtitle: 'Coming in Phase 3',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Pareto Explorer
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pareto',
                builder: (_, __) => const PlaceholderScreen(
                  title: 'Pareto Explorer',
                  subtitle: 'Coming in Phase 3',
                  icon: Icons.scatter_plot,
                ),
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
        path: '/alerts',
        builder: (_, __) => const PlaceholderScreen(
          title: 'Alerts',
          subtitle: 'Coming in Phase 4',
          icon: Icons.notifications,
        ),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (_, state) => PlaceholderScreen(
          title: 'Alert #${state.pathParameters['id']}',
          subtitle: 'Coming in Phase 4',
          icon: Icons.notification_important,
        ),
      ),
    ],
  );
}
