/// Where the Thandal backend lives.
///
/// Set it at build/run time (no code change needed):
///   flutter run --dart-define=THANDAL_API_BASE_URL=https://your-domain.com/api
///
/// The default below points at a backend running on your own computer:
///   * Android emulator  -> 10.0.2.2 is the emulator's name for your computer
///   * iOS simulator     -> use http://127.0.0.1:8000/api
///   * Real phone        -> use your computer's LAN IP, e.g. http://192.168.1.20:8000/api
///     (start the backend with:  php artisan serve --host=0.0.0.0 --port=8000)
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'THANDAL_API_BASE_URL',
    defaultValue: 'http://192.168.0.235:8000/api',
  );

  /// How long to wait for the server before showing a "can't reach server" message.
  static const Duration timeout = Duration(seconds: 25);
}
