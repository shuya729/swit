import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../models/label.dart';
import '../models/layout.dart';
import '../widgets/setting_dialog.dart';
import '../widgets/setting_state.dart';
import 'home_page.dart';
import '../providers/layout_providers.dart';
import '../widgets/loading_dialog.dart';

class LayoutPage extends ConsumerWidget {
  const LayoutPage({super.key});

  double calcScale(BuildContext context) {
    final double pageHeight = MediaQuery.of(context).size.height;
    final double scaledHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        150;
    return scaledHeight / pageHeight;
  }

  static const List<Color> colors = <MaterialColor>[
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    final double scale = calcScale(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: layout.subText,
                width: 1,
              ),
              image: layout.image == null
                  ? null
                  : DecorationImage(
                      image: FileImage(layout.image!),
                      fit: BoxFit.cover,
                    ),
            ),
            height: height,
            width: width,
            child: const HomePage(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 50,
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(
                      colors.length + 1,
                      (index) {
                        if (index < colors.length) {
                          final Color color = colors[index];
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(layoutProvider.notifier)
                                  .changeTheme(color);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  width: 1,
                                  color: layout.theme.value == color.value
                                      ? layout.mainText
                                      : layout.subText,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: IconButton(
                              onPressed: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (_) => BackImageSheet(
                                    calcHeight: height * scale,
                                    calcWidth: width * scale,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 24,
                                color: layout.subText,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(
                    //
                    //
                    // children: [
                    //   Expanded(
                    //     child: ListView.builder(
                    //       shrinkWrap: true,
                    //       itemCount: Labels.all.length,
                    //       scrollDirection: Axis.horizontal,
                    //       padding: const EdgeInsets.symmetric(horizontal: 10),
                    //       itemBuilder: (context, index) {
                    //
                    //
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(
                      Labels.all.length,
                      (index) {
                        //
                        //
                        final Label label = Labels.all[index];
                        return Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              ref
                                  .read(layoutProvider.notifier)
                                  .changeLabel(label);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: layout.subText, width: 1),
                              ),
                              child: Image(
                                image: label.headImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  //
                  //
                  //     Container(
                  //       width: 40,
                  //       height: 40,
                  //       alignment: Alignment.center,
                  //       decoration: BoxDecoration(
                  //         border: Border(
                  //           left: BorderSide(
                  //             color: layout.subText,
                  //             width: 1.5,
                  //           ),
                  //         ),
                  //       ),
                  //       child: IconButton(
                  //         onPressed: () {
                  //           showModalBottomSheet(
                  //             useSafeArea: true,
                  //             isScrollControlled: true,
                  //             context: context,
                  //             builder: (context) => const LabelSheet(),
                  //           );
                  //         },
                  //         icon: Icon(
                  //           Icons.keyboard_arrow_up,
                  //           size: 24,
                  //           color: layout.mainText,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  //
                  //
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BackImageSheet extends ConsumerWidget {
  const BackImageSheet({
    super.key,
    required this.calcHeight,
    required this.calcWidth,
  });
  final double calcHeight;
  final double calcWidth;

  Future<void> selectImage(LayoutNotifier notifier) async {
    final XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;
    final croppedImage = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      aspectRatio: CropAspectRatio(ratioX: calcWidth, ratioY: calcHeight),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '画像を編集',
          hideBottomControls: true,
        ),
      ],
    );
    if (croppedImage == null) return;
    await notifier.changeImage(File(croppedImage.path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return CupertinoActionSheet(
      actions: (layout.image == null)
          ? [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  LoadingDialog(selectImage(ref.read(layoutProvider.notifier)))
                      .show(context);
                },
                child: Text(
                  'ライブラリから選択',
                  style: TextStyle(color: layout.subBack),
                ),
              ),
            ]
          : [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  LoadingDialog(selectImage(ref.read(layoutProvider.notifier)))
                      .show(context);
                },
                child: Text(
                  'ライブラリから選択',
                  style: TextStyle(color: layout.subBack),
                ),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  LoadingDialog(
                    ref.read(layoutProvider.notifier).changeImage(null),
                  ).show(context);
                },
                child: const Text('背景を削除'),
              ),
            ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('キャンセル', style: TextStyle(color: layout.subBack)),
      ),
    );
  }
}

class LabelSheet extends ConsumerStatefulWidget {
  const LabelSheet({super.key});

  @override
  SettingState<ConsumerStatefulWidget> createState() => _LabelSheetState();
}

class _LabelSheetState extends SettingState<LabelSheet> {
  @override
  String get title => 'ラベル';
  @override
  bool get isRoot => true;

  Widget labelGrid({required Layout layout, required List<Label> labels}) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 75),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 90,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: labels.length,
      itemBuilder: (context, index) {
        final Label label = labels[index];
        return GestureDetector(
          onTap: () => LabelDialog(showMsgbar, label: label).show(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: layout.subText, width: 1),
            ),
            child: Image(
              image: label.headImage,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildChild(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return DefaultTabController(
      length: Labels.categories.length + 1,
      child: Column(
        children: [
          TabBar(
            isScrollable: false,
            dividerHeight: 0,
            indicatorWeight: 1.0,
            labelColor: layout.subBack,
            indicatorColor: layout.subBack,
            unselectedLabelColor: layout.mainText,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
            tabs: [
              const Tab(text: 'マイラベル', height: 32),
              ...Labels.categories
                  .map((String category) => Tab(text: category, height: 32)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                labelGrid(layout: layout, labels: Labels.all),
                ...Labels.categories.map((String category) {
                  final List<Label> labels = Labels.all
                      .where((Label label) => label.category == category)
                      .toList();
                  return labelGrid(layout: layout, labels: labels);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LabelDialog extends SettingDialog {
  const LabelDialog(super.showMsgbar, {super.key, required this.label});
  final Label label;

  Future<void> _purchase() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Widget _labelBtn(
    BuildContext context,
    WidgetRef ref,
    Layout layout,
    Label currentLabel,
  ) {
    if (label.id == currentLabel.id) {
      return OutlinedButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          foregroundColor: layout.subText,
          side: BorderSide(color: layout.subText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('選択'),
      );
      // } else if (true) {
      //   return ElevatedButton(
      //     onPressed: () {
      //       LoadingDialog(_purchase()).show(context).whenComplete(() {
      //         Navigator.of(context).popUntil((route) => route.isFirst);
      //         ref.read(layoutProvider.notifier).changeLabel(label);
      //       });
      //     },
      //     style: ElevatedButton.styleFrom(
      //       visualDensity: VisualDensity.compact,
      //       padding: const EdgeInsets.symmetric(horizontal: 15),
      //       foregroundColor: layout.mainText,
      //       backgroundColor: layout.subBack,
      //       side: BorderSide(color: layout.subBack),
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(10),
      //       ),
      //     ),
      //     child: const Text('購入'),
      //   );
    } else {
      return ElevatedButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(layoutProvider.notifier).changeLabel(label);
        },
        style: ElevatedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          foregroundColor: layout.mainText,
          backgroundColor: layout.subBack,
          side: BorderSide(color: layout.subBack),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('選択'),
      );
    }
  }

  @override
  Widget buildContent(BuildContext context, WidgetRef ref, Layout layout) {
    final Label currentLabel = ref.read(layoutProvider)?.label ?? Label.def;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Image(
            image: label.bodyImage,
            fit: BoxFit.contain,
          ),
        ),
        _labelBtn(context, ref, layout, currentLabel),
      ],
    );
  }
}
