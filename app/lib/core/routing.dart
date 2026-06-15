import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/projects/screens/projects_screen.dart';
import '../features/projects/screens/project_detail_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../shared/widgets/app_shell.dart';
import 'providers.dart';

GoRouter createGoRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    debugLogDiagnostics: false,
    errorBuilder: (_, __) => const SizedBox.shrink(),
    redirect: (context, state) {
      if (!authNotifier.isReady) return null;
      final isLoggedIn = authNotifier.isLoggedIn;
      final location = state.matchedLocation;

      final isOnLogin = location == '/login';
      final isProtected = location.startsWith('/dashboard') ||
          location.startsWith('/projects') ||
          location.startsWith('/leaderboard') ||
          location.startsWith('/settings');
      final isUnmatched = !isOnLogin && !isProtected;

      if (!isLoggedIn && (isProtected || isUnmatched)) return '/login';
      if (isLoggedIn && (isOnLogin || isUnmatched)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (_, __) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':projectId',
                builder: (_, state) => ProjectDetailScreen(
                  projectId: state.pathParameters['projectId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
