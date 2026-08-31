import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Branded AppBar with Woosh logo and "Be Safe, Be Fearless" motto.
/// Used across Login, Signup, OTP screens.
class WooshAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const WooshAppBar({super.key, this.onBack, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          Image.asset('assets/woosh_logo.png', height: 30),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 10, color: Colors.black),
              children: [
                TextSpan(text: 'Be Safe, '),
                TextSpan(
                  text: 'Be Fearless',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: onBack,
            )
          : null,
      actions: actions,
    );
  }
}
