import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/layout.dart';
import '../../models/messaging.dart';
import '../../models/presence.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_dialog.dart';

class DeleteDialog extends SettingDialog {
  const DeleteDialog(this.user, super.showMsgbar, {super.key});
  final User user;

  Future<User?> _reauthWithGoogle() async {
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn().signInSilently();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential =
        await user.reauthenticateWithCredential(credential);
    return userCredential.user;
  }

  Future<User?> _reauthWithApple() async {
    final appleProvider = AppleAuthProvider();
    final UserCredential userCredential =
        await user.reauthenticateWithProvider(appleProvider);
    return userCredential.user;
  }

  Future<void> _delete() async {
    final Presence presence = Presence.instance;
    User? reauthUser;
    try {
      if (user.providerData[0].providerId == 'google.com') {
        reauthUser = await _reauthWithGoogle();
      } else if (user.providerData[0].providerId == 'apple.com') {
        reauthUser = await _reauthWithApple();
      } else {}
      if (reauthUser == null) return;
      await Messaging().deleteToken();
      await presence.goOffline();
      await user.delete();
    } catch (e) {
      showMsgbar('アカウントの削除に失敗しました。');
    }
  }

  @override
  Widget buildContent(BuildContext context, WidgetRef ref, Layout layout) {
    return Container(
      height: 310,
      width: 380,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Text(
            'アカウント削除',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 22,
              color: layout.mainText,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'アカウントを削除しますか？\nログとフレンドに関する情報が完全に削除されます。\nこの操作は取り消せません。',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: layout.mainText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '上記の内容を了承の上、以下のボタンより再認証してアカウントを削除して下さい。',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: layout.mainText,
            ),
          ),
          const SizedBox(height: 45),
          ElevatedButton(
            onPressed: () {
              LoadingDialog(_delete()).show(context).then((_) {
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: layout.error,
              backgroundColor: layout.subBack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }
}
