import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/friend_state.dart';
import '../../models/user_data.dart';
import '../../widgets/setting_widget.dart';

class FriendsPage extends SettingWidget {
  const FriendsPage(super.myData, {super.key});

  @override
  String get title => 'フレンド一覧';
  @override
  String get noUserMsg => 'フレンドがいません。';
  @override
  String get tgtFriendState => FriendState.friend;

  @override
  Future<List<UserData>> getTgtUsers(
    Map<String, String> userStates,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<UserData> friends = [];
    final List<String> friendIds = [];

    userStates.forEach((String key, String value) {
      if (value == FriendState.friend) friendIds.add(key);
    });
    userStates.forEach((String key, String value) {
      if (value == FriendState.blocked) friendIds.add(key);
    });
    if (friendIds.isEmpty) {
      return friends;
    }

    await firestore
        .collection('users')
        .where('uid', whereIn: friendIds)
        .get()
        .then(
      (QuerySnapshot snapshot) {
        friends.addAll(snapshot.docs.map<UserData>(
          (DocumentSnapshot doc) {
            return UserData.fromFirestore(doc);
          },
        ));
      },
    );

    friends.sort((UserData a, UserData b) {
      final String astate = userStates[a.uid] ?? FriendState.friend;
      final String bstate = userStates[b.uid] ?? FriendState.friend;
      if (astate == bstate) {
        return 0;
      } else if (astate == FriendState.friend) {
        return -1;
      } else {
        return 1;
      }
    });

    return friends;
  }
}
