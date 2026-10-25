import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/woosh_bottom_nav.dart';
import '../../../providers/di_providers.dart';

class SafetyView extends ConsumerStatefulWidget {
  const SafetyView({super.key});

  @override
  ConsumerState<SafetyView> createState() => _SafetyViewState();
}

class _SafetyViewState extends ConsumerState<SafetyView> {
  bool autoShare = true;
  bool rideCheck = true;
  bool nightRide = true;
  bool recordAudio = false;
  bool _isLoadingSos = false;

  void _triggerSos() async {
    if (_isLoadingSos) return;
    setState(() => _isLoadingSos = true);
    
    try {
      final repo = ref.read(safetyRepositoryProvider);
      // Assuming no specific ride ID for now
      await repo.triggerSos(rideId: null);
      
      if (mounted) {
        context.push('/sos-active');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Everything that keeps you protected, in one place.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: AppColors.lightGray,
                ),
              ),
              const SizedBox(height: 24),

              // Emergency SOS Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency SOS',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Alerts our safety team, your contacts and shares live location.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Circular Button
                    GestureDetector(
                      onLongPress: _triggerSos,
                      onTap: _triggerSos, // Allowing tap as well for easier testing
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: _isLoadingSos 
                              ? const CircularProgressIndicator(color: Color(0xFFD81B60))
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'SOS',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                        color: Color(0xFFD81B60),
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'HOLD 3s',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Emergency contacts
              GestureDetector(
                onTap: () => context.push('/emergency-contacts'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Avatars Stack
                      SizedBox(
                        width: 65,
                        height: 44,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 20,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFCE4EC),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'N',
                                  style: TextStyle(
                                    color: Color(0xFFC2185B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFF3E0),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'M',
                                  style: TextStyle(
                                    color: Color(0xFFE65100),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency contacts',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.darkText,
                              ),
                            ),
                            Text(
                              '2 of 5 added · Mom, [Name]',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.lightGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.lightGray,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Switches Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Auto-share every ride',
                      subtitle: 'Contacts get a live link when a ride starts',
                      value: autoShare,
                      onChanged: (v) => setState(() => autoShare = v),
                    ),
                    _buildSwitchTile(
                      title: 'Ride check',
                      subtitle: 'We check in on long stops or route changes',
                      value: rideCheck,
                      onChanged: (v) => setState(() => rideCheck = v),
                    ),
                    _buildSwitchTile(
                      title: 'Night ride protection',
                      subtitle: 'Extra check-ins from 9 pm to 6 am',
                      value: nightRide,
                      onChanged: (v) => setState(() => nightRide = v),
                    ),
                    _buildSwitchTile(
                      title: 'Record audio on SOS',
                      subtitle: 'Saved securely, only shared if you report',
                      value: recordAudio,
                      onChanged: (v) => setState(() => recordAudio = v),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Helplines Row
              Row(
                children: [
                  Expanded(
                    child: _buildHelplineCard(
                      iconColor: const Color(0xFFD32F2F),
                      backgroundColor: const Color(0xFFFFEBEE),
                      number: '112',
                      label: 'Emergency',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildHelplineCard(
                      iconColor: const Color(0xFF9C27B0),
                      backgroundColor: const Color(0xFFF3E5F5),
                      number: '181',
                      label: 'Women helpline',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const WooshBottomNav(currentIndex: 2),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.lightGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.95,
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.dividerColor),
      ],
    );
  }

  Widget _buildHelplineCard({
    required Color iconColor,
    required Color backgroundColor,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_in_talk_outlined,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.darkText,
                    height: 1.2,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
