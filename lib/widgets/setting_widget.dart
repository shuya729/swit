import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/friend_states.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/user_tile.dart';
import '../models/friend_state.dart';

abstract class SettingWidget extends ConsumerWidget {
  const SettingWidget(this.myData, {super.key});
  final UserData myData;

  static Widget pageTemp({
    required BuildContext context,
    required Layout layout,
    required String title,
    required Widget child,
    bool isRoot = false,
    bool fromDialog = false,
  }) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: layout.mainBack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isRoot
                          ? const SizedBox(width: 48)
                          : IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: 18,
                                color: layout.subText,
                              ),
                            ),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                          color: layout.mainText,
                        ),
                      ),
                      fromDialog
                          ? const SizedBox(width: 48)
                          : IconButton(
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                              icon: Icon(
                                Icons.close,
                                size: 22,
                                color: layout.subText,
                              ),
                            ),
                    ],
                  ),
                  Divider(
                    height: 1,
                    color: layout.subText,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @protected
  String get title;
  @protected
  String get noUserMsg;
  @protected
  String get tgtFriendState;

  Future<List<UserData>> getTgtUsers(List<FriendState> userStates) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<UserData> tgtUsers = [];
    final List<String> tgtIds = [];

    for (FriendState userState in userStates) {
      if (userState.state == tgtFriendState) tgtIds.add(userState.uid);
    }
    if (tgtIds.isEmpty) {
      return tgtUsers;
    }

    await firestore
        .collection('users')
        .where('uid', whereIn: tgtIds)
        .get()
        .then(
      (QuerySnapshot snapshot) {
        tgtUsers.addAll(snapshot.docs.map<UserData>(
          (DocumentSnapshot doc) {
            return UserData.fromFirestore(doc);
          },
        ));
      },
    );

    return tgtUsers;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final List<FriendState> friendStates = ref.watch(friendStatesProvider);

    return pageTemp(
      context: context,
      layout: layout,
      title: title,
      child: FutureBuilder(
        future: getTgtUsers(friendStates),
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
                noUserMsg,
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
