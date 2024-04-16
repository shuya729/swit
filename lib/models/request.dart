import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String uid;
  final String tgt;
  final String request;

  const Request({
    required this.uid,
    required this.tgt,
    required this.request,
  });

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> toFirestore() async {
    final CollectionReference collection = firestore.collection('requests');
    await collection.add({
      'uid': uid,
      'tgt': tgt,
      'request': request,
      'credt': DateTime.now(),
    });
  }

  static String get friend => 'friend';
  static String get unfriend => 'unfriend';
  static String get block => 'block';
  static String get unblock => 'unblock';
  // static String get remove => 'remove';

  factory Request.friendRequest(String uid, String tgt) {
    return Request(uid: uid, tgt: tgt, request: friend);
  }

  factory Request.unfriendRequest(String uid, String tgt) {
    return Request(uid: uid, tgt: tgt, request: unfriend);
  }

  factory Request.blockRequest(String uid, String tgt) {
    return Request(uid: uid, tgt: tgt, request: block);
  }

  factory Request.unblockRequest(String uid, String tgt) {
    return Request(uid: uid, tgt: tgt, request: unblock);
  }

  // factory Request.removeRequest(String uid, String tgt) {
  //   return Request(uid: uid, tgt: tgt, request: remove);
  // }
}
