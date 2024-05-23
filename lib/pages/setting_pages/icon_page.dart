import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/icon_widget.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_state.dart';

class IconPage extends ConsumerStatefulWidget {
  const IconPage(this.myData, {super.key});
  final UserData myData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IconPageState();
}

class _IconPageState extends SettingState<IconPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _imageFile;
  String _error = '';

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return;
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: pickedImage.path,
        cropStyle: CropStyle.circle,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 0,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '画像を編集',
            hideBottomControls: true,
          ),
        ],
      );
      if (croppedImage == null) return;
      setState(() => _imageFile = File(croppedImage.path));
    } catch (e) {
      showMsgbar('画像の取得に失敗しました。');
    }
  }

  Future<void> _save(File imageFile) async {
    try {
      final String path = 'users/${widget.myData.uid}/iconImage.jpg';
      final Reference ref = _storage.ref().child(path);
      await ref.putFile(imageFile);
      final String image = await ref.getDownloadURL();
      await widget.myData.update(image: image);
    } catch (e) {
      showMsgbar('アイコン画像の更新に失敗しました。');
    }
  }

  @override
  String get title => 'アイコン画像';

  @override
  Widget buildChild(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 40,
      ),
      children: [
        const SizedBox(height: 15),
        Center(
          child: Text(
            'アイコン画像を選択して下さい。',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 16,
              color: layout.mainText,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => LoadingDialog(_pickImage()).show(context),
            child: _imageFile == null
                ? IconWidget(widget.myData.image, radius: 40)
                : CircleAvatar(
                    radius: 40,
                    backgroundImage: Image.file(_imageFile!).image,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            height: 20,
            child: _error.isEmpty
                ? null
                : Text(
                    _error,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: layout.error,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (_imageFile == null) {
                setState(() => _error = '新しい画像が選択されていません。');
              } else {
                LoadingDialog(_save(_imageFile!)).show(context).then((_) {
                  Navigator.of(context).pop();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: layout.mainText,
              backgroundColor: layout.subBack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }
}
