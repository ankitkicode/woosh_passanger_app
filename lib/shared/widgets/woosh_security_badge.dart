import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// "Secure & Private Authentication" badge shown on auth screens.
class WooshSecurityBadge extends StatelessWidget {
  final String text;

  const WooshSecurityBadge({
    super.key,
    this.text = 'Secure & Private Authentication',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 14, color: AppColors.pickupPurple),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.pickupPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Privacy notice card shown on auth forms.
class WooshPrivacyNotice extends StatelessWidget {
  final String title;
  final String subtitle;

  const WooshPrivacyNotice({
    super.key,
    this.title = 'Your safety and privacy are our priority.',
    this.subtitle = 'We never share your personal details with anyone.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
