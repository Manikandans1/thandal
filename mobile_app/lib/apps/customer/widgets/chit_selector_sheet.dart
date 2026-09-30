import 'package:flutter/material.dart';
import '../models/chit.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

Future<String?> showChitSelectorSheet(
  BuildContext context, {
  required List<Chit> chits,
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Chits', style: AppText.h2),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...chits.map((c) => _ChitTile(
                    chit: c,
                    selected: c.id == selectedId,
                    onTap: () => Navigator.of(context).pop(c.id),
                  )),
            ],
          ),
        ),
      );
    },
  );
}

class _ChitTile extends StatelessWidget {
  final Chit chit;
  final bool selected;
  final VoidCallback onTap;

  const _ChitTile({required this.chit, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chit.id, style: AppText.bodyBold),
                    const SizedBox(height: 3),
                    Text(
                      'Loan ${Formatters.rupees(chit.loanAmount)} \u00b7 ${Formatters.rupees(chit.installmentAmount)} ${chit.cadenceLabel}',
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 3),
                    Text('Outstanding ${Formatters.rupees(chit.outstanding)}', style: AppText.bodyBold),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                child: const Text('Active', style: TextStyle(color: AppColors.successText, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
