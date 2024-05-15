import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../models/layout.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_dialog.dart';

class SigninDialog extends SettingDialog {
  const SigninDialog(super.showMsgbar, {super.key});

  Future<void> _signInWithGoogle() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await auth.signInWithCredential(credential);
    } catch (e) {
      showMsgbar('サインインに失敗しました。');
    }
  }

  Future<void> _singInWithApple() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      await auth.signInWithProvider(appleProvider);
    } catch (e) {
      showMsgbar('サインインに失敗しました。');
    }
  }

  @override
  Widget buildContent(BuildContext context, WidgetRef ref, Layout layout) {
    return Container(
      height: 255,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Text(
            'サインイン',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 22,
              color: layout.mainText,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 220,
            child: SignInButton(
              Buttons.google,
              text: 'Googleでサインイン',
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () {
                LoadingDialog(_signInWithGoogle()).show(context).then((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ),
          const SizedBox(height: 3),
          Text('or',
              style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: layout.mainText,
                  fontSize: 15)),
          const SizedBox(height: 3),
          SizedBox(
            width: 220,
            child: SignInButton(
              Buttons.apple,
              text: 'Appleでサインイン',
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () {
                LoadingDialog(_singInWithApple()).show(context).then((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
