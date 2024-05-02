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

class RequestingPage extends ConsumerWidget {
  const RequestingPage(this.myData, {super.key});
  final UserData myData;

  Future<List<UserData>> _getRequestingUsers(
    Map<String, String> userStates,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<UserData> requestingUsers = [];
    final List<String> requestingIds = [];

    userStates.forEach((String key, String value) {
      if (value == FriendState.requesting) requestingIds.add(key);
    });
    if (requestingIds.isEmpty) {
      return requestingUsers;
    }

    await firestore
        .collection('users')
        .where('uid', whereIn: requestingIds)
        .get()
        .then(
      (QuerySnapshot snapshot) {
        requestingUsers.addAll(snapshot.docs.map<UserData>(
          (DocumentSnapshot doc) {
            return UserData.fromFirestore(doc);
          },
        ));
      },
    );

    return requestingUsers;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final Map<String, String> friendStates = ref.watch(friendStatesProvider);

    return SettingPageTemp(
      title: '送信リクエスト',
      child: FutureBuilder(
        future: _getRequestingUsers(friendStates),
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
                '送信済みのリクエストはありません。',
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
