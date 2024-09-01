import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Messaging {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await messaging.requestPermission();
    final String? token = await messaging.getToken();
    final String? uid = auth.currentUser?.uid;
    if (token != null && uid != null) {
      await firestore.collection('tokens').doc(uid).set(
        {'uid': uid, token: FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> deleteToken() async {
    final String? token = await messaging.getToken();
    final String? uid = auth.currentUser?.uid;
    if (token != null && uid != null) {
      await firestore
          .collection('tokens')
          .doc(uid)
          .update({'uid': uid, token: FieldValue.delete()});
    }
  }
}
