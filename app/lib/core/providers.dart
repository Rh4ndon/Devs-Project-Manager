import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.currentUser;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange.map((event) => event.session?.user);
});

class AuthNotifier extends ChangeNotifier {
  bool _isReady = false;
  bool _isLoggedIn = false;
  bool get isReady => _isReady;
  bool get isLoggedIn => _isLoggedIn;
  set isReady(bool value) {
    _isReady = value;
    notifyListeners();
  }
  void setAuthenticated(bool value) {
    _isLoggedIn = value;
    _isReady = true;
    notifyListeners();
  }
}

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) => AuthNotifier());
