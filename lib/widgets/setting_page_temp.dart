import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/layout.dart';
import '../providers/layout_providers.dart';

class SettingPageTemp extends ConsumerWidget {
  const SettingPageTemp({
    super.key,
    required this.title,
    required this.child,
    this.isRoot = false,
    this.fromDialog = false,
  });
  final String title;
  final Widget child;
  final bool isRoot;
  final bool fromDialog;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;

    return Container(
      decoration: BoxDecoration(
        color: layout.mainBack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isRoot
                        ? const SizedBox(width: 48)
                        : IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              size: 18,
                              color: layout.mainText,
                            ),
                          ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        color: layout.mainText,
                      ),
                    ),
                    fromDialog
                        ? const SizedBox(width: 48)
                        : IconButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            icon: Icon(
                              Icons.close,
                              size: 22,
                              color: layout.mainText,
                            ),
                          ),
                  ],
                ),
                Divider(
                  height: 1,
                  color: layout.subText,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingDialogTemp extends ConsumerWidget {
  const SettingDialogTemp({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });
  final String title;
  final String? description;
  final Widget child;

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Dialog(
      backgroundColor: layout.mainBack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: layout.mainText,
                ),
              ),
              const SizedBox(height: 20),
              description != null
                  ? Text(
                      description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: layout.mainText,
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
