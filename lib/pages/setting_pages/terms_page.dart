import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/config.dart';
import '../../models/layout.dart';
import '../../models/terms_text.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/setting_widget.dart';

class TermsPage extends ConsumerWidget {
  const TermsPage(this.isPrivacy, {super.key, this.fromDialog = false});

  final bool isPrivacy;
  final bool fromDialog;

  Future<List<TermsText>> _init() async {
    final Config config = await Config.init();
    final List<TermsText> terms = [];
    const byte = 1024 * 100;
    final FirebaseStorage storage = FirebaseStorage.instance;
    final String path = isPrivacy
        ? 'terms/privacy/privacy_${config.remotePrivacy}.json'
        : 'terms/term/term_${config.remoteTerms}.json';
    final Reference ref = storage.ref().child(path);
    final Uint8List? data = await ref.getData(byte);
    if (data != null) {
      final String decodData = utf8.decode(data);
      final Map<String, dynamic> jsonData =
          jsonDecode(decodData) as Map<String, dynamic>;
      final List<dynamic> jsonList = jsonData['contents'] as List<dynamic>;
      for (final dynamic json in jsonList) {
        terms.add(TermsText.fromJson(json as Map<String, dynamic>));
      }
    }
    return terms;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return SettingWidget.pageTemp(
      context: context,
      layout: layout,
      title: isPrivacy ? 'プライバシーポリシー' : '利用規約',
      fromDialog: fromDialog,
      child: FutureBuilder(
        future: _init(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<TermsText> terms = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 40,
              ),
              itemCount: terms.length,
              itemBuilder: (context, index) {
                final TermsText term = terms[index];
                return Padding(
                  padding: EdgeInsets.only(
                    top: term.type == TermsText.content ? 5 : 30,
                    bottom: term.type == TermsText.content ? 5 : 10,
                    right: 10,
                    left: 10 + (10 * term.indent.toDouble()),
                  ),
                  child: Text(
                    term.text,
                    textAlign: (term.type == TermsText.signature)
                        ? TextAlign.right
                        : (term.type == TermsText.title)
                            ? TextAlign.center
                            : TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: term.type == TermsText.title ? 20 : 14,
                      color: layout.mainText,
                    ),
                  ),
                );
              },
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
