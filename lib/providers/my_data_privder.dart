import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_data.dart';
import 'auth_provider.dart';

final myDataProvider = StateNotifierProvider<_MyDataNotifier, UserData?>((ref) {
  final User? user = ref.watch(authProvider);
  return _MyDataNotifier(user);
});

class _MyDataNotifier extends StateNotifier<UserData?> {
  _MyDataNotifier(this._user) : super(null) {
    _init();
  }
  final User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    if (_user == null) return;
    final Stream<DocumentSnapshot> stream =
        _firestore.collection('users').doc(_user.uid).snapshots();
    await for (DocumentSnapshot doc in stream) {
      if (doc.exists) {
        print('bgndt: ${UserData.fromFirestore(doc).bgndt}');
        if (mounted) state = UserData.fromFirestore(doc);
      } else {
        if (mounted) state = null;
      }
    }
  }
}
