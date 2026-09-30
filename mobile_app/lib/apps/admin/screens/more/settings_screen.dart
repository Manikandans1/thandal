import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockData.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Company and support',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                KeyValueRow('Company', data.companyName),
                KeyValueRow('Support phone', data.supportPhone),
                KeyValueRow('Office hours', data.officeHours),
                const KeyValueRow('Receipt prefix', 'THD-RCP'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Security',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              children: [
                KeyValueRow('Login', 'Mobile number + PIN'),
                KeyValueRow('PIN length', '4 digits'),
                KeyValueRow('Wrong PIN attempts', '3, then locked 15 min'),
                KeyValueRow('PIN storage', 'Secure hash only'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Payments',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              children: [
                KeyValueRow('Razorpay mode', 'Test'),
                KeyValueRow('Webhook', 'Receiving'),
                KeyValueRow('Repeat callbacks', 'Ignored'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('More settings are available on the web panel.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
