import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Presence {
  static final Presence instance = Presence._internal();

  User? _user;
  String _postKey = '';
  Timer? _timer;
  bool connected = false;
  StreamSubscription? _connectedSub;

  final StreamController<bool> _connectedController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectedStream => _connectedController.stream;

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

  Presence._internal() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseDatabase database = FirebaseDatabase.instance;
    final DatabaseReference presenceRef = database.ref('presence');
    final DatabaseReference connectedRef = database.ref('.info/connected');
    auth.authStateChanges().listen((user) async {
      _user = user;
      _connectedSub?.cancel();
      if (user == null) {
        await database.goOffline();
        _postKey = '';
        connected = true;
        _connectedController.add(true);
        _timer?.cancel();
      } else {
        await database.goOnline();
        _connectedSub = connectedRef.onValue.listen((event) {
          connected = event.snapshot.value as bool? ?? false;
          _connectedController.add(connected);
          _timer?.cancel();
          if (connected) {
            final DatabaseReference preRef = presenceRef.push();
            preRef.onDisconnect().remove();
            preRef.set(data(user.uid, false));
            _postKey = preRef.key ?? '';
            _timer = Timer.periodic(const Duration(minutes: 50), (_) {
              if (_user == null || _postKey.isEmpty) return;
              final DatabaseReference preRef = presenceRef.child(_postKey);
              preRef.update(data(_user!.uid, true));
            });
          }
        });
      }
    });
  }
}
