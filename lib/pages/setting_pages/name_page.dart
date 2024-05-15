import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_state.dart';

class NamePage extends ConsumerStatefulWidget {
  const NamePage(this.myData, {super.key});
  final UserData myData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NamePageState();
}

class _NamePageState extends SettingState<NamePage> {
  late final TextEditingController _nameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.myData.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(String name) async {
    try {
      await widget.myData.update(name: name);
    } catch (e) {
      showMsgbar('名前の更新に失敗しました。');
    }
  }

  @override
  String get title => '名前';

  @override
  Widget buildChild(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + keyboardHeight + 40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    '名前を入力して下さい。',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: layout.mainText,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    maxLength: 20,
                    cursorHeight: 23,
                    cursorColor: layout.subBack,
                    style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 17,
                        color: layout.mainText),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.all(5),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: layout.subText),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: layout.subBack),
                      ),
                      hintText: '名前',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 17,
                        color: layout.subText,
                      ),
                      errorStyle: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 13,
                          color: layout.error),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: layout.error),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: layout.error),
                      ),
                      counterStyle: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          color: layout.subText),
                    ),
                    validator: (value) {
                      value = value?.trim();
                      if (value == null || value.isEmpty) {
                        return '名前を入力してください。';
                      } else if (value.length > 20) {
                        return '名前は20文字以内で入力してください。';
                      } else if (value == widget.myData.name) {
                        return '変更がありません。';
                      } else {
                        return null;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 60),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final String name = _nameController.text.trim();
                        LoadingDialog(_save(name)).show(context).then((_) {
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
            ),
          ),
        ),
      ),
    );
  }
}
