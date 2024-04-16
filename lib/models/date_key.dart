class DateKey {
  late final String _value;

  DateKey(String value) {
    if (isKey(value)) {
      _value = value;
    } else {
      _value = '0000-00-00';
    }
  }

  String get key => _value;

  static bool isKey(String key) {
    final RegExp regExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regExp.hasMatch(key)) return false;
    final List<String> parts = key.split('-');
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  String get monthKey {
    final List<String> parts = _value.split('-');
    final String yearStr = parts[0];
    final String monthStr = parts[1];
    return '$yearStr-$monthStr';
  }

  factory DateKey.fromDateTime(DateTime dateTime) {
    final String yearStr = dateTime.year.toString();
    final String monthStr = dateTime.month.toString().padLeft(2, '0');
    final String dayStr = dateTime.day.toString().padLeft(2, '0');
    return DateKey('$yearStr-$monthStr-$dayStr');
  }

  factory DateKey.fromDate(int year, int month, int day) {
    final String yearStr = year.toString();
    final String monthStr = month.toString().padLeft(2, '0');
    final String dayStr = day.toString().padLeft(2, '0');
    return DateKey('$yearStr-$monthStr-$dayStr');
  }
}
