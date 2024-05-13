import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout.dart';
import '../../models/user_data.dart';
import '../../providers/layout_providers.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/setting_state.dart';

class ContactPage extends ConsumerStatefulWidget {
  const ContactPage(this.user, this.myData, {super.key});
  final User? user;
  final UserData? myData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContactPageState();
}

class _ContactPageState extends SettingState<ContactPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;
  int _subjectValue = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _nameController = TextEditingController(text: widget.myData?.name ?? '');
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    try {
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
    } catch (e) {
      showMsgbar('お問い合わせの送信に失敗しました。');
    }
  }

  @override
  String get title => 'お問い合わせ';

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
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '名前',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 15,
                      color: layout.mainText,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  cursorHeight: 23,
                  cursorColor: layout.subBack,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 17,
                    color: layout.mainText,
                  ),
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
                      color: layout.error,
                    ),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 15,
                        color: layout.mainText),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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
                    hintText: 'メールアドレス',
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 17,
                      color: layout.subText,
                    ),
                    errorStyle: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 13,
                      color: layout.error,
                    ),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 15,
                        color: layout.mainText),
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
                            fillColor: MaterialStateProperty.resolveWith(
                              (states) =>
                                  states.contains(MaterialState.selected)
                                      ? layout.subBack
                                      : layout.subText,
                            ),
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
                                fontWeight: FontWeight.w300,
                                fontSize: 15,
                                color: layout.mainText,
                              ),
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
                            fillColor: MaterialStateProperty.resolveWith(
                              (states) =>
                                  states.contains(MaterialState.selected)
                                      ? layout.subBack
                                      : layout.subText,
                            ),
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
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15,
                                  color: layout.mainText),
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
                            fillColor: MaterialStateProperty.resolveWith(
                              (states) =>
                                  states.contains(MaterialState.selected)
                                      ? layout.subBack
                                      : layout.subText,
                            ),
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
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15,
                                  color: layout.mainText),
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
                            fillColor: MaterialStateProperty.resolveWith(
                              (states) =>
                                  states.contains(MaterialState.selected)
                                      ? layout.subBack
                                      : layout.subText,
                            ),
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
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15,
                                  color: layout.mainText),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 15,
                        color: layout.mainText),
                  ),
                ),
                TextFormField(
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  controller: _contentController,
                  cursorHeight: 23,
                  cursorColor: layout.subBack,
                  style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 17,
                      color: layout.mainText),
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
                      fontWeight: FontWeight.w300,
                      fontSize: 17,
                      color: layout.subText,
                    ),
                    errorStyle: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 13,
                      color: layout.error,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: layout.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
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
                      return 'お問い合わせ内容を入力してください。';
                    } else {
                      return null;
                    }
                  },
                ),
                const SizedBox(height: 50),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        LoadingDialog(_send()).show(context).then((_) {
                          Navigator.pop(context);
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
                    child: const Text('送信'),
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
