import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular avatar with initials, used for customers and agent.
class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? bg;
  final Color? fg;

  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 44,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? AppColors.avatarBg,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: fg ?? AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Small pill badge used for status labels (Overdue / Due / Active ...).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
    this.fontSize = 12.5,
  });

  factory StatusBadge.forStatus(String status) {
    switch (status) {
      case 'Overdue':
        return StatusBadge(label: status, fg: AppColors.overdue, bg: AppColors.overdueBg);
      case 'Due':
        return StatusBadge(label: status, fg: AppColors.due, bg: AppColors.dueBg);
      case 'Collected':
      case 'Confirmed':
      case 'Active':
      case 'approved':
      case 'Correction: approved':
        return StatusBadge(
          label: status,
          fg: AppColors.success,
          bg: AppColors.successBg,
        );
      case 'Closed':
        return const StatusBadge(
          label: 'Closed',
          fg: AppColors.textSecondary,
          bg: AppColors.divider,
        );
      case 'Pending':
        return StatusBadge(label: status, fg: AppColors.due, bg: AppColors.dueBg);
      case 'pending':
      case 'Correction: pending':
        return StatusBadge(label: status, fg: AppColors.info, bg: AppColors.infoBg);
      default:
        return StatusBadge(label: status, fg: AppColors.textSecondary, bg: AppColors.divider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// A bordered card container used throughout the app.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: card,
    );
  }
}

/// A row with a label on the left and a value on the right — used a lot
/// on detail screens ("Mobile", "Address", "Loan amount" ...).
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic empty-state placeholder (no customers / no results / ...).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.softGreenBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin section title with an optional trailing action ("See all").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
      ],
    );
  }
}

/// Rounded labelled text field used across forms.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget field;
  final bool required;

  const LabeledField({
    super.key,
    required this.label,
    required this.field,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            children: [
              if (required)
                const TextSpan(
                    text: ' *', style: TextStyle(color: AppColors.overdue)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider);
  }
}
