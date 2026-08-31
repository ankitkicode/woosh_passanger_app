import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color lightGray = Color(0xFF757575);
  static const Color lightPink = Color(0xFFFFF0F5);
  static const Color borderPink = Color(0xFFFFC0CB);
  static const Color shadowPink = Color(0x20E91E63);
  static const Color inputBackground = Color(0xFFF9F9F9);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color pickupPurple = Color(0xFF9C27B0);
  static const Color dropPink = Color(0xFFE91E63);
  static const Color surfaceGray = Color(0xFFF5F5F5);
  static const Color cardShadow = Color(0x1A000000);
  static const Color dividerColor = Color(0xFFEEEEEE);
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFE0F0),
      Colors.white,
    ],
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
    ],
  );

  static const LinearGradient verifyButtonGradient = LinearGradient(
    colors: [
      Color(0xFFD81B60),
      Color(0xFFFF7043),
    ],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF5F8),
      Colors.white,
    ],
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [
      Color(0xFF9C27B0),
      Color(0xFFE91E63),
      Color(0xFFE0E0E0),
    ],
    stops: [0.0, 0.5, 0.5],
  );
}
