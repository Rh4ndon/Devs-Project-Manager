import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isReady = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isReady => _isReady;

  void setAuthenticated(bool value) {
    _isLoggedIn = value;
    _isReady = true;
    notifyListeners();
  }
}
