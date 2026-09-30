import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class PinDotsField extends StatefulWidget {
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const PinDotsField({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<PinDotsField> createState() => _PinDotsFieldState();
}

class _PinDotsFieldState extends State<PinDotsField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.hasError ? AppColors.redBorder : AppColors.border,
                width: widget.hasError ? 1.4 : 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                final text = widget.controller.text;
                return Row(
                  children: List.generate(4, (i) {
                    final filled = i < text.length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: filled
                          ? Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.textMuted.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                    );
                  }),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                onChanged: widget.onChanged,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
