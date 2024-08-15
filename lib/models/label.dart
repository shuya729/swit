import 'package:flutter/material.dart';

class Label {
  final String id;
  final String category;
  final String head;
  final String body;
  final bool paid;

  static Label get def => Labels.all.first;

  const Label({
    required this.id,
    required this.category,
    required this.head,
    required this.body,
    required this.paid,
  });

  factory Label.fromId(String id) {
    return Labels.all.firstWhere(
      (Label label) => label.id == id,
      orElse: () => Labels._dolphin,
    );
  }

  ImageProvider get headImage => AssetImage(head);
  ImageProvider get bodyImage => AssetImage(body);
}

final class Labels {
  static const Label _cat = Label(
    id: '0101_cat',
    category: '動物',
    head: 'assets/labels/head/0101_cat.png',
    body: 'assets/labels/body/0101_cat.gif',
    paid: false,
  );

  static const Label _dolphin = Label(
    id: '0103_dolphin',
    category: '動物',
    head: 'assets/labels/head/0103_dolphin.png',
    body: 'assets/labels/body/0103_dolphin.gif',
    paid: false,
  );

  static const Label _penguin = Label(
    id: '0104_penguin',
    category: '動物',
    head: 'assets/labels/head/0104_penguin.png',
    body: 'assets/labels/body/0104_penguin.gif',
    paid: true,
  );

  static const List<Label> all = <Label>[
    _cat,
    _dolphin,
    _penguin,
  ];

  static List<String> get ids => all.map((Label label) => label.id).toList();
  static List<String> get categories =>
      all.map((Label label) => label.category).toSet().toList();
}
