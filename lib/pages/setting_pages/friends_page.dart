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
    List<FriendState> userStates,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<UserData> friends = [];
    final List<String> friendIds = [];

    for (FriendState userState in userStates) {
      if (userState.isFriend) friendIds.add(userState.uid);
    }
    for (FriendState userState in userStates) {
      if (userState.isBlocked) friendIds.add(userState.uid);
    }
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
      final String astate = userStates
          .firstWhere((FriendState userState) => userState.uid == a.uid)
          .state;
      final String bstate = userStates
          .firstWhere((FriendState userState) => userState.uid == b.uid)
          .state;
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
