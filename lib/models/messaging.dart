import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Messaging {
  Future<void> init() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await messaging.requestPermission();
    await messaging.setForegroundNotificationPresentationOptions(badge: true);
    final String? token = await messaging.getToken();
    final String? uid = auth.currentUser?.uid;
    if (token != null && uid != null) {
      await firestore.collection('tokens').doc(uid).set(
        {token: FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> deleteToken() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String? token = await messaging.getToken();
    final String? uid = auth.currentUser?.uid;
    if (token != null && uid != null) {
      await firestore
          .collection('tokens')
          .doc(uid)
          .update({token: FieldValue.delete()});
    }
  }
}
