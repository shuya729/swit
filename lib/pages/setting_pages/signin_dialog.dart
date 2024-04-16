import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../models/layout.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';

class SigninDialog extends ConsumerWidget {
  const SigninDialog({super.key});

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  Future<UserCredential> _signInWithGoogle() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await auth.signInWithCredential(credential);
  }

  Future<UserCredential> _singInWithApple() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');
    return await auth.signInWithProvider(appleProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Dialog(
      backgroundColor: layout.mainBack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        height: 255,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Text(
              'サインイン',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
            Text('or', style: TextStyle(color: layout.mainText, fontSize: 15)),
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
      ),
    );
  }
}
