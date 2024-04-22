import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/user_tile.dart';
import '../../widgets/setting_page_temp.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage(this.myData, {super.key});
  final UserData myData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _key = '';

  Future<List<UserData>?> _search(String key) async {
    if (key.length < 6) return null;
    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .orderBy('uid')
        .startAt([key])
        .endAt(['$key\uf8ff'])
        .limit(20)
        .get();
    return snapshot.docs
        .where((doc) => doc.id != widget.myData.uid)
        .map((doc) => UserData.fromFirestore(doc))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return SettingPageTemp(
      title: 'ユーザー検索',
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            'フレンドキーを入力して下さい。',
            style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 16,
                color: layout.mainText),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: TextField(
              cursorHeight: 23,
              cursorColor: layout.subBack,
              style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 17,
                  color: layout.mainText),
              onChanged: (value) => setState(() => _key = value),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(5),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: layout.subText),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: layout.subBack),
                ),
                hintText: 'フレンドキー',
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 17,
                  color: layout.subText,
                ),
                focusedErrorBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                counterStyle: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                    color: layout.subText),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder(
              future: _search(_key),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final List<UserData> users = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 10,
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final UserData user = users[index];
                      return UserTile(
                        myData: widget.myData,
                        user: user,
                        useCache: false,
                      );
                    },
                  );
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      '該当するユーザーが見つかりませんでした。',
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
                      '検索時にエラーが発生しました。',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: layout.mainText,
                        fontSize: 15,
                      ),
                    ),
                  );
                } else if (snapshot.data == null) {
                  return Center(
                    child: Text(
                      'フレンドキーを6文字以上入力してください。',
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
          ),
        ],
      ),
    );
  }
}
