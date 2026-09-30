import '../api/api_client.dart';

/// PIN-related calls shared by all three apps (same rules for everyone, enforced by the server).
class AuthApi {
  AuthApi._();

  /// Signed-in user changes their own PIN.
  static Future<void> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    await ApiClient.instance.post('/auth/change-pin', body: {
      'current_pin': currentPin,
      'pin': newPin,
      'pin_confirmation': confirmPin,
    });
  }

  /// After an admin reset the PIN: mobile + the temporary PIN + the new PIN the person chose.
  /// Works without being logged in.
  static Future<void> setNewPin({
    required String mobile,
    required String temporaryPin,
    required String newPin,
    required String confirmPin,
  }) async {
    await ApiClient.instance.post('/auth/set-new-pin', body: {
      'mobile': mobile,
      'temporary_pin': temporaryPin,
      'pin': newPin,
      'pin_confirmation': confirmPin,
    });
  }
}
