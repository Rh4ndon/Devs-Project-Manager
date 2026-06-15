import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authUserProvider);
  return user != null;
});

final authReadyProvider = Provider<bool>((ref) {
  final state = ref.watch(authStateProvider);
  return state.hasValue;
});
