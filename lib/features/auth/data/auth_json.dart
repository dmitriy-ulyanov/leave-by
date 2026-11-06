import '../domain/auth_session.dart';

Map<String, dynamic> authSessionToJson(AuthSession session) {
  return {
    'token': session.token,
    'user': {'id': session.userId, 'email': session.email, 'name': session.name},
  };
}

AuthSession authSessionFromJson(Map<String, dynamic> json) {
  final user = json['user'];
  if (user is! Map<String, dynamic>) throw const FormatException('Field "user" tidak valid');
  return AuthSession(
    token: _requiredString(json, 'token'),
    userId: _requiredString(user, 'id'),
    email: _requiredString(user, 'email'),
    name: _requiredString(user, 'name'),
  );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Field "$key" wajib berupa teks yang tidak kosong');
  }
  return value;
}
