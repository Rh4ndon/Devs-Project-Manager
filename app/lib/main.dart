import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/providers.dart';
import 'core/routing.dart';
import 'core/theme.dart';

final _authNotifier = AuthNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  final router = createGoRouter(_authNotifier);

  Supabase.instance.client.auth.onAuthStateChange.listen((event) {
    _authNotifier.setAuthenticated(event.session?.user != null);
    if (event.session?.user != null) {
      router.go('/dashboard');
    }
  });

  runApp(
    ProviderScope(child: DevsProjectManagerApp(router: router)),
  );
}

class DevsProjectManagerApp extends ConsumerWidget {
  final GoRouter router;

  const DevsProjectManagerApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Devs Project Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
