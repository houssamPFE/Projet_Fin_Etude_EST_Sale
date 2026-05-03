import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';

/// Gradient CTA button with press-scale animation and optional loading state.
class NexoraGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final double height;

  const NexoraGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 54,
  });

  @override
  State<NexoraGradientButton> createState() => _NexoraGradientButtonState();
}

class _NexoraGradientButtonState extends State<NexoraGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.isLoading ? null : AppGradients.button,
            color: widget.isLoading ? AppColors.surfaceElevated : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading || _pressed
                ? []
                : [
                    const BoxShadow(
                      color: Color(0x706366F1),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: Offset(0, 12),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(widget.label, style: AppTextStyles.buttonLarge),
          ),
        ),
      ),
    );
  }
}
