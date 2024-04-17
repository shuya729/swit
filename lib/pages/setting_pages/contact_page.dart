import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_page_temp.dart';

class ContactPage extends ConsumerStatefulWidget {
  const ContactPage(this.user, this.myData, {super.key});
  final User? user;
  final UserData? myData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  final TextEditingController _contentController = TextEditingController();
  int _subjectValue = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _nameController = TextEditingController(text: widget.myData?.name ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final int subject = _subjectValue;
    final String content = _contentController.text.trim();
    await firestore.collection('contacts').add({
      'uid': widget.user?.uid,
      'name': name,
      'email': email,
      'subject': subject,
      'content': content,
      'credt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return SettingPageTemp(
      title: 'お問い合わせ',
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '名前',
                    style: TextStyle(fontSize: 15, color: layout.mainText),
                  ),
                ),
                TextFormField(
                  controller: _nameController,
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
                    errorStyle:
                        const TextStyle(fontSize: 13, color: Colors.red),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    counterStyle:
                        TextStyle(fontSize: 12, color: layout.subText),
                  ),
                  validator: (value) {
                    value = value?.trim();
                    if (value == null || value.isEmpty) {
                      return '名前を入力してください。';
                    } else if (value.length > 20) {
                      return '名前は20文字以内で入力してください。';
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'メールアドレス',
                    style: TextStyle(fontSize: 15, color: layout.mainText),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
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
                    hintText: 'メールアドレス',
                    hintStyle: TextStyle(
                      fontSize: 17,
                      color: layout.subText,
                    ),
                    errorStyle:
                        const TextStyle(fontSize: 13, color: Colors.red),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    counterStyle:
                        TextStyle(fontSize: 12, color: layout.subText),
                  ),
                  validator: (value) {
                    value = value?.trim();
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください。';
                    } else if (!RegExp(
                            r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')
                        .hasMatch(value)) {
                      return '形式が正しくありません。';
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '件名',
                    style: TextStyle(fontSize: 15, color: layout.mainText),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Radio(
                            value: 0,
                            groupValue: _subjectValue,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                setState(() => _subjectValue = 0),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(0),
                            ),
                            onPressed: () => setState(() => _subjectValue = 0),
                            child: Text(
                              'ご意見',
                              style: TextStyle(
                                  fontSize: 15, color: layout.mainText),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Radio(
                            value: 1,
                            groupValue: _subjectValue,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                setState(() => _subjectValue = 1),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(0),
                            ),
                            onPressed: () => setState(() => _subjectValue = 1),
                            child: Text(
                              '不具合報告',
                              style: TextStyle(
                                  fontSize: 15, color: layout.mainText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Radio(
                            value: 2,
                            groupValue: _subjectValue,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                setState(() => _subjectValue = 2),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(0),
                            ),
                            onPressed: () => setState(() => _subjectValue = 2),
                            child: Text(
                              'アカウント削除申請',
                              style: TextStyle(
                                  fontSize: 15, color: layout.mainText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Radio(
                            value: 3,
                            groupValue: _subjectValue,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                setState(() => _subjectValue = 3),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(0),
                            ),
                            onPressed: () => setState(() => _subjectValue = 3),
                            child: Text(
                              'その他',
                              style: TextStyle(
                                  fontSize: 15, color: layout.mainText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'お問い合わせ内容',
                    style: TextStyle(fontSize: 15, color: layout.mainText),
                  ),
                ),
                TextFormField(
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  controller: _contentController,
                  cursorHeight: 23,
                  cursorColor: layout.subBack,
                  style: TextStyle(fontSize: 17, color: layout.mainText),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.all(5),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: layout.subText),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: layout.subBack),
                    ),
                    hintText: 'お問い合わせ内容',
                    hintStyle: TextStyle(
                      fontSize: 17,
                      color: layout.subText,
                    ),
                    errorStyle:
                        const TextStyle(fontSize: 13, color: Colors.red),
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    counterStyle:
                        TextStyle(fontSize: 12, color: layout.subText),
                  ),
                  validator: (value) {
                    value = value?.trim();
                    if (value == null || value.isEmpty) {
                      return 'お問い合わせ内容を入力してください。';
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      LoadingDialog(_send()).show(context).then((_) {
                        Navigator.pop(context);
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
                  child: const Text('送信'),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
