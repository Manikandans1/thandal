/// Any failure talking to the backend, with a message that is safe to show to the user.
class ApiException implements Exception {
  final String message;

  /// HTTP status, or 0 when the server could not be reached at all.
  final int statusCode;

  /// Laravel validation errors: field name -> first message.
  final Map<String, String> fieldErrors;

  /// Only set on failed logins ("2 attempts left").
  final int? attemptsLeft;

  const ApiException(
    this.message, {
    this.statusCode = 0,
    this.fieldErrors = const {},
    this.attemptsLeft,
  });

  bool get isNetwork => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;

  @override
  String toString() => message;
}
