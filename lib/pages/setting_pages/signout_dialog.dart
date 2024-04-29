import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/presence.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';

class SignoutDialog extends ConsumerWidget {
  const SignoutDialog({super.key});

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  Future<void> _signOut() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final Presence presence = Presence();
    await presence.paused();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Dialog(
      backgroundColor: layout.mainBack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
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
      ),
    );
  }
}
