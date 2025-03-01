import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_state.dart';
import '../models/user_data.dart';
import 'friend_states.dart';

final friendsProvider =
    StateNotifierProvider<_FriendsNotifier, List<UserData>>((ref) {
  return _FriendsNotifier(ref);
});

class _FriendsNotifier extends StateNotifier<List<UserData>> {
  _FriendsNotifier(this._ref) : super([]) {
    _init();
  }

  final StateNotifierProviderRef _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    try {
      final List<FriendState> friendStates = _ref.watch(friendStatesProvider);
      final List<String> friendIds = [];

      for (FriendState friendState in friendStates) {
        if (friendState.isFriend) friendIds.add(friendState.uid);
      }

      if (friendIds.isEmpty) {
        if (mounted) state = [];
        return;
      }

      final Stream<QuerySnapshot> stream = _firestore
          .collection('users')
          .where('uid', whereIn: friendIds)
          .snapshots();
      await for (QuerySnapshot snapshot in stream) {
        final List<UserData> friends = [];
        for (DocumentSnapshot doc in snapshot.docs) {
          friends.add(UserData.fromFirestore(doc));
        }
        friends.sort((a, b) {
          final DateTime aDate = a.bgndt ?? DateTime(2999);
          final DateTime bDate = b.bgndt ?? DateTime(2999);
          return aDate.compareTo(bDate);
        });
        if (mounted) state = friends;
      }
    } catch (e) {
      if (mounted) state = [];
    }
  }
}
