import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final requestingProvider =
    StateNotifierProvider<RequestingNotifier, List<String>>((ref) {
  final User? auth = ref.watch(authProvider);
  return RequestingNotifier(auth);
});

class RequestingNotifier extends StateNotifier<List<String>> {
  RequestingNotifier(this._user) : super([]) {
    _init();
  }
  final User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    if (_user == null) return;
    final Stream<QuerySnapshot> stream = _firestore
        .collection('requests')
        .where("uid", isEqualTo: _user.uid)
        .snapshots();
    await for (QuerySnapshot snapshot in stream) {
      final List<String> requesting = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String tgt = data['tgt'] as String;
        requesting.add(tgt);
      }
      if (mounted) state = requesting;
    }
  }
}
