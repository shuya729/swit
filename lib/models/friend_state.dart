import 'package:cloud_firestore/cloud_firestore.dart';

class FriendState {
  static const String friend = 'friend';
  static const String requesting = 'requesting';
  static const String requested = 'requested';
  static const String blocked = 'blocked';
  static const String blocking = 'blocking';
  static const String error = 'error';

  static const list = [
    friend,
    requesting,
    requested,
    blocked,
    blocking,
  ];

  final String uid;
  late final String state;

  FriendState({
    required this.uid,
    required this.state,
  }) {
    if (!list.contains(state)) state = error;
  }

  factory FriendState.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FriendState(
      uid: data['tgt'],
      state: data['state'],
    );
  }

  bool get isFriendState => list.contains(state);
  bool get isFriend => state == friend;
  bool get isRequesting => state == requesting;
  bool get isRequested => state == requested;
  bool get isBlocked => state == blocked;
  bool get isBlocking => state == blocking;
}
