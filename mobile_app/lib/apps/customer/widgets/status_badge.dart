import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeTone { green, amber, red, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final bool dot;

  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.green,
    this.dot = false,
  });

  _Palette get _palette {
    switch (tone) {
      case BadgeTone.green:
        return _Palette(AppColors.successBg, AppColors.successText);
      case BadgeTone.amber:
        return _Palette(AppColors.amberBg, AppColors.amberText);
      case BadgeTone.red:
        return _Palette(AppColors.redBg, AppColors.redText);
      case BadgeTone.neutral:
        return _Palette(AppColors.chipBg, AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: p.fg, shape: BoxShape.circle),
            ),
          ],
          Text(
            label,
            style: TextStyle(color: p.fg, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Palette {
  final Color bg;
  final Color fg;
  _Palette(this.bg, this.fg);
}
