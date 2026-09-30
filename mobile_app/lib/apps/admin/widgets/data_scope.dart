import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Rebuilds its child whenever the admin data changes (after a refresh or an action),
/// so every open screen shows the latest server data without each screen wiring it up.
class DataScope extends StatelessWidget {
  final WidgetBuilder builder;
  const DataScope({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: MockData.instance,
        builder: (context, _) => builder(context),
      );
}
