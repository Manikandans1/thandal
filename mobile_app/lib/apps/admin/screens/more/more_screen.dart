import 'package:flutter/material.dart';
import '../../../../core/auth/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../agents/agents_screen.dart';
import '../auth/login_screen.dart';
import 'reports_screen.dart';
import 'audit_logs_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuTile(context, Icons.badge_outlined, 'Agents',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgentsScreen()))),
          _menuTile(context, Icons.insert_chart_outlined, 'Reports',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          _menuTile(context, Icons.receipt_long_outlined, 'Audit logs',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditLogsScreen()))),
          _menuTile(context, Icons.settings_outlined, 'Settings',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const SizedBox(height: 24),
          Builder(builder: (context) {
            final u = Session.user;
            final name = (u?.name.isNotEmpty ?? false) ? u!.name : 'Admin';
            final initials = name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase();
            return AppCard(
              child: Row(
                children: [
                  InitialsAvatar(initials.isEmpty ? 'A' : initials, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        Text(u?.mobile ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          DangerButton(
            label: '⏻  Log out',
            onPressed: () async {
              final ok = await showConfirmSheet(
                context,
                title: 'Log out of Thandal?',
                message: "You'll need your mobile number and PIN to log in again.",
                confirmLabel: 'Log out',
                danger: true,
              );
              if (ok && context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Thandal · Admin · Version 1.0 (prototype)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.textSecondary),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
