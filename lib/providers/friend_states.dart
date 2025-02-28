import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_state.dart';
import 'auth_provider.dart';

final friendStatesProvider =
    StateNotifierProvider<_FriendStatesNotifier, List<FriendState>>((ref) {
  final User? auth = ref.watch(authProvider);
  return _FriendStatesNotifier(auth);
});

class _FriendStatesNotifier extends StateNotifier<List<FriendState>> {
  _FriendStatesNotifier(this._user) : super([]) {
    _init();
  }
  final User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    try {
      if (_user == null) return;
      final Stream<QuerySnapshot> stream = _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('friends')
          .snapshots();
      await for (QuerySnapshot snapshot in stream) {
        final List<FriendState> states = [];
        for (DocumentSnapshot doc in snapshot.docs) {
          final FriendState friendState = FriendState.fromFirestore(doc);
          if (friendState.isFriendState) {
            states.add(FriendState.fromFirestore(doc));
          }
        }
        if (mounted) state = states;
      }
    } catch (e) {
      if (mounted) state = [];
    }
  }
}
