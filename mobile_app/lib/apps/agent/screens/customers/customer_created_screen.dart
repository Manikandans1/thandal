import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';
import 'new_chit_screen.dart';

class CustomerCreatedScreen extends StatelessWidget {
  final Customer customer;

  /// The temporary login PIN from the server, shown only here, only once.
  final String pin;
  const CustomerCreatedScreen({super.key, required this.customer, this.pin = ''});

  String get _pin => pin.split('').join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 42),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Customer created',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(customer.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 26),
              const Text('One-time login PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(_pin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 8)),
              const SizedBox(height: 14),
              const Text(
                "Share this PIN with the customer. It won't be shown again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Create a chit for them',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => NewChitScreen(customer: customer)),
                ),
              ),
              const SizedBox(height: 12),
              AppOutlineButton(
                label: 'Done',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
