import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum SocialBrand { google, facebook }

/// Social login/signup button with gradient border and press animation.
class SocialAuthButton extends StatefulWidget {
  final SocialBrand brand;
  final String label;
  final VoidCallback onTap;

  const SocialAuthButton({
    super.key,
    required this.brand,
    required this.label,
    required this.onTap,
  });

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x406366F1), Color(0x201E2A42)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(1),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialIcon(brand: widget.brand),
                const SizedBox(width: 12),
                Text(widget.label, style: AppTextStyles.buttonMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final SocialBrand brand;
  const _SocialIcon({required this.brand});

  @override
  Widget build(BuildContext context) {
    if (brand == SocialBrand.google) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
              height: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
