import 'package:flutter/widgets.dart';

/// Lets non-widget code (e.g. "your session expired") move the app back to the login screen.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
