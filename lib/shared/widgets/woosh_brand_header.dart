import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Woosh branded header — matches mockup exactly.
/// Shows: back arrow (optional) | Woosh logo + tagline | shield icon
class WooshBrandHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBack;

  const WooshBrandHeader({super.key, this.onBack, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back / Hamburger
            if (showBack)
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.darkText),
                ),
              )
            else
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.menu, color: AppColors.darkText, size: 24),
              ),

            const Spacer(),

            // Woosh Logo
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ).createShader(r),
                  child: const Text(
                    'Woosh',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11, color: AppColors.lightGray),
                    children: [
                      TextSpan(text: 'Be Safe, '),
                      TextSpan(
                        text: 'Be Fearless',
                        style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Safety Shield
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.lightPink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderPink, width: 1.5),
              ),
              child: const Icon(Icons.verified_user_outlined, color: AppColors.primaryPink, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
