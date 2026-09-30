import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/outline_button.dart';
import '../../widgets/section_card.dart';
import 'set_new_pin_screen.dart';

class ForgotPinScreen extends StatelessWidget {
  const ForgotPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Forgot PIN', style: AppText.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PINs are reset by Thandal so your account stays safe.',
                style: AppText.body,
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  children: const [
                    InfoRow(label: 'Customers: office', value: '+91 44 5555 0142'),
                    SectionDivider(),
                    InfoRow(label: 'Agents: your admin', value: '+91 44 5555 0142'),
                    SectionDivider(),
                    InfoRow(label: 'Hours', value: 'Mon\u2013Sat, 9:30 am \u2013 6 pm'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('How it works', style: AppText.bodyBold),
                    SizedBox(height: 12),
                    _Step(number: '1', text: 'Call and tell them your mobile number.'),
                    SizedBox(height: 10),
                    _Step(number: '2', text: 'They confirm it is you.'),
                    SizedBox(height: 10),
                    _Step(number: '3', text: 'They give you a temporary PIN.'),
                    SizedBox(height: 10),
                    _Step(number: '4', text: 'You set your own new PIN in the app.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Call Thandal',
                icon: Icons.call,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling +91 44 5555 0142\u2026')),
                ),
              ),
              const SizedBox(height: 10),
              AppOutlineButton(
                label: 'I have a temporary PIN',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SetNewPinScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Text(number, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppText.body)),
      ],
    );
  }
}
