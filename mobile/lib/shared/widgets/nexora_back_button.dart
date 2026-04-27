import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Styled back button used on auth screens.
class NexoraBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const NexoraBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap ?? () => Navigator.maybePop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
