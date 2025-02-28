import 'package:cloud_firestore/cloud_firestore.dart';

import 'friend_state.dart';

class Request {
  final String uid;
  final String tgt;
  Request({
    required this.uid,
    required this.tgt,
  });

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _data({
    required String uid,
    required String tgt,
    required String state,
    bool create = false,
  }) {
    if (create) {
      return {
        'uid': uid,
        'tgt': tgt,
        'state': state,
        'upddt': FieldValue.serverTimestamp(),
        'credt': FieldValue.serverTimestamp(),
      };
    } else {
      return {
        'uid': uid,
        'tgt': tgt,
        'state': state,
        'upddt': FieldValue.serverTimestamp(),
      };
    }
  }

  Future<void> request() async {
    final DocumentReference udoc =
        firestore.collection('users').doc(uid).collection('friends').doc(tgt);
    final DocumentReference tdoc =
        firestore.collection('users').doc(tgt).collection('friends').doc(uid);
    await firestore.runTransaction((t) async {
      final DocumentSnapshot tSnap = await t.get(tdoc);
      if (tSnap.exists && FriendState.fromFirestore(tSnap).isRequesting) {
        t.update(udoc, _data(uid: uid, tgt: tgt, state: FriendState.friend));
        t.update(tdoc, _data(uid: tgt, tgt: uid, state: FriendState.friend));
      } else {
        t.set(
          udoc,
          _data(
              uid: uid, tgt: tgt, state: FriendState.requesting, create: true),
        );
        t.set(
          tdoc,
          _data(uid: tgt, tgt: uid, state: FriendState.requested, create: true),
        );
      }
    });
  }

  Future<void> unrequest() async {
    final DocumentReference udoc =
        firestore.collection('users').doc(uid).collection('friends').doc(tgt);
    final DocumentReference tdoc =
        firestore.collection('users').doc(tgt).collection('friends').doc(uid);
    await firestore.runTransaction((t) async {
      final DocumentSnapshot tSnap = await t.get(tdoc);
      t.delete(udoc);
      if (tSnap.exists) t.delete(tdoc);
    });
  }

  Future<void> block() async {
    final DocumentReference udoc =
        firestore.collection('users').doc(uid).collection('friends').doc(tgt);
    final DocumentReference tdoc =
        firestore.collection('users').doc(tgt).collection('friends').doc(uid);
    await firestore.runTransaction((t) async {
      final DocumentSnapshot tSnap = await t.get(tdoc);
      if (tSnap.exists && FriendState.fromFirestore(tSnap).isBlocking) {
        t.update(udoc, _data(uid: uid, tgt: tgt, state: FriendState.blocking));
      } else {
        t.update(udoc, _data(uid: uid, tgt: tgt, state: FriendState.blocking));
        t.update(tdoc, _data(uid: tgt, tgt: uid, state: FriendState.blocked));
      }
    });
  }

  Future<void> unblock() async {
    final DocumentReference udoc =
        firestore.collection('users').doc(uid).collection('friends').doc(tgt);
    final DocumentReference tdoc =
        firestore.collection('users').doc(tgt).collection('friends').doc(uid);
    await firestore.runTransaction((t) async {
      final DocumentSnapshot tSnap = await t.get(tdoc);
      if (tSnap.exists && FriendState.fromFirestore(tSnap).isBlocking) {
        t.update(udoc, _data(uid: uid, tgt: tgt, state: FriendState.blocked));
      } else {
        t.update(udoc, _data(uid: uid, tgt: tgt, state: FriendState.friend));
        t.update(tdoc, _data(uid: tgt, tgt: uid, state: FriendState.friend));
      }
    });
  }
}
