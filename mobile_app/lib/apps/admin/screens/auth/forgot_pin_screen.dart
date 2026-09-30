import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'set_pin_screen.dart';

class ForgotPinScreen extends StatelessWidget {
  const ForgotPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockData.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PINs are reset by Thandal so your account stays safe.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  children: [
                    KeyValueRow("Customers' office", data.supportPhone),
                    const Divider(height: 20),
                    const KeyValueRow('Agents: your admin', '+91 44 5555 0142'),
                    const Divider(height: 20),
                    KeyValueRow('Hours', data.officeHours),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('How it works',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              const _HowStep(number: '1', text: 'Call and tell them your mobile number.'),
              const _HowStep(number: '2', text: 'They confirm it is you.'),
              const _HowStep(number: '3', text: 'They give you a temporary PIN.'),
              const _HowStep(number: '4', text: 'You set your own new PIN in the app.'),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Call Thandal',
                icon: Icons.call,
                onPressed: () => showAppSnackBar(context, '${data.supportPhone} · tap to copy or dial from your phone app'),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'I have a temporary PIN',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SetPinScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String text;
  const _HowStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
