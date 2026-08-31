import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable gradient CTA button.
/// Replaces _LoginButton, _SubmitButton, _VerifyButton.
class WooshGradientButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final IconData? trailingIcon;

  const WooshGradientButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
    this.gradient,
    this.trailingIcon = Icons.arrow_forward_ios,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.verifyButtonGradient;
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: isEnabled ? effectiveGradient : null,
        color: isEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(18),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, color: Colors.white, size: 16),
                  ],
                ],
              ),
      ),
    );
  }
}
