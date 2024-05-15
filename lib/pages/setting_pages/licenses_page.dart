import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/setting_state.dart';
import '../../widgets/setting_widget.dart';
import 'setting_sheet.dart';

class LicensesPage extends ConsumerStatefulWidget {
  const LicensesPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LicensesPageState();
}

class _LicensesPageState extends SettingState<LicensesPage> {
  Map<String, List<List<LicenseParagraph>>> packages = {};
  Map<List<String>, List<LicenseParagraph>> licenses = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final Stream stream = LicenseRegistry.licenses;
    await for (final LicenseEntry license in stream) {
      packages[license.packages.toList().first] = [];
      licenses[license.packages.toList()] = license.paragraphs.toList();
    }

    packages.forEach((packageKey, packageVal) {
      licenses.forEach((licenseKey, licenseVal) {
        if (licenseKey.contains(packageKey)) {
          packages[packageKey]?.add(licenseVal);
        }
      });
    });

    setState(() => packages = packages);
  }

  @override
  String get title => 'ライセンス情報';

  @override
  Widget buildChild(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;

    if (packages.isEmpty) {
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

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 40,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final String package = packages.keys.toList()[index];
        final List<List<LicenseParagraph>> paragraphs =
            packages.values.toList()[index];

        return SettingSheet.settingItem(
          layout: layout,
          menu: package,
          onTap: () =>
              SettingWidget.push(context, LicenseChild(package, paragraphs)),
        );
      },
    );
  }
}

class LicenseChild extends ConsumerWidget {
  const LicenseChild(this.package, this.paragraphs, {super.key});
  final String package;
  final List<List<LicenseParagraph>> paragraphs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return SettingWidget.pageTemp(
      context: context,
      layout: layout,
      title: package,
      child: ListView.separated(
        itemCount: paragraphs.length,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 40,
        ),
        separatorBuilder: (context, index) {
          return Divider(height: 60, color: layout.subText);
        },
        itemBuilder: (context, index) {
          final List<LicenseParagraph> paragraph = paragraphs[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paragraph.map((LicenseParagraph p) {
              return Padding(
                  padding: EdgeInsets.only(
                    top: 5,
                    bottom: 5,
                    right: 10,
                    left: 10 + (10 * p.indent.toDouble()),
                  ),
                  child: Text(
                    p.text,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: layout.mainText,
                    ),
                  ));
            }).toList(),
          );
        },
      ),
    );
  }
}
