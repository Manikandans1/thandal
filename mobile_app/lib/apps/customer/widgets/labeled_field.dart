import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class MobileNumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const MobileNumberField({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? AppColors.redBorder : AppColors.border,
          width: hasError ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Text('+91', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          Container(width: 1, height: 22, color: AppColors.border),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '98765 43210',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FieldErrorText extends StatelessWidget {
  final String text;
  const FieldErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: const TextStyle(color: AppColors.redText, fontSize: 12.5)),
    );
  }
}
