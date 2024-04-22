import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/layout.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';

class DeleteDialog extends ConsumerWidget {
  const DeleteDialog(this.user, {super.key});
  final User user;

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  Future<void> _reauthWithGoogle() async {
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn().signInSilently();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _reauthWithApple() async {
    final appleProvider = AppleAuthProvider();
    await user.reauthenticateWithProvider(appleProvider);
  }

  Future<void> _delete() async {
    if (user.providerData[0].providerId == 'google.com') {
      await _reauthWithGoogle();
    } else if (user.providerData[0].providerId == 'apple.com') {
      await _reauthWithApple();
    } else {}
    await user.delete();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Dialog(
      backgroundColor: layout.mainBack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
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
                foregroundColor: layout.subText,
                backgroundColor: layout.subBack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '削除する',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
