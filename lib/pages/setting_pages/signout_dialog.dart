import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/messaging.dart';
import '../../models/presence.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_dialog.dart';

class SignoutDialog extends SettingDialog {
  const SignoutDialog(super.showMsgbar, {super.key});

  Future<void> _signOut() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final Presence presence = Presence.instance;
      await presence.paused();
      await Messaging().deleteToken();
      await auth.signOut();
    } catch (e) {
      showMsgbar('サインアウトに失敗しました。');
    }
  }

  @override
  Widget buildContent(BuildContext context, WidgetRef ref, Layout layout) {
    return Container(
      height: 250,
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Text(
            'サインアウト',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 22,
              color: layout.mainText,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'サインアウトしますか？\n一部の機能が使用できなくなります。',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: layout.mainText,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              LoadingDialog(_signOut()).show(context).then((_) {
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: layout.mainText,
              backgroundColor: layout.subBack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('サインアウト'),
          ),
        ],
      ),
    );
  }
}
