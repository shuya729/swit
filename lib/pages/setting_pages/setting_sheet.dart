import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/data_state.dart';
import '../../models/friend_state.dart';
import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_states.dart';
import '../../providers/layout_providers.dart';
import '../../providers/my_data_privder.dart';
import '../../widgets/icon_widget.dart';
import '../../widgets/setting_item.dart';
import '../../widgets/setting_state.dart';
import 'bolocking_page.dart';
import 'contact_page.dart';
import 'delete_dialog.dart';
import 'friends_page.dart';
import 'icon_page.dart';
import 'licenses_page.dart';
import 'name_page.dart';
import 'requested_page.dart';
import 'requesting_page.dart';
import 'search_page.dart';
import 'signin_dialog.dart';
import 'signout_dialog.dart';
import 'terms_page.dart';

class SettingSheet extends ConsumerStatefulWidget {
  const SettingSheet({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SettingSheetState();
}

class SettingSheetState extends SettingState<SettingSheet> {
  Future<int> _countingUsers(
    Map<String, String> friendStates,
    String tgtState,
  ) async {
    final List<String> tgtIds = [];
    if (tgtState == FriendState.friend) {
      friendStates.forEach((String key, String value) {
        if (value == FriendState.friend) tgtIds.add(key);
      });
      friendStates.forEach((String key, String value) {
        if (value == FriendState.blocked) tgtIds.add(key);
      });
    } else {
      friendStates.forEach((String key, String value) {
        if (value == tgtState) tgtIds.add(key);
      });
    }
    if (tgtIds.isEmpty) return 0;

    final res = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', whereIn: tgtIds)
        .count()
        .get();
    return res.count ?? 0;
  }

  Map<String, List<Widget>> _getSettingMenus({
    required BuildContext context,
    required Layout layout,
    required UserData? myData,
    required User? user,
    required Map<String, String> friendStates,
    required DataState dataState,
  }) {
    final Map<String, List<Widget>> settingMenus = {};
    if (dataState.isLoading) {
      settingMenus['アカウント'] = [
        Container(
          height: 70,
          width: double.infinity,
          alignment: const Alignment(0, -0.6),
          child: SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: layout.subText,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
        SettingItem(
          menu: 'サインアウト',
          onTap: () => SignoutDialog(showMsgbar).show(context),
        ),
        SettingItem(
          menu: 'アカウント削除',
          onTap: () => DeleteDialog(user!, showMsgbar).show(context),
        ),
      ];
    } else if (dataState.hasError) {
      settingMenus['アカウント'] = [
        SettingItem(
          menu: 'エラー: ${dataState.errorMessage}',
          onTap: null,
        ),
      ];
    } else if (myData == null) {
      settingMenus['アカウント'] = [
        SettingItem(
          menu: 'サインイン',
          onTap: () => SigninDialog(showMsgbar).show(context),
        ),
      ];
    } else {
      settingMenus['アカウント'] = [
        Container(
          width: 70,
          height: 80,
          alignment: Alignment.topCenter,
          child: GestureDetector(
              onTap: () => SettingState.push(context, IconPage(myData)),
              child: IconWidget(myData.image, radius: 35)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'フレンドキー： ${myData.uid}',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 13,
                color: layout.mainText,
              ),
            ),
            IconButton(
              onPressed: () => Share.share(
                myData.uid,
                subject: 'フレンドキー：${myData.uid}',
              ),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.ios_share,
                color: layout.subText,
                size: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SettingItem(
          menu: myData.name.isEmpty ? '名前' : myData.name,
          onTap: () => SettingState.push(context, NamePage(myData)),
        ),
        SettingItem(
          menu: 'サインアウト',
          onTap: () => SignoutDialog(showMsgbar).show(context),
        ),
        SettingItem(
          menu: 'アカウント削除',
          onTap: () => DeleteDialog(user!, showMsgbar).show(context),
        ),
      ];
      settingMenus['フレンド'] = [
        SettingItem(
          menu: 'フレンド追加',
          onTap: () => SettingState.push(context, SearchPage(myData)),
        ),
        SettingItem(
          menu: 'フレンド一覧',
          onTap: () => SettingState.push(context, FriendsPage(myData)),
          counting: _countingUsers(friendStates, FriendState.friend),
        ),
        SettingItem(
          menu: '送信リクエスト',
          onTap: () => SettingState.push(context, RequestingPage(myData)),
          counting: _countingUsers(friendStates, FriendState.requesting),
        ),
        SettingItem(
          menu: '受信リクエスト',
          onTap: () => SettingState.push(context, RequestedPage(myData)),
          counting: _countingUsers(friendStates, FriendState.requested),
        ),
        SettingItem(
          menu: 'ブロックリスト',
          onTap: () => SettingState.push(context, BlockingPage(myData)),
          counting: _countingUsers(friendStates, FriendState.blocking),
        ),
      ];
    }

    settingMenus['このアプリについて'] = [
      SettingItem(
        menu: '利用規約',
        onTap: () => SettingState.push(context, const TermsPage(false)),
      ),
      SettingItem(
        menu: 'プライバシーポリシー',
        onTap: () => SettingState.push(context, const TermsPage(true)),
      ),
      SettingItem(
        menu: 'ライセンス情報',
        onTap: () => SettingState.push(context, const LicensesPage()),
      ),
      SettingItem(
        menu: 'お問い合わせ',
        onTap: () => SettingState.push(context, ContactPage(user, myData)),
      ),
    ];

    return settingMenus;
  }

  @override
  String get title => '設定';
  @override
  bool get isRoot => true;

  @override
  Widget buildChild(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final User? user = ref.watch(authProvider);
    final UserData? myData = ref.watch(myDataProvider);
    final Map<String, String> friendStates = ref.watch(friendStatesProvider);
    final List<Widget> children = [];
    late final Map<String, List<Widget>> settingMenus;

    if (user == null) {
      settingMenus = _getSettingMenus(
        context: context,
        layout: layout,
        myData: null,
        user: null,
        friendStates: friendStates,
        dataState: DataState.normal(),
      );
    } else if (myData == null) {
      settingMenus = _getSettingMenus(
        context: context,
        layout: layout,
        myData: null,
        user: user,
        friendStates: friendStates,
        dataState: DataState.loading(),
      );
    } else {
      settingMenus = _getSettingMenus(
        context: context,
        layout: layout,
        myData: myData,
        user: user,
        friendStates: friendStates,
        dataState: DataState.normal(),
      );
    }

    settingMenus.forEach((key, value) {
      children.addAll([
        const SizedBox(height: 15),
        Text(
          key,
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            color: layout.subText,
          ),
        ),
        const SizedBox(height: 5),
        ...value,
        const SizedBox(height: 15),
      ]);
    });

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 40,
      ),
      children: children,
    );
  }
}
