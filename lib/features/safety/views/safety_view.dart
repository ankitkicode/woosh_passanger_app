import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/woosh_bottom_nav.dart';

class SafetyView extends StatelessWidget {
  const SafetyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: const Text('Safety & Security', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your safety is our priority', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 24),
            
            // Emergency Contacts
            _buildSafetyCard(
              context,
              icon: Icons.contact_phone_outlined,
              title: 'Emergency Contacts',
              subtitle: 'Add up to 5 contacts to notify during emergencies.',
              onTap: () {
                // Navigate to emergency contacts setup
              },
            ),
            
            const SizedBox(height: 16),
            
            // SOS Button Demo/Info
            _buildSafetyCard(
              context,
              icon: Icons.sos,
              iconColor: AppColors.errorRed,
              title: 'SOS Emergency',
              subtitle: 'In an active ride, press SOS to immediately share your live location and alert our 24/7 safety team.',
              onTap: () {
                // Info dialog or test SOS
              },
            ),
            
            const SizedBox(height: 16),
            
            // Ride Sharing Preferences
            _buildSafetyCard(
              context,
              icon: Icons.share_location_outlined,
              title: 'Share Live Trip',
              subtitle: 'Configure automatic sharing of your ride status with trusted contacts.',
              onTap: () {
                // Navigate to share settings
              },
            ),
            
            const SizedBox(height: 16),
            
            // Support
            _buildSafetyCard(
              context,
              icon: Icons.support_agent_outlined,
              title: '24/7 Support Helpline',
              subtitle: 'Get instant help from our safety response team.',
              onTap: () {
                // Call support
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const WooshBottomNav(currentIndex: 2),
    );
  }

  Widget _buildSafetyCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color iconColor = AppColors.primaryPink}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.darkText)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.lightGray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lightGray),
          ],
        ),
      ),
    );
  }
}
