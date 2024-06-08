import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/layout.dart';
import '../providers/layout_providers.dart';
import 'setting_widget.dart';

abstract class SettingState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  static Future<void> push(BuildContext context, Widget next) async {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void showMsgbar(String message) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: layout.subBack,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 14,
            color: layout.subText,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @protected
  String get title;
  bool get isRoot => false;
  bool get fromDialog => false;

  @protected
  Widget buildChild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: SettingWidget.pageTemp(
        context: context,
        layout: layout,
        title: title,
        child: buildChild(context),
        isRoot: isRoot,
        fromDialog: fromDialog,
      ),
    );
  }
}
