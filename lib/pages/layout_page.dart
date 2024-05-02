import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../models/layout.dart';
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
        120;
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
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
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
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(9),
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
                          width: 26,
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
                              size: 25,
                              color: layout.subText,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
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
        ]);
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
