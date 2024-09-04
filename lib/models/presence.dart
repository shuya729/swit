import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class Presence {
  static final Presence instance = Presence._internal();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;

  late final StreamSubscription<User?> _authStateSub;
  late final StreamSubscription<DatabaseEvent> _connectedSub;
  late AppLifecycleListener _appLifecycleListener;

  final _lock = Lock();

  User? _user;
  bool _connected = false;
  bool _display = true;

  String _postKey = '';
  Timer? _timer;

  final StreamController<bool> _stateController =
      StreamController<bool>.broadcast();
  bool state = false;
  Stream<bool> get stateStream => _stateController.stream;

  Presence._internal() {
    final DatabaseReference connectedRef = database.ref('.info/connected');
    _stateController.add(false);
    _changeUser(auth.currentUser);
    connectedRef.once().then(_changeConnected);
    _authStateSub = auth.authStateChanges().listen(_changeUser);
    _connectedSub = connectedRef.onValue.listen(_changeConnected);
    _appLifecycleListener = AppLifecycleListener(
      onResume: _onResume,
      onPause: _onPause,
    );
  }

  void dispose() {
    _authStateSub.cancel();
    _connectedSub.cancel();
    _appLifecycleListener.dispose();
    _stateController.close();
  }

  Future<void> goOffline() async {
    await _lock.synchronized(() async {
      if (_postKey.isNotEmpty) {
        final DatabaseReference presenceRef = database.ref('presence');
        final DatabaseReference preRef = presenceRef.child(_postKey);
        await preRef.remove();
      }
      await database.goOffline();
    });
  }

  Future<void> _changeUser(User? user) async {
    _user = user;
    if (user != null) {
      await database.goOnline();
    } else {
      await goOffline();
    }
  }

  Future<void> _changeConnected(DatabaseEvent event) async {
    final bool connected = event.snapshot.value as bool? ?? false;
    _connected = connected;
    final User? user = _user;
    final bool display = _display;
    if (user != null && connected && display) {
      await _registPresence(user);
    } else if (user != null && connected && !display) {
      await goOffline();
    } else if (user != null && !connected && display) {
      await _cancelPresence();
      await database.goOnline();
    } else if (user != null && !connected && !display) {
      await _cancelPresence();
    } else if (user == null && connected) {
      await goOffline();
    } else if (user == null && !connected) {
      await _cancelPresence();
    }
  }

  Future<void> _onResume() async {
    _display = true;
    final User? user = _user;
    final bool connected = _connected;
    if (user != null && connected) {
      await _registPresence(user);
    } else if (user != null && !connected) {
      await database.goOnline();
    }
  }

  Future<void> _onPause() async {
    _display = false;
    final bool connected = _connected;
    if (connected) {
      await goOffline();
    }
  }

  Future<void> _registPresence(User user) async {
    final DatabaseReference presenceRef = database.ref('presence');
    try {
      await _lock.synchronized(() async {
        if (_postKey.isEmpty) {
          final DatabaseReference preRef = presenceRef.push();
          await preRef.onDisconnect().remove();
          await preRef.set({
            "uid": user.uid,
            "credt": ServerValue.timestamp,
            "upddt": ServerValue.timestamp,
          });
          _postKey = preRef.key ?? '';
          _timer = Timer.periodic(const Duration(minutes: 50), (_) {
            if (_user != null && _display && _postKey.isNotEmpty) {
              final DatabaseReference preRef = presenceRef.child(_postKey);
              preRef.update({"upddt": ServerValue.timestamp});
            }
          });
          state = true;
          _stateController.add(true);
        }
      });
    } catch (e) {
      state = false;
      _stateController.add(false);
    }
  }

  Future<void> _cancelPresence() async {
    await _lock.synchronized(() {
      _postKey = '';
      _timer?.cancel();
      state = false;
      _stateController.add(false);
    });
  }
}
