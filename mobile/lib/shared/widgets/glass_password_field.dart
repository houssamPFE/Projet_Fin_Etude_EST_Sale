import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Glassmorphic password input with show/hide toggle and focus glow.
class GlassPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool visible;
  final VoidCallback onToggle;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  const GlassPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.visible,
    required this.onToggle,
    required this.textInputAction,
    this.validator,
  });

  @override
  State<GlassPasswordField> createState() => _GlassPasswordFieldState();
}

class _GlassPasswordFieldState extends State<GlassPasswordField> {
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
                  color: Color(0x706366F1),
                  blurRadius: 28,
                  spreadRadius: -3,
                ),
                const BoxShadow(
                  color: Color(0x306366F1),
                  blurRadius: 48,
                  spreadRadius: -8,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: !widget.visible,
        textInputAction: widget.textInputAction,
        style: AppTextStyles.input,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            onPressed: widget.onToggle,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                key: ValueKey(widget.visible),
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          fillColor: _focused
              ? const Color(0x256366F1)
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
