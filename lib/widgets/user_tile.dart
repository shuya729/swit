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
import '../providers/requests_proivider.dart';
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
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                LoadingDialog(_report()).show(context).then((_) {
                  Navigator.of(context).pop();
                });
              },
              child: Container(
                width: double.infinity,
                height: 57,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: layout.mainText.withOpacity(0.8),
                alignment: Alignment.center,
                child: Text(
                  '${user.name} を報告',
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 18,
                    color: layout.error,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
          cancelButton: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              decoration: BoxDecoration(
                color: layout.mainText.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              width: double.infinity,
              height: 57,
              alignment: Alignment.center,
              child: Text(
                'キャンセル',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                  color: layout.subBack,
                  decoration: TextDecoration.none,
                ),
              ),
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
    Map<String, String> friendStates,
    List<Request> requests,
    Layout layout,
    BuildContext context,
  ) {
    final List<Request> tgt =
        requests.where((Request r) => r.tgt == user.uid).toList();
    if (tgt.isNotEmpty) {
      return OutlinedButton(
        onPressed: () => LoadingDialog(_cancel(tgt)).show(context),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          foregroundColor: layout.subText,
          side: BorderSide(color: layout.subText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: layout.subText,
            strokeCap: StrokeCap.round,
          ),
        ),
      );
    } else if (friendStates.containsKey(user.uid)) {
      if (friendStates[user.uid] == FriendState.friend) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(_block()).show(context),
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
      } else if (friendStates[user.uid] == FriendState.requesting) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(_unfriend()).show(context),
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
      } else if (friendStates[user.uid] == FriendState.requested) {
        return ElevatedButton(
          onPressed: () => LoadingDialog(_friend()).show(context),
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
      } else if (friendStates[user.uid] == FriendState.blocking) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(_unblock()).show(context),
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
      } else if (friendStates[user.uid] == FriendState.blocked) {
        return OutlinedButton(
          onPressed: () => LoadingDialog(_block()).show(context),
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
      onPressed: () => LoadingDialog(_friend()).show(context),
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

  Future<void> _friend() async {
    await Request.friendRequest(myData.uid, user.uid).toFirestore();
  }

  Future<void> _unfriend() async {
    await Request.unfriendRequest(myData.uid, user.uid).toFirestore();
  }

  Future<void> _block() async {
    await Request.blockRequest(myData.uid, user.uid).toFirestore();
  }

  Future<void> _unblock() async {
    await Request.unblockRequest(myData.uid, user.uid).toFirestore();
  }

  Future<void> _cancel(List<Request> tgt) async {
    if (tgt.isEmpty) return;
    for (Request r in tgt) {
      await r.cancel();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final Map<String, String> friendStates = ref.watch(friendStatesProvider);
    final List<Request> requests = ref.watch(requestsProvider);
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
              child: _userButton(friendStates, requests, layout, context),
            ),
          ],
        ),
      ),
    );
  }
}
