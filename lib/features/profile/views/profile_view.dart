import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../view_models/profile_view_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/di_providers.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(authRepositoryProvider).logout();
    ref.read(authStateProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.darkText),
            onPressed: () {},
          ),
        ],
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : state.error != null && state.data == null
              ? Center(child: Text('Error: ${state.error}'))
              : _buildProfileContent(context, ref, state.data),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, Map<String, dynamic>? data) {
    final user = data ?? {};
    final name = user['name']?.isNotEmpty == true ? user['name'] : 'Passenger Name';
    final phone = user['phoneNumber']?.isNotEmpty == true ? user['phoneNumber'] : 'Phone Number';
    final rating = '5.0'; // Passenger rating not implemented in MVP

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, size: 40, color: AppColors.primaryPink),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                const SizedBox(height: 4),
                Text(phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.lightGray)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Items
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Column(
              children: [
                _buildMenuItem(Icons.edit_outlined, 'Edit Profile', () {}),
                const Divider(height: 1, color: AppColors.dividerColor),
                _buildMenuItem(Icons.history, 'Ride History', () {
                  context.push('/ride-history');
                }),
                const Divider(height: 1, color: AppColors.dividerColor),
                _buildMenuItem(Icons.contact_phone_outlined, 'Emergency Contacts', () {}),
                const Divider(height: 1, color: AppColors.dividerColor),
                _buildMenuItem(Icons.support_agent_outlined, 'Help & Support', () {}),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.errorRed),
              label: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', color: AppColors.errorRed, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkText),
      title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.darkText)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
      onTap: onTap,
    );
  }
}
