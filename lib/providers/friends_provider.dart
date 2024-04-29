import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_state.dart';
import '../models/user_data.dart';
import 'friend_states.dart';

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, List<UserData>>((ref) {
  return FriendsNotifier(ref);
});

class FriendsNotifier extends StateNotifier<List<UserData>> {
  FriendsNotifier(this._ref) : super([]) {
    _init();
  }

  final StateNotifierProviderRef _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    final Map<String, String> friendStates = _ref.watch(friendStatesProvider);
    final List<String> friendIds = [];

    friendStates.forEach((String key, String value) {
      if (FriendState.isFriend(value)) friendIds.add(key);
    });

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
  }
}
