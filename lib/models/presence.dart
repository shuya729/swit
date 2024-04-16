import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class Presence {
  const Presence(this._user);
  final User? _user;

  static final FirebaseDatabase database = FirebaseDatabase.instance;

  static final DatabaseReference connectedRef = database.ref('.info/connected');

  Future<void> start() async {
    if (_user == null) {
      await database.goOffline();
    } else {
      await database.goOnline();
      final DatabaseReference myRef = database.ref('users/${_user.uid}');
      connectedRef.onValue.listen((event) {
        final bool connected = event.snapshot.value as bool? ?? false;
        if (connected) {
          myRef.onDisconnect().set(false);
          myRef.set(true);
        }
      });
    }
  }

  Future<void> resumed() async {
    if (_user != null) await database.goOnline();
  }

  Future<void> paused() async {
    if (_user != null) await database.goOffline();
  }
}
