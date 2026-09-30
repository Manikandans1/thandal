import 'package:flutter_test/flutter_test.dart';

import 'package:thandal/core/auth/session.dart';

void main() {
  group('SessionUser.fromJson', () {
    test('maps the server role to the right app', () {
      expect(SessionUser.fromJson({'id': 1, 'role': 'customer', 'name': 'Ravi', 'mobile': '9876543210'}).role,
          UserRole.customer);
      expect(SessionUser.fromJson({'id': 2, 'role': 'agent', 'name': 'Karthik', 'mobile': '9841022017'}).role,
          UserRole.agent);
      expect(SessionUser.fromJson({'id': 3, 'role': 'admin', 'name': 'Admin', 'mobile': '9840000001'}).role,
          UserRole.admin);
      // super_admin also opens the admin app, but is flagged separately.
      final superAdmin =
          SessionUser.fromJson({'id': 4, 'role': 'super_admin', 'name': 'Owner', 'mobile': '9000000000'});
      expect(superAdmin.role, UserRole.admin);
      expect(superAdmin.isSuperAdmin, isTrue);
    });

    test('carries the customer / agent code when the server sends one', () {
      final customer = SessionUser.fromJson({
        'id': 1,
        'role': 'customer',
        'name': 'Ravi',
        'mobile': '9876543210',
        'customer_code': 'THD-10001',
      });
      expect(customer.customerCode, 'THD-10001');
      expect(customer.agentCode, isNull);
    });
  });

  group('Session', () {
    test('starts signed out, with no role and no user', () {
      expect(Session.role.value, isNull);
      expect(Session.user, isNull);
    });
  });
}
