import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String uid;
  final String tgt;
  final String request;

  const Request({
    this.id = '',
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

  factory Request.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Request(
      id: doc.id,
      uid: data['uid'],
      tgt: data['tgt'],
      request: data['request'],
    );
  }

  static String get friend => 'friend';
  static String get unfriend => 'unfriend';
  static String get block => 'block';
  static String get unblock => 'unblock';

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

  Future<void> cancel() async {
    if (id.isNotEmpty) await firestore.collection('requests').doc(id).delete();
  }
}
