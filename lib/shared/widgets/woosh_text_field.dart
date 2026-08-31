import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Reusable text field with label, icon, and error handling.
/// Replaces all the duplicated _InputField widgets across Login/Signup/OTP.
class WooshTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final bool autofocus;
  final TextAlign textAlign;
  final TextStyle? style;

  const WooshTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.onChanged,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          autofocus: autofocus,
          textAlign: textAlign,
          style: style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 15, color: AppColors.lightGray),
            prefixIcon: Icon(icon, color: AppColors.primaryPink, size: 22),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: AppColors.errorRed),
          ),
        ),
      ],
    );
  }
}
