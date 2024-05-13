import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../providers/layout_providers.dart';

abstract class SettingDialog extends ConsumerWidget {
  const SettingDialog({super.key});

  Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => this,
    );
  }

  @protected
  Widget buildContent(BuildContext context, WidgetRef ref, Layout layout);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Dialog(
      backgroundColor: layout.mainBack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: buildContent(context, ref, layout),
    );
  }
}
