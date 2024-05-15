import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Presence {
  static final Presence instance = Presence._internal();

  User? _user;
  String _postKey = '';
  Timer? _timer;
  bool connected = false;

  final StreamController<bool> _connectedController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectedStream => _connectedController.stream;

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseDatabase database = FirebaseDatabase.instance;

  Map<String, Object> data(String uid, bool isUpdate) {
    if (isUpdate) {
      return {
        "upddt": ServerValue.timestamp,
      };
    } else {
      return {
        "uid": uid,
        "credt": ServerValue.timestamp,
        "upddt": ServerValue.timestamp,
      };
    }
  }

  static final DatabaseReference presenceRef = database.ref('presence');
  static final DatabaseReference connectedRef = database.ref('.info/connected');
  Presence._internal() {
    auth.authStateChanges().listen((user) async {
      if (user == null) {
        _user = null;
        await paused();
        _postKey = '';
        connected = true;
        _connectedController.add(true);
      } else {
        _user = user;
        await resumed();
        connectedRef.onValue.listen((event) {
          connected = event.snapshot.value as bool? ?? false;
          _connectedController.add(connected);
          if (connected) {
            final DatabaseReference preRef = presenceRef.push();
            preRef.onDisconnect().remove();
            preRef.set(data(user.uid, false));
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
      final DatabaseReference preRef = presenceRef.child(_postKey);
      preRef.update(data(_user!.uid, true));
    });
  }

  Future<void> paused() async {
    if (_user == null) return;
    await database.goOffline();
    _timer?.cancel();
  }
}
