import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/date_key.dart';
import '../models/layout.dart';
import '../models/logs.dart';
import '../models/user_data.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/layout_providers.dart';
import '../providers/my_data_privder.dart';
import '../widgets/icon_widget.dart';
import 'setting_pages/setting_sheet.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  late List<UserData> _friends;
  late final ScrollController _scrollController;
  int? _expandedIndex = 0;
  double _preOffset = 0;

  @override
  void initState() {
    super.initState();
    _friends = ref.read(friendsProvider);
    _scrollController = ScrollController(initialScrollOffset: 50);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _callBack(int panelIndex, bool isExpanded) {
    if (isExpanded) {
      _expandedIndex = panelIndex;
      _preOffset = _scrollController.offset;
    } else {
      _expandedIndex = null;
    }
    setState(() {
      _scrollController.animateTo(
        isExpanded ? panelIndex * 50 + 50 : _preOffset,
        duration: kThemeAnimationDuration,
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        70;
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          controller: _scrollController,
          children: [
            SizedBox(
              height: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ログ',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 20,
                              color: layout.mainText,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (context) => Navigator(
                                  onGenerateRoute: (context) =>
                                      MaterialPageRoute(
                                    builder: (context) => const SettingSheet(),
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.settings_outlined,
                              size: 23,
                              color: layout.subText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: layout.subText,
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            LogsWidget(
              friends: _friends,
              bodyHeight: bodyHeight,
              callBack: _callBack,
              expandIndex: _expandedIndex,
            ),
          ],
        ),
      ),
    );
  }
}

class LogsWidget extends ConsumerWidget {
  const LogsWidget({
    super.key,
    required this.friends,
    required this.bodyHeight,
    required this.callBack,
    required this.expandIndex,
  });
  final List<UserData> friends;
  final double bodyHeight;
  final Function(int, bool) callBack;
  final int? expandIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final User? user = ref.watch(authProvider);
    final UserData? myData = ref.watch(myDataProvider);

    if (user == null) {
      return SizedBox(
        height: bodyHeight,
        child: Center(
          child: Text(
            'サインインが必要です。',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              color: layout.mainText,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else if (myData == null) {
      return SizedBox(
        height: bodyHeight,
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: layout.subText,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
      );
    } else {
      return ExpansionPanelList.radio(
        initialOpenPanelValue: 0,
        elevation: 0,
        materialGapSize: 0,
        dividerColor: Colors.transparent,
        expandIconColor: layout.subText,
        expandedHeaderPadding: const EdgeInsets.all(0),
        expansionCallback: callBack,
        children: List.generate(
          friends.length + 1,
          (index) {
            final UserData user = index == 0 ? myData : friends[index - 1];
            return ExpansionPanelRadio(
              value: index,
              canTapOnHeader: true,
              backgroundColor: Colors.transparent,
              headerBuilder: (context, isExpanded) {
                return SizedBox(
                  height: 50,
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: user.bgndt == null
                              ? Colors.transparent
                              : layout.mainText,
                          width: 1,
                        ),
                      ),
                      child: IconWidget(user.image, radius: 18),
                    ),
                    title: Text(
                      user.name,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: layout.mainText,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              },
              body: LogWidget(
                opened: expandIndex == index,
                user: user,
                bodyHeight: bodyHeight,
              ),
            );
          },
        ),
      );
    }
  }
}

class LogWidget extends ConsumerWidget {
  LogWidget({
    super.key,
    required this.opened,
    required this.user,
    required this.bodyHeight,
  }) {
    now = DateTime.now();
    // now = DateTime(2024, 4, 1); // サンプル用のコード
    logsFuture = _loadLogs(user, now);
  }
  final bool opened;
  final UserData user;
  final double bodyHeight;
  late final DateTime now;
  late final Future<Logs> logsFuture;

  static const List<String> _weekDays = ['日', '月', '火', '水', '木', '金', '土'];
  static const int _basetime = 6 * 60 * 60 * 1000;

  Future<Logs> _loadLogs(UserData user, DateTime now) async {
    final Logs logs = Logs();
    final List<String> monthKeys = List.generate(4, (index) {
      return DateKey.fromDate(now.year, now.month - index, 1).monthKey;
    });
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final QuerySnapshot snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('logs')
        .where('monthKey', whereIn: monthKeys)
        .get();
    for (final DocumentSnapshot doc in snapshot.docs) {
      logs.fromFirestore(doc);
    }
    logs.calcNow(user.bgndt, now);
    return logs;
  }

  DateTime _getFirstDay(DateTime now) {
    final DateTime firstDay = DateTime(now.year, now.month, now.day - 84);
    return firstDay.subtract(Duration(days: firstDay.weekday % 7));
  }

  Widget _dayWidget(Layout layout, DateTime date, DateTime now, Logs logs) {
    if (date.isAfter(now)) {
      return const SizedBox(height: 22, width: 22);
    }

    // // サンプル用のコード
    // final double percent = Random().nextDouble();

    final int time = logs.gettime(DateKey.fromDateTime(date));
    final double percent = (time / _basetime).clamp(0.0, 1.0);
    return Container(
      height: 18,
      width: 18,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: layout.mainText.withOpacity(percent),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _weekWidget(Layout layout) {
    return SizedBox(
      height: 154,
      width: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          return Container(
            height: 22,
            width: 22,
            alignment: Alignment.centerLeft,
            child: Text(
              _weekDays[index],
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: layout.mainText,
                fontSize: 13,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _monthWidget(Layout layout, DateTime first) {
    final List<Widget> monthWidgets =
        List.filled(15, const SizedBox(height: 22, width: 22));
    for (int col = 0; col < 13; col++) {
      final DateTime lastDate = first.add(Duration(days: (col * 7) + 6));
      if (lastDate.day <= 7) {
        monthWidgets[col] = const SizedBox.shrink();
        monthWidgets[col + 1] = Container(
          height: 22,
          width: 66,
          alignment: Alignment.topCenter,
          child: Text(
            '${lastDate.month}月',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              color: layout.mainText,
              fontSize: 13,
            ),
          ),
        );
        monthWidgets[col + 2] = const SizedBox.shrink();
      }
    }
    return SizedBox(
      height: 22,
      width: 330,
      child: Row(children: monthWidgets),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime firstDay = _getFirstDay(now);
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    if (!opened) {
      return SizedBox(
        height: bodyHeight,
      );
    }

    return Container(
      height: bodyHeight,
      width: double.infinity,
      alignment: const Alignment(0, -0.3),
      constraints: const BoxConstraints(maxWidth: 540),
      child: FutureBuilder(
        future: logsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final Logs logs = snapshot.data as Logs;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 176,
                  width: 330,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _monthWidget(layout, firstDay),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _weekWidget(layout),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(13, (rowIndex) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(7, (colIndex) {
                                  final DateTime date = firstDay.add(
                                      Duration(days: rowIndex * 7 + colIndex));
                                  return _dayWidget(layout, date, now, logs);
                                }),
                              );
                            }),
                          ),
                          const SizedBox(height: 154, width: 22),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 130,
                  width: 150,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          '今日',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            color: layout.mainText,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          Logs.formattime(
                              logs.gettime(DateKey.fromDateTime(now))),
                          // Logs.formattime(12000000), // サンプル用のコード
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 17,
                            color: layout.mainText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          '${now.month}月',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            color: layout.mainText,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          Logs.formattime(logs.getMonthtime(now)),
                          // Logs.formattime(12000000), // サンプル用のコード
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 17,
                            color: layout.mainText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text(
              'エラーが発生しました。',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: layout.mainText,
                fontSize: 16,
              ),
            );
          } else {
            return SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: layout.subText,
                strokeCap: StrokeCap.round,
              ),
            );
          }
        },
      ),
    );
  }
}
