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

class BlockingPage extends ConsumerWidget {
  const BlockingPage(this.myData, {super.key});
  final UserData myData;

  Future<List<UserData>> _getBlockingUsers(
    Map<String, String> userStates,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<UserData> blockingUsers = [];
    final List<String> blockingIds = [];

    userStates.forEach((String key, String value) {
      if (value == FriendState.blocking) blockingIds.add(key);
    });
    if (blockingIds.isEmpty) {
      return blockingUsers;
    }

    await firestore
        .collection('users')
        .where('uid', whereIn: blockingIds)
        .get()
        .then(
      (QuerySnapshot snapshot) {
        blockingUsers.addAll(snapshot.docs.map<UserData>(
          (DocumentSnapshot doc) {
            return UserData.fromFirestore(doc);
          },
        ));
      },
    );

    return blockingUsers;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final Map<String, String> friendStates = ref.watch(friendStatesProvider);

    return SettingPageTemp(
      title: 'ブロックリスト',
      child: FutureBuilder(
        future: _getBlockingUsers(friendStates),
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
                'ブロック中のユーザーはいません。',
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
