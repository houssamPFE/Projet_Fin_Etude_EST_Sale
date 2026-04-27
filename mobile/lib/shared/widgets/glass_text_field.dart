import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Glassmorphic text input with focus glow animation.
class GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.keyboardType,
    required this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = false,
    this.validator,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _focused
            ? [
                const BoxShadow(
                  color: Color(0x506366F1),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        autocorrect: widget.autocorrect,
        style: AppTextStyles.input,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.prefixIcon),
          fillColor: _focused
              ? const Color(0x1A6366F1)
              : const Color(0x0F6366F1),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      ),
    );
  }
}
