import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Presence {
  static final Presence _instance = Presence._internal();

  factory Presence() => _instance;

  User? _user;
  String _postKey = '';
  Timer? _timer;

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseDatabase database = FirebaseDatabase.instance;

  static final DatabaseReference connectedRef = database.ref('.info/connected');
  Presence._internal() {
    auth.authStateChanges().listen((user) async {
      if (user == null) {
        _user = null;
        await paused();
        _postKey = '';
      } else {
        _user = user;
        await resumed();
        final DatabaseReference myRef = database.ref('users/${user.uid}');
        connectedRef.onValue.listen((event) {
          final bool connected = event.snapshot.value as bool? ?? false;
          if (connected) {
            final DateTime now = DateTime.now();
            final DatabaseReference con = myRef.push();
            con.onDisconnect().remove();
            con.set(now.millisecondsSinceEpoch);
            _postKey = con.key ?? '';
          }
        });
      }
    });
  }

  Future<void> resumed() async {
    if (_user == null) return;
    await database.goOnline();
    _timer = Timer.periodic(const Duration(minutes: 50), (_) {
      if (_user == null || _postKey.isEmpty) return;
      final DateTime now = DateTime.now();
      final DatabaseReference myRef = database.ref('users/${_user!.uid}');
      myRef.update({_postKey: now.millisecondsSinceEpoch});
    });
  }

  Future<void> paused() async {
    await database.goOffline();
    _timer?.cancel();
  }
}
