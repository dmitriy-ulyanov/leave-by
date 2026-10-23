class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  factory ApiException.network() =>
      const ApiException('Tidak dapat terhubung ke server. Periksa koneksi lalu coba lagi.');

  factory ApiException.timeout() => const ApiException('Server tidak merespons. Coba lagi.');

  factory ApiException.malformed() => const ApiException('Respons server tidak dapat dibaca.');

  factory ApiException.http(int statusCode) {
    return ApiException('Server mengembalikan kesalahan (kode $statusCode).', statusCode: statusCode);
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
