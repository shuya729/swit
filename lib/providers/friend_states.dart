import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final friendStatesProvider =
    StateNotifierProvider<_FriendStatesNotifier, Map<String, String>>((ref) {
  final User? auth = ref.watch(authProvider);
  return _FriendStatesNotifier(auth);
});

class _FriendStatesNotifier extends StateNotifier<Map<String, String>> {
  _FriendStatesNotifier(this._user) : super({}) {
    _init();
  }
  final User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    try {
      if (_user == null) return;
      final Stream<DocumentSnapshot> stream =
          _firestore.collection('friends').doc(_user.uid).snapshots();
      await for (DocumentSnapshot doc in stream) {
        if (doc.exists) {
          if (mounted) {
            state = (doc.data() as Map<String, dynamic>).cast<String, String>();
          }
        } else {
          if (mounted) state = {};
        }
      }
    } catch (e) {
      if (mounted) state = {};
    }
  }
}
