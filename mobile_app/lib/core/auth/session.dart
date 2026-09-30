import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json_util.dart';

/// The three experiences packaged inside the one Thandal app.
enum UserRole { customer, agent, admin }

/// The signed-in person, as returned by the server.
class SessionUser {
  final int id;
  final String rawRole; // customer | agent | admin | super_admin
  final String name;
  final String mobile;
  final String? customerCode;
  final String? agentCode;

  const SessionUser({
    required this.id,
    required this.rawRole,
    required this.name,
    required this.mobile,
    this.customerCode,
    this.agentCode,
  });

  bool get isSuperAdmin => rawRole == 'super_admin';

  UserRole get role {
    switch (rawRole) {
      case 'customer':
        return UserRole.customer;
      case 'agent':
        return UserRole.agent;
      default:
        return UserRole.admin; // admin + super_admin
    }
  }

  factory SessionUser.fromJson(Map<String, dynamic> j) => SessionUser(
        id: asInt(j['id']),
        rawRole: asString(j['role']),
        name: asString(j['name']),
        mobile: asString(j['mobile']),
        customerCode: asStringOrNull(j['customer_code']),
        agentCode: asStringOrNull(j['agent_code']),
      );
}

/// What the server said after a correct mobile + PIN.
class LoginResult {
  final SessionUser user;

  /// true when an admin reset the PIN: the person must choose their own before using the app.
  final bool mustChangePin;
  const LoginResult(this.user, this.mustChangePin);
}

/// Holds who is signed in. The account's role (decided by the SERVER, never by the app)
/// drives which app - theme + screens - is shown.
class Session {
  Session._();

  /// null while signed out (splash / login / forgot PIN).
  static final ValueNotifier<UserRole?> role = ValueNotifier<UserRole?>(null);

  static SessionUser? user;

  /// Registered by each app's data store so a logout wipes everything that was loaded.
  static final List<VoidCallback> _clearers = [];
  static void onClear(VoidCallback fn) => _clearers.add(fn);

  /// POST /auth/login. On success the token is kept for later calls.
  /// Throws [ApiException] (wrong PIN, locked, inactive, no network ...).
  static Future<LoginResult> login(String mobile, String pin) async {
    final json = asMap(await ApiClient.instance.post('/auth/login', body: {'mobile': mobile, 'pin': pin}));
    final token = asString(json['token']);
    if (token.isEmpty) {
      throw const ApiException('Login failed. Please try again.');
    }
    ApiClient.instance.token = token;
    final u = SessionUser.fromJson(asMap(json['user']));
    user = u;
    return LoginResult(u, json['must_change_pin'] == true);
  }

  /// Marks the user as signed in to [r]'s app (after the app's data has loaded).
  static void enter(UserRole r) => role.value = r;

  /// Ends the session: revokes the token on the server (best effort), clears the token
  /// and forgets every piece of loaded data. Safe to call when already signed out.
  static Future<void> signOut() async {
    final hadToken = ApiClient.instance.token != null;
    if (hadToken) {
      try {
        await ApiClient.instance.post('/auth/logout');
      } catch (_) {
        // Offline or already expired - the local session is cleared either way.
      }
    }
    _reset();
  }

  /// Local-only reset (token already invalid, or no token to revoke).
  static void _reset() {
    ApiClient.instance.token = null;
    user = null;
    for (final fn in _clearers) {
      fn();
    }
    role.value = null;
  }

  static void forceReset() => _reset();
}
