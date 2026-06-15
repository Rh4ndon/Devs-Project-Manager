import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final supabase = ref.read(supabaseProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (user?.id != null)
                          Text(
                            'ID: ${user!.id.substring(0, 8)}...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
