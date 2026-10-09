class Validators {
  static String? requiredChoice(String? value, String message) {
    return value == null || value.isEmpty ? message : null;
  }

  static String? destination(String? value, String? origin) {
    if (value == null || value.isEmpty) return 'Tujuan wajib dipilih';
    if (value == origin) return 'Tujuan harus berbeda dari asal';
    return null;
  }

  static final RegExp _timePattern = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

  static DateTime? parseTime(String input, DateTime now) {
    final match = _timePattern.firstMatch(input.trim());
    if (match == null) return null;
    return DateTime(now.year, now.month, now.day, int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  static String? arriveBy(String? input, DateTime now) {
    if (input == null || input.trim().isEmpty) return 'Jam tiba wajib diisi';
    final time = parseTime(input, now);
    if (time == null) return 'Format jam harus HH:mm';
    if (time.isBefore(now)) return 'Jam tiba sudah lewat';
    return null;
  }
}
