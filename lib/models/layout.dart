import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'label.dart';

class Layout {
  const Layout({
    required this.theme,
    required this.mainBack,
    required this.mainText,
    required this.subBack,
    required this.subText,
    required this.image,
    this.error = const Color(0xFFD32F2F),
    required this.label,
  });

  final Color theme;
  final Color mainBack;
  final Color mainText;
  final Color subBack;
  final Color subText;
  final File? image;
  final Color error;
  final Label label;

  static const double _mainBackRate = 0.6;
  static const double _subTextRate = 0.3;
  static const String _imageFile = 'image.jpg';

  static Layout get def {
    const Color defTheme = Colors.teal;
    return Layout(
      theme: defTheme,
      mainBack: Color.lerp(Colors.white, defTheme, _mainBackRate)!,
      mainText: Colors.white,
      subBack: defTheme,
      subText: Color.lerp(Colors.white, defTheme, _subTextRate)!,
      image: null,
      label: Label.def,
    );
  }

  Layout _copyWithColor(Color theme) {
    return Layout(
      theme: theme,
      mainBack: Color.lerp(Colors.white, theme, _mainBackRate)!,
      mainText: Colors.white,
      subBack: theme,
      subText: Color.lerp(Colors.white, theme, _subTextRate)!,
      image: image,
      label: label,
    );
  }

  Layout _copyWithImage(File? image) {
    return Layout(
      theme: theme,
      mainBack: mainBack,
      mainText: mainText,
      subBack: subBack,
      subText: subText,
      image: image,
      label: label,
    );
  }

  Layout _copyWithLabel(Label label) {
    return Layout(
      theme: theme,
      mainBack: mainBack,
      mainText: mainText,
      subBack: subBack,
      subText: subText,
      image: image,
      label: label,
    );
  }

  static Layout read({
    required SharedPreferences prefs,
    required String localPath,
  }) {
    Layout layout = def;
    final int? theme = prefs.getInt('theme');
    final String imageFile = prefs.getString('imageFile') ?? '';
    final String imagePath = '$localPath/$imageFile';
    final String labelId = prefs.getString('labelId') ?? Label.def.id;
    if (theme != null) {
      layout = layout._copyWithColor(Color(theme));
    }
    if (imageFile.isNotEmpty && File(imagePath).existsSync()) {
      layout = layout._copyWithImage(File(imagePath));
    }
    layout = layout._copyWithLabel(Label.fromId(labelId));
    return layout;
  }

  Future<Layout> update({
    required Color theme,
    required File? image,
    required Label label,
    required SharedPreferences prefs,
    required String localPath,
  }) async {
    if (theme != this.theme) {
      await prefs.setInt('theme', theme.value);
    }
    if (image != this.image) {
      final String imagePath = '$localPath/$_imageFile';
      if (image != null) {
        await prefs.setString('imageFile', _imageFile);
        await File(imagePath).writeAsBytes(image.readAsBytesSync());
      } else {
        await prefs.remove('imageFile');
        await File(this.image!.path).delete();
      }
    }
    if (label.id != this.label.id) {
      await prefs.setString('labelId', label.id);
    }
    return Layout(
      theme: theme,
      mainBack: Color.lerp(Colors.white, theme, _mainBackRate)!,
      mainText: Colors.white,
      subBack: theme,
      subText: Color.lerp(Colors.white, theme, _subTextRate)!,
      image: image,
      label: label,
    );
  }
}
