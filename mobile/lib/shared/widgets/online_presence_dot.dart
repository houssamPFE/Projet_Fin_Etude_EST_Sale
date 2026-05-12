import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated pulsing dot that indicates a user is online.
/// The dot shows a solid green core with an expanding ring animation.
class OnlinePresenceDot extends StatefulWidget {
  final double size;
  final bool showBorder;

  const OnlinePresenceDot({
    super.key,
    this.size = 10,
    this.showBorder = true,
  });

  @override
  State<OnlinePresenceDot> createState() => _OnlinePresenceDotState();
}

class _OnlinePresenceDotState extends State<OnlinePresenceDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ring = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.size + 10.0;
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding ring
          AnimatedBuilder(
            animation: _ring,
            builder: (_, __) => Container(
              width: widget.size + _ring.value * 10,
              height: widget.size + _ring.value * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withAlpha(
                  (75 * (1 - _ring.value)).toInt(),
                ),
              ),
            ),
          ),
          // Solid core
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              border: widget.showBorder
                  ? Border.all(
                      color: AppColors.surface,
                      width: 1.5,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
