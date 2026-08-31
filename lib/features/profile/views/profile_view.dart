import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/di_providers.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';

/// Profile View
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/passenger/profile');
      setState(() {
        _profile = response.data['data'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryPink, AppColors.secondaryPurple],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 44),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: AppColors.primaryPink, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(user?.name?.isNotEmpty == true ? user!.name! : 'Woosh Passenger', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.female, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            const Text('Woosh Passenger', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: AppColors.primaryPink,
            leading: GestureDetector(
              onTap: () { if (context.canPop()) context.pop(); },
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final updated = await context.push<bool>('/profile/edit');
                  if (updated == true) {
                    _loadProfile();
                  }
                },
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                else ...[

                  // Info Section
                  _SectionCard(
                    title: 'Personal Info',
                    icon: Icons.person_outline,
                    children: [
                      _InfoTile(icon: Icons.phone, label: 'WhatsApp Number', value: user?.whatsappNumber?.isNotEmpty == true ? user!.whatsappNumber! : (user?.phoneNumber ?? '—')),
                      _InfoTile(icon: Icons.email_outlined, label: 'Email', value: _profile?['email']?.toString().isNotEmpty == true ? _profile!['email'].toString() : 'Not added'),
                      _InfoTile(icon: Icons.person_outline, label: 'Gender', value: _profile?['gender']?.toString().isNotEmpty == true ? _profile!['gender'].toString() : 'Not added'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Emergency Contacts
                  _SectionCard(
                    title: 'Emergency Contacts',
                    icon: Icons.emergency_outlined,
                    children: [
                      if ((_profile?['emergencyContacts'] as List?)?.isEmpty ?? true)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No emergency contacts added.', style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                        )
                      else
                        ...(_profile?['emergencyContacts'] as List? ?? []).map((c) {
                          return _InfoTile(icon: Icons.contact_phone_outlined, label: c['name']?.toString() ?? '', value: c['number']?.toString() ?? '');
                        }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Links
                  _SectionCard(
                    title: 'My Activity',
                    icon: Icons.dashboard_outlined,
                    children: [
                      _LinkTile(icon: Icons.history, label: 'Ride History', onTap: () => context.push('/history')),
                      _LinkTile(icon: Icons.account_balance_wallet_outlined, label: 'My Wallet', onTap: () => context.push('/wallet')),
                      _LinkTile(icon: Icons.child_care_outlined, label: 'Child Profiles', onTap: () => context.push('/children')),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Safety
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderPink),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppColors.primaryPink, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Verified Safe Passenger', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                              Text('Your account is verified and protected by Woosh Safety Shield.', style: TextStyle(fontSize: 12, color: AppColors.lightGray)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      context.go('/verification');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.errorRed),
                    label: const Text('Logout', style: TextStyle(color: AppColors.errorRed)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryPink, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.lightGray),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryPink),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.darkText))),
            const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 18),
          ],
        ),
      ),
    );
  }
}
