import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_page_temp.dart';

class NamePage extends ConsumerStatefulWidget {
  const NamePage(this.myData, {super.key});
  final UserData myData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<NamePage> {
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
    await widget.myData.update(name: name);
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return SettingPageTemp(
      title: '名前',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Spacer(),
            Text(
              '名前を入力して下さい。',
              style: TextStyle(fontSize: 16, color: layout.mainText),
            ),
            Container(
              constraints: const BoxConstraints(
                minWidth: 200,
                maxWidth: 400,
                minHeight: 80,
                maxHeight: 80,
              ),
              alignment: Alignment.center,
              child: TextFormField(
                controller: _nameController,
                maxLength: 20,
                cursorHeight: 23,
                cursorColor: layout.subBack,
                style: TextStyle(fontSize: 17, color: layout.mainText),
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
                    fontSize: 17,
                    color: layout.subText,
                  ),
                  errorStyle: const TextStyle(fontSize: 13, color: Colors.red),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  counterStyle: TextStyle(fontSize: 12, color: layout.subText),
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
            const Spacer(flex: 2),
            Container(
              constraints: const BoxConstraints(minHeight: 50),
              height: keyboardHeight,
              alignment: Alignment.center,
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
                  foregroundColor: layout.subText,
                  backgroundColor: layout.subBack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('保存'),
              ),
            ),
            const Spacer(),
            SizedBox(height: MediaQuery.of(context).padding.bottom)
          ],
        ),
      ),
    );
  }
}
