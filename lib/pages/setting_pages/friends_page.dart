import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/friend_state.dart';
import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/friend_states.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/user_tile.dart';
import '../../widgets/setting_page_temp.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage(this.myData, {super.key});
  final UserData myData;

  Future<List<UserData>> _getFriends(
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

    return friends;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final Map<String, String> friendStates = ref.watch(friendStatesProvider);

    return SettingPageTemp(
      title: 'フレンド一覧',
      child: FutureBuilder(
        future: _getFriends(friendStates),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final List<UserData> users = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 40,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final UserData user = users[index];
                return UserTile(myData: myData, user: user);
              },
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'フレンドがいません。',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: layout.mainText,
                  fontSize: 15,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'エラーが発生しました。',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: layout.mainText,
                  fontSize: 15,
                ),
              ),
            );
          } else {
            return Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: layout.subText,
                  strokeCap: StrokeCap.round,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
