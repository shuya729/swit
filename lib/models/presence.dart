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

  Map<String, Object> data(String uid, int time) {
    return {
      "uid": uid,
      "time": time,
    };
  }

  static final DatabaseReference presenceRef = database.ref('presence');
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
        connectedRef.onValue.listen((event) {
          final bool connected = event.snapshot.value as bool? ?? false;
          if (connected) {
            final DateTime now = DateTime.now();
            final DatabaseReference preRef = presenceRef.push();
            preRef.onDisconnect().remove();
            preRef.set(data(user.uid, now.millisecondsSinceEpoch));
            _postKey = preRef.key ?? '';
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
      final DatabaseReference preRef = presenceRef.child(_postKey);
      preRef.update(data(_user!.uid, now.millisecondsSinceEpoch));
    });
  }

  Future<void> paused() async {
    await database.goOffline();
    _timer?.cancel();
  }
}
