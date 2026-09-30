// The three apps share ONE login screen (lib/core/auth/login_screen.dart).
// This file only re-exports it so the existing "back to login" / logout /
// set-new-PIN navigation inside this app keeps working unchanged.
export '../../../../core/auth/login_screen.dart';
