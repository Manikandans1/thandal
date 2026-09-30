import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import 'set_new_pin_screen.dart';

class ForgotPinScreen extends StatelessWidget {
  const ForgotPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  children: [
                    KeyValueRow(label: 'Customers: office', value: '+91 44 5555 0142', bold: true),
                    const DashedDivider(),
                    KeyValueRow(label: 'Agents: your admin', value: '+91 44 5555 0142', bold: true),
                    const DashedDivider(),
                    KeyValueRow(label: 'Hours', value: 'Mon–Sat, 9:30 am – 6 pm', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How it works',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),
                    _StepRow(number: '1', text: 'Call and tell them your mobile number.'),
                    _StepRow(number: '2', text: 'They confirm it is you.'),
                    _StepRow(number: '3', text: 'They give you a temporary PIN.'),
                    _StepRow(number: '4', text: 'You set your own new PIN in the app.', last: true),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppPrimaryButton(
                label: 'Call Thandal',
                icon: Icons.call_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Thandal support…')),
                  );
                },
              ),
              const SizedBox(height: 10),
              AppOutlineButton(
                label: 'I have a temporary PIN',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SetNewPinScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  final bool last;
  const _StepRow({required this.number, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(number,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
