import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/layout.dart';

final layoutProvider = StateNotifierProvider<LayoutNotifier, Layout?>((_) {
  return LayoutNotifier();
});

class LayoutNotifier extends StateNotifier<Layout?> {
  LayoutNotifier() : super(null) {
    init();
  }

  SharedPreferences? _prefs;
  String? _localPath;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final Directory localPath = await getApplicationDocumentsDirectory();
    _localPath = localPath.path;
    state = Layout.read(prefs: _prefs!, localPath: _localPath!);
  }

  Future<void> changeTheme(Color theme) async {
    if (state == null || _prefs == null || _localPath == null) return;
    state = await state!.update(
      theme: theme,
      image: state!.image,
      prefs: _prefs!,
      localPath: _localPath!,
    );
  }

  Future<void> changeImage(File? image) async {
    if (state == null || _prefs == null || _localPath == null) return;
    state = await state!.update(
      theme: state!.theme,
      image: image,
      prefs: _prefs!,
      localPath: _localPath!,
    );
  }
}
