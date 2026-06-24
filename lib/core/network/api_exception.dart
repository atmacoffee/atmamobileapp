class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class SessionExpiredException extends ApiException {
  const SessionExpiredException([super.message = 'Sesi login berakhir. Silakan masuk lagi.']);
}
