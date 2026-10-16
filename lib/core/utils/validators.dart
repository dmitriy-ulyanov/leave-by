class Validators {
  static String? requiredChoice(String? value, String message) {
    return value == null || value.isEmpty ? message : null;
  }

  static String? requiredText(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  static String? destination(String? value, String? origin) {
    if (value == null || value.isEmpty) return 'Tujuan wajib dipilih';
    if (value == origin) return 'Tujuan harus berbeda dari asal';
    return null;
  }

  static String? tripDestination(String? value, String origin) {
    if (value == null || value.trim().isEmpty) return 'Tujuan wajib diisi';
    if (value.trim().toLowerCase() == origin.trim().toLowerCase()) return 'Tujuan harus berbeda dari asal';
    return null;
  }

  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) return 'Judul wajib diisi';
    if (value.trim().length > 60) return 'Judul maksimal 60 karakter';
    return null;
  }

  static String? note(String? value) {
    return (value ?? '').length > 200 ? 'Catatan maksimal 200 karakter' : null;
  }

  static final RegExp _timePattern = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

  static DateTime? parseTime(String input, DateTime now) {
    final match = _timePattern.firstMatch(input.trim());
    if (match == null) return null;
    return DateTime(now.year, now.month, now.day, int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  static String? timeFormat(String? input) {
    if (input == null || input.trim().isEmpty) return 'Jam tiba wajib diisi';
    if (parseTime(input, DateTime(2000)) == null) return 'Format jam harus HH:mm';
    return null;
  }

  static String? arriveBy(String? input, DateTime now) {
    if (input == null || input.trim().isEmpty) return 'Jam tiba wajib diisi';
    final time = parseTime(input, now);
    if (time == null) return 'Format jam harus HH:mm';
    if (time.isBefore(now)) return 'Jam tiba sudah lewat';
    return null;
  }
}
