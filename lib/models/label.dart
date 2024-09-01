// ignore_for_file: constant_identifier_names

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
      orElse: () => Labels.LB0101_cat,
    );
  }

  ImageProvider get headImage => AssetImage(head);
  ImageProvider get bodyImage => AssetImage(body);
}

final class Labels {
  static const Label LB0101_cat = Label(
    id: 'LB0101_cat',
    category: '動物',
    head: 'assets/labels/LB0101_cat/LB0101_cat.png',
    body: 'assets/labels/LB0101_cat/LB0101_cat.gif',
    paid: false,
  );

  static const Label LB0102_bird = Label(
    id: 'LB0102_bird',
    category: '動物',
    head: 'assets/labels/LB0102_bird/LB0102_bird.png',
    body: 'assets/labels/LB0102_bird/LB0102_bird.gif',
    paid: false,
  );

  static const Label LB0103_dolphin = Label(
    id: 'LB0103_dolphin',
    category: '動物',
    head: 'assets/labels/LB0103_dolphin/LB0103_dolphin.png',
    body: 'assets/labels/LB0103_dolphin/LB0103_dolphin.gif',
    paid: false,
  );

  static const Label LB0104_penguin = Label(
    id: 'LB0104_penguin',
    category: '動物',
    head: 'assets/labels/LB0104_penguin/LB0104_penguin.png',
    body: 'assets/labels/LB0104_penguin/LB0104_penguin.gif',
    paid: true,
  );

  static const Label LB0105_rabbit = Label(
    id: 'LB0105_rabbit',
    category: '動物',
    head: 'assets/labels/LB0105_rabbit/LB0105_rabbit.png',
    body: 'assets/labels/LB0105_rabbit/LB0105_rabbit.gif',
    paid: true,
  );

  static const List<Label> all = <Label>[
    LB0101_cat,
    LB0102_bird,
    LB0103_dolphin,
    LB0104_penguin,
    LB0105_rabbit,
  ];

  static List<String> get ids => all.map((Label label) => label.id).toList();
  static List<String> get categories =>
      all.map((Label label) => label.category).toSet().toList();
}
