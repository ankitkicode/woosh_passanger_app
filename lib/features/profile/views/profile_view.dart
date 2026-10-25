import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF1E1E1E),
          ),
        ),
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
      ),
      body: state.isLoading && state.data == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          : state.error != null && state.data == null
          ? Center(child: Text('Error: ${state.error}'))
          : _buildProfileContent(context, ref, state.data),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? data,
  ) {
    final user = data ?? {};
    final name = user['name']?.isNotEmpty == true ? user['name'] : 'Your name';
    final phone = user['phoneNumber']?.isNotEmpty == true
        ? user['phoneNumber']
        : '+91 98765 4XXXX';
    final rating = user['rating']?.toString() ?? '0.0';
    final ridesCount = user['totalRides']?.toString() ?? '0';
    final walletBalance = user['walletBalance']?.toString() ?? '0';
    final referReward = user['referReward']?.toString() ?? '0';
    final emergencyContacts = user['emergencyContacts'] as List?;
    final emergencyContactsCount = emergencyContacts?.length.toString() ?? '0';
    final profileImage = user['profileImage'] as String?;

    final String initial = name.isNotEmpty && name != 'Your name'
        ? name[0].toUpperCase()
        : '';

    String? getFullImageUrl(String? path) {
      if (path == null || path.isEmpty) return null;
      if (path.startsWith('http')) return path;
      final baseUrl = AppConfig.imageBaseUrl.endsWith('/')
          ? AppConfig.imageBaseUrl.substring(0, AppConfig.imageBaseUrl.length - 1)
          : AppConfig.imageBaseUrl;
      final imagePath = path.startsWith('/') ? path : '/$path';
      return '$baseUrl$imagePath';
    }

    final String? fullImageUrl = getFullImageUrl(profileImage);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF14264),
                        width: 2,
                      ),
                      color: const Color(0xFFFFF0F3),
                    ),
                    alignment: Alignment.center,
                    child: (fullImageUrl != null)
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: fullImageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFD40B7E)),
                              errorWidget: (context, url, error) => Text(
                                initial,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD40B7E),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            initial,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD40B7E),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF00A651),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Edit profile',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD40B7E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
                ],
              ),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ridesCount,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rides',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF1E1E1E),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your rating',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '₹$walletBalance',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Wallet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Items Group 1
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.account_balance_wallet_outlined,
                  'Payments & wallet',
                  () {
                    context.push('/wallet');
                  },
                ),
                const Divider(
                  height: 1,
                  color: Color(0xFFEEEEEE),
                  indent: 16,
                  endIndent: 16,
                ),
                _buildMenuItem(Icons.location_on_outlined, 'Saved places', () {
                  context.push('/saved-places');
                }),
                const Divider(
                  height: 1,
                  color: Color(0xFFEEEEEE),
                  indent: 16,
                  endIndent: 16,
                ),
                _buildMenuItem(Icons.people_outline, 'Emergency contacts', () {
                  context.push('/emergency-contacts');
                }, trailingText: emergencyContactsCount),
                const Divider(
                  height: 1,
                  color: Color(0xFFEEEEEE),
                  indent: 16,
                  endIndent: 16,
                ),
                _buildMenuItem(
                  Icons.card_giftcard,
                  'Refer a friend',
                  () {},
                  isPromo: true,
                  promoText: 'Earn ₹$referReward',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Items Group 2
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildMenuItem(Icons.light_mode_outlined, 'Settings', () {
                  context.push('/settings');
                }),
                const Divider(
                  height: 1,
                  color: Color(0xFFEEEEEE),
                  indent: 16,
                  endIndent: 16,
                ),
                _buildMenuItem(Icons.help_outline, 'Help & support', () {
                  context.push('/help-support');
                }),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout
          TextButton(
            onPressed: () => _logout(context, ref),
            child: const Text(
              'Log out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD40B7E),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? trailingText,
    bool isPromo = false,
    String? promoText,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD40B7E), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF757575),
                ),
              ),
            if (isPromo && promoText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promoText,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD), size: 20),
          ],
        ),
      ),
    );
  }
}
