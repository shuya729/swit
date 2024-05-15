import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/data_state.dart';
import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/layout_providers.dart';
import '../../providers/my_data_privder.dart';
import '../../widgets/icon_widget.dart';
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
  static Widget settingItem({
    required String menu,
    required Layout layout,
    required Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              menu,
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 15,
                color: onTap == null ? layout.subText : layout.mainText,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: layout.subText,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Widget>> _getSettingMenus({
    required BuildContext context,
    required Layout layout,
    required UserData? myData,
    required User? user,
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
        settingItem(
          menu: 'サインアウト',
          layout: layout,
          onTap: () => SignoutDialog(showMsgbar).show(context),
        ),
        settingItem(
          menu: 'アカウント削除',
          layout: layout,
          onTap: () => DeleteDialog(user!, showMsgbar).show(context),
        ),
      ];
    } else if (dataState.hasError) {
      settingMenus['アカウント'] = [
        settingItem(
          menu: 'エラー: ${dataState.errorMessage}',
          layout: layout,
          onTap: null,
        ),
      ];
    } else if (myData == null) {
      settingMenus['アカウント'] = [
        settingItem(
          menu: 'サインイン',
          layout: layout,
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
              'フレンドキー： ',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 13,
                color: layout.mainText,
              ),
            ),
            SelectableText(
              myData.uid,
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
        settingItem(
          menu: myData.name.isEmpty ? '名前' : myData.name,
          layout: layout,
          onTap: () => SettingState.push(context, NamePage(myData)),
        ),
        settingItem(
          menu: 'サインアウト',
          layout: layout,
          onTap: () => SignoutDialog(showMsgbar).show(context),
        ),
        settingItem(
          menu: 'アカウント削除',
          layout: layout,
          onTap: () => DeleteDialog(user!, showMsgbar).show(context),
        ),
      ];
      settingMenus['フレンド'] = [
        settingItem(
          menu: 'フレンド一覧',
          layout: layout,
          onTap: () => SettingState.push(context, FriendsPage(myData)),
        ),
        settingItem(
          menu: 'フレンド追加',
          layout: layout,
          onTap: () => SettingState.push(context, SearchPage(myData)),
        ),
        settingItem(
          menu: '送信リクエスト',
          layout: layout,
          onTap: () => SettingState.push(context, RequestingPage(myData)),
        ),
        settingItem(
          menu: '受信リクエスト',
          layout: layout,
          onTap: () => SettingState.push(context, RequestedPage(myData)),
        ),
        settingItem(
          menu: 'ブロックリスト',
          layout: layout,
          onTap: () => SettingState.push(context, BlockingPage(myData)),
        ),
      ];
    }

    settingMenus['このアプリについて'] = [
      settingItem(
        menu: '利用規約',
        layout: layout,
        onTap: () => SettingState.push(context, const TermsPage(false)),
      ),
      settingItem(
        menu: 'プライバシーポリシー',
        layout: layout,
        onTap: () => SettingState.push(context, const TermsPage(true)),
      ),
      settingItem(
        menu: 'ライセンス情報',
        layout: layout,
        onTap: () => SettingState.push(context, const LicensesPage()),
      ),
      settingItem(
        menu: 'お問い合わせ',
        layout: layout,
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
    final List<Widget> children = [];
    late final Map<String, List<Widget>> settingMenus;

    if (user == null) {
      settingMenus = _getSettingMenus(
        context: context,
        layout: layout,
        myData: null,
        user: null,
        dataState: DataState.normal(),
      );
    } else if (myData == null) {
      settingMenus = _getSettingMenus(
        context: context,
        layout: layout,
        myData: null,
        user: user,
        dataState: DataState.loading(),
      );
    } else {
      settingMenus = _getSettingMenus(
        context: context,
        layout: layout,
        myData: myData,
        user: user,
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
