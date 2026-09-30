import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/home/home_screen.dart';
import '../screens/chit/my_chit_screen.dart';
import '../screens/payments/payment_history_screen.dart';
import '../screens/payments/account_statement_screen.dart';
import '../screens/account/profile_screen.dart';
import '../state/app_state.dart';
import '../theme/app_text_styles.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    final hasChits = AppState.instance.hasChits;
    final pages = [
      hasChits ? HomeScreen(onNavigateTab: goTo) : const _NoChitView(),
      hasChits ? const MyChitScreen() : const _NoChitView(),
      hasChits ? const PaymentHistoryScreen() : const _NoChitView(),
      hasChits ? const AccountStatementScreen() : const _NoChitView(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', selected: _index == 0, onTap: () => goTo(0)),
              _NavItem(icon: Icons.description_rounded, label: 'My Chit', selected: _index == 1, onTap: () => goTo(1)),
              _NavItem(icon: Icons.receipt_long_rounded, label: 'Payments', selected: _index == 2, onTap: () => goTo(2)),
              _NavItem(icon: Icons.list_alt_rounded, label: 'Statement', selected: _index == 3, onTap: () => goTo(3)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: _index == 4, onTap: () => goTo(4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the signed-in customer has no active chit account yet.
class _NoChitView extends StatelessWidget {
  const _NoChitView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final err = await AppState.instance.refresh();
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 90),
            const Icon(Icons.description_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('No active chit yet', textAlign: TextAlign.center, style: AppText.title),
            const SizedBox(height: 8),
            const Text(
              'When Thandal gives you a loan, your chit account will appear here. Pull down to refresh.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
