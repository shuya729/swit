import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/request.dart';
import 'auth_provider.dart';

final requestsProvider =
    StateNotifierProvider<RequestsNotifier, List<Request>>((ref) {
  final User? auth = ref.watch(authProvider);
  return RequestsNotifier(auth);
});

class RequestsNotifier extends StateNotifier<List<Request>> {
  RequestsNotifier(this._user) : super([]) {
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
      final List<Request> requests = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        requests.add(Request.fromFirestore(doc));
      }
      if (mounted) state = requests;
    }
  }
}
