import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return isWide ? _WebShell(child: child) : _MobileShell(child: child);
  }
}

class _WebShell extends StatelessWidget {
  final Widget child;

  const _WebShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex(context),
            onDestinationSelected: (i) => _onNavigate(context, i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: Text('Leaderboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/projects');
      case 2: context.go('/leaderboard');
      case 3: context.go('/settings');
    }
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;

  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => _onNavigate(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/projects');
      case 2: context.go('/leaderboard');
      case 3: context.go('/settings');
    }
  }
}
