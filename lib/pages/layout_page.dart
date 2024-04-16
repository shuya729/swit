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
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: layout.mainText,
                width: 5,
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
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                width: 1.5,
                                color: layout.theme == color
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
                              Icons.add_photo_alternate,
                              size: 25,
                              color: layout.mainText,
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
      compressQuality: 50,
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
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Navigator.of(context).pop();
                  LoadingDialog(selectImage(ref.read(layoutProvider.notifier)))
                      .show(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 57,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: layout.mainText.withOpacity(0.8),
                  alignment: Alignment.center,
                  child: Text(
                    '画像を選択する',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: layout.subBack,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ]
          : [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Navigator.of(context).pop();
                  LoadingDialog(selectImage(ref.read(layoutProvider.notifier)))
                      .show(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 57,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: layout.mainText.withOpacity(0.8),
                  alignment: Alignment.center,
                  child: Text(
                    '画像を選択',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: layout.subBack,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Navigator.of(context).pop();
                  LoadingDialog(
                    ref.read(layoutProvider.notifier).changeImage(null),
                  ).show(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 57,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: layout.mainText.withOpacity(0.8),
                  alignment: Alignment.center,
                  child: const Text(
                    '画像を削除',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
      cancelButton: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          decoration: BoxDecoration(
            color: layout.mainText.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          width: double.infinity,
          height: 57,
          alignment: Alignment.center,
          child: Text(
            'キャンセル',
            style: TextStyle(
              fontSize: 18,
              color: layout.subBack,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
