import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import 'auth_provider.dart';

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<Message>>((ref) {
  final User? user = ref.watch(authProvider);
  return MessagesNotifier(user);
});

class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier(this._user) : super([]) {
    _init();
  }
  final User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    try {
      if (_user == null) return;
      final Stream<QuerySnapshot> stream = _firestore
          .collection('messages')
          .where('tgt', isEqualTo: _user.uid)
          .snapshots();
      await for (QuerySnapshot snap in stream) {
        final List<Message> messages = [];
        for (DocumentSnapshot doc in snap.docs) {
          final Message message = Message.fromFirestore(doc);
          if (message.isCorrectType) messages.add(message);
        }
        if (mounted) state = messages;
        if (state.isNotEmpty) {
          FlutterAppBadgeControl.updateBadgeCount(state.length);
        } else {
          FlutterAppBadgeControl.removeBadge();
        }
      }
    } catch (e) {
      if (mounted) state = [];
    }
  }

  Future<void> readMessages(String type) async {
    if (_user == null) return;
    final List<Message> messages = state;
    final WriteBatch batch = _firestore.batch();
    for (Message message in messages) {
      if (message.type == type) {
        final DocumentReference ref =
            _firestore.collection('messages').doc(message.id);
        batch.delete(ref);
      }
    }
    await batch.commit();
  }
}
