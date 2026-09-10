import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Bottom navigation bar — Home, My Rides, Safety, Profile
class WooshBottomNav extends StatelessWidget {
  final int currentIndex;

  const WooshBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_filled, label: 'Home', isActive: currentIndex == 0,
                onTap: () { if (currentIndex != 0) context.go('/home'); }),
              _NavItem(icon: Icons.access_time, label: 'My Rides', isActive: currentIndex == 1,
                onTap: () { if (currentIndex != 1) context.push('/ride-history'); }),
              _NavItem(icon: Icons.shield_outlined, label: 'Safety', isActive: currentIndex == 2,
                onTap: () { if (currentIndex != 2) context.push('/safety'); }),
              _NavItem(icon: Icons.person_outline, label: 'Profile', isActive: currentIndex == 3,
                onTap: () { if (currentIndex != 3) context.push('/profile'); }),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryPink : AppColors.lightGray;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
