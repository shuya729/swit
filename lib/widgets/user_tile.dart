import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_state.dart';
import '../models/layout.dart';
import '../models/request.dart';
import '../models/user_data.dart';
import '../providers/friend_states.dart';
import '../providers/layout_providers.dart';
import 'icon_widget.dart';
import 'loading_dialog.dart';

class UserTile extends ConsumerWidget {
  const UserTile({
    super.key,
    required this.myData,
    required this.user,
    this.useCache = true,
  });
  final UserData myData;
  final UserData user;
  final bool useCache;

  Future<void> _reportSheet(BuildContext context, Layout layout) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                LoadingDialog(_report()).show(context);
              },
              child: Text('${user.name} を報告'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: layout.subBack),
            ),
          ),
        );
      },
    );
  }

  Future<void> _report() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('reports').doc(myData.uid + user.uid).set({
      'uid': myData.uid,
      'tgt': user.uid,
      'credt': DateTime.now(),
    });
  }

  Widget _userButton(
    List<FriendState> friendStates,
    Layout layout,
    BuildContext context,
  ) {
    final Request request = Request(uid: myData.uid, tgt: user.uid);
    if (friendStates.any((friendState) => friendState.uid == user.uid)) {
      final FriendState friendState =
          friendStates.firstWhere((friendState) => friendState.uid == user.uid);
      if (friendState.isFriend) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(request.block()).show(context),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            foregroundColor: layout.subText,
            side: BorderSide(color: layout.subText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('ブロック'),
        );
      } else if (friendState.isRequesting) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(request.unrequest()).show(context),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            foregroundColor: layout.subText,
            side: BorderSide(color: layout.subText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('リクエスト済み'),
        );
      } else if (friendState.isRequested) {
        return ElevatedButton(
          onPressed: () => LoadingDialog(request.request()).show(context),
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            foregroundColor: layout.mainText,
            backgroundColor: layout.subBack,
            side: BorderSide(color: layout.subBack),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('確認'),
        );
      } else if (friendState.isBlocking) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(request.unblock()).show(context),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            foregroundColor: layout.subText,
            side: BorderSide(color: layout.subText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('ブロック中'),
        );
      } else if (friendState.isBlocked) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(request.block()).show(context),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            foregroundColor: layout.subText,
            side: BorderSide(color: layout.subText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('ブロック'),
        );
      }
    }
    return ElevatedButton(
      onPressed: () => LoadingDialog(request.request()).show(context),
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        foregroundColor: layout.mainText,
        backgroundColor: layout.subBack,
        side: BorderSide(color: layout.subBack),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text('リクエスト'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final List<FriendState> friendStates = ref.watch(friendStatesProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      width: double.infinity,
      height: 50,
      child: GestureDetector(
        onLongPress: () => _reportSheet(context, layout),
        child: Row(
          children: [
            IconWidget(
              user.image,
              radius: 16,
              useCache: useCache,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                user.name,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: layout.mainText,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 15),
            SizedBox(
              width: 130,
              child: _userButton(friendStates, layout, context),
            ),
          ],
        ),
      ),
    );
  }
}
