import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/top_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faqs = [
    ('My payment is not showing',
        "Online payments can take a few minutes to confirm. If it still doesn't show after 30 minutes, call the office with your reference number."),
    ('How is my payment applied?',
        'Thandal always applies payments to the oldest unpaid installment first, including any overdue amount, before moving to future installments.'),
    ('How do I close my chit early?',
        "Open My Chit and tap 'Pay early and close this chit' to see your full outstanding amount and pay it in one go."),
    ('What if I miss an installment?',
        "It shows as overdue on your Home screen and schedule. Pay it along with today's due as soon as you can to avoid it stacking up."),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: backAppBar(context, 'Support'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Call the office', style: AppText.label),
                  const SizedBox(height: 4),
                  const Text('+91 44 5555 0142', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Mon\u2013Sat, 9:30 am \u2013 6 pm', style: AppText.caption),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Call now',
                    icon: Icons.call,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling +91 44 5555 0142\u2026')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Common questions', style: AppText.bodyBold),
            const SizedBox(height: 8),
            ..._faqs.map((f) => _FaqTile(question: f.$1, answer: f.$2)),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(question, style: AppText.bodyBold),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(answer, style: AppText.body)],
        ),
      ),
    );
  }
}
