import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

PreferredSizeWidget backAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Text(title,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
    actions: actions,
  );
}

/// Fake status bar shown at the very top of prototype-style screens
/// (mirrors the "10:42" time + signal/battery icons in the design).
class FakeStatusBar extends StatelessWidget {
  const FakeStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
