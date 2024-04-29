import 'package:cloud_firestore/cloud_firestore.dart';

import 'date_key.dart';

class Logs implements Map<String, int> {
  final Map<String, int> _data = {};

  @override
  int? operator [](Object? key) => _data[key];

  @override
  void operator []=(String key, int value) {
    _data[key] = value;
  }

  @override
  void addAll(Map<String, int> other) {
    _data.addAll(other);
  }

  @override
  void addEntries(Iterable<MapEntry<String, int>> entries) {
    _data.addEntries(entries);
  }

  @override
  Map<RK, RV> cast<RK, RV>() => _data.cast<RK, RV>();

  @override
  bool containsKey(Object? key) => _data.containsKey(key);

  @override
  bool containsValue(Object? value) => _data.containsValue(value);

  @override
  void forEach(void Function(String key, int value) f) {
    _data.forEach(f);
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(String key, int value) f) {
    return _data.map<K2, V2>(f);
  }

  @override
  int putIfAbsent(String key, int Function() ifAbsent) {
    return _data.putIfAbsent(key, ifAbsent);
  }

  @override
  int? remove(Object? key) {
    return _data.remove(key);
  }

  @override
  void removeWhere(bool Function(String key, int value) predicate) {
    _data.removeWhere(predicate);
  }

  @override
  int update(String key, int Function(int value) update,
      {int Function()? ifAbsent}) {
    return _data.update(key, update, ifAbsent: ifAbsent);
  }

  @override
  void updateAll(int Function(String key, int value) update) {
    _data.updateAll(update);
  }

  @override
  Iterable<MapEntry<String, int>> get entries => _data.entries;

  @override
  void clear() {
    _data.clear();
  }

  @override
  Iterable<String> get keys => _data.keys;

  @override
  Iterable<int> get values => _data.values;

  @override
  int get length => _data.length;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  void fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data.forEach((key, value) {
      if (DateKey.isKey(key) && value is int) {
        _data[DateKey(key).key] = value;
      }
    });
  }

  void calcNow(DateTime? bgn, DateTime now) {
    if (bgn == null || bgn.isAfter(now)) return;
    if (bgn.year != now.year || bgn.month != now.month || bgn.day != now.day) {
      final DateKey dateKey = DateKey.fromDateTime(bgn);
      final DateTime baseDate = DateTime(bgn.year, bgn.month, bgn.day + 1);
      final int diff = baseDate.difference(bgn).inMilliseconds;
      _data[dateKey.key] = diff + (_data[dateKey.key] ?? 0);
      calcNow(baseDate, now);
    } else {
      final DateKey dateKey = DateKey.fromDateTime(now);
      final int diff = now.difference(bgn).inMilliseconds;
      _data[dateKey.key] = diff + (_data[dateKey.key] ?? 0);
    }
  }

  int gettime(DateKey dateKey) => _data[dateKey.key] ?? 0;

  int getMonthtime(DateTime now) {
    final DateKey dateKey = DateKey.fromDateTime(now);
    final String monthKey = dateKey.monthKey;
    return _data.entries
        .where((entry) => entry.key.startsWith(monthKey))
        .map((entry) => entry.value)
        .fold<int>(0, (prev, element) => prev + element);
  }

  static String formattime(int time) {
    final int hours = time ~/ 3600000;
    final int minutes = (time % 3600000) ~/ 60000;
    return '$hours時間 $minutes分';
  }
}
