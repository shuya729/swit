import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Layout {
  const Layout({
    required this.theme,
    required this.mainBack,
    required this.mainText,
    required this.subBack,
    required this.subText,
    required this.image,
    this.error = const Color(0xFFD32F2F),
  });

  final Color theme;
  final Color mainBack;
  final Color mainText;
  final Color subBack;
  final Color subText;
  final File? image;
  final Color error;

  static const double _mainBackRate = 0.6;
  static const double _subTextRate = 0.3;

  static Layout get def {
    const Color defTheme = Colors.teal;
    return Layout(
      theme: defTheme,
      mainBack: Color.lerp(Colors.white, defTheme, _mainBackRate)!,
      mainText: Colors.white,
      subBack: defTheme,
      subText: Color.lerp(Colors.white, defTheme, _subTextRate)!,
      image: null,
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
    );
  }

  static Layout read({required SharedPreferences prefs}) {
    Layout layout = def;
    final int? theme = prefs.getInt('theme');
    final String imagePath = prefs.getString('imagePath') ?? '';
    if (theme != null) {
      layout = layout._copyWithColor(Color(theme));
    }
    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      layout = layout._copyWithImage(File(imagePath));
    }
    return layout;
  }

  Future<Layout> update({
    required Color theme,
    required File? image,
    required SharedPreferences prefs,
    required String imagePath,
  }) async {
    if (theme != this.theme) {
      await prefs.setInt('theme', theme.value);
    }
    if (image != this.image) {
      if (image != null) {
        await prefs.setString('imagePath', imagePath);
        await File(imagePath).writeAsBytes(image.readAsBytesSync());
      } else {
        await prefs.remove('imagePath');
        await File(this.image!.path).delete();
      }
    }
    return Layout(
      theme: theme,
      mainBack: Color.lerp(Colors.white, theme, _mainBackRate)!,
      mainText: Colors.white,
      subBack: theme,
      subText: Color.lerp(Colors.white, theme, _subTextRate)!,
      image: image,
    );
  }
}
