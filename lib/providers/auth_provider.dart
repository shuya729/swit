import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((_) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _init();
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _init() async {
    await for (User? user in _auth.authStateChanges()) {
      if (mounted) state = user;
    }
  }
}
