class AuthSession {
  const AuthSession({required this.token, required this.userId, required this.email, required this.name});

  final String token;
  final String userId;
  final String email;
  final String name;
}
