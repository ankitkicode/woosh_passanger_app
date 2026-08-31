import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../ride/view_models/ride_view_model.dart';

/// Ride Complete View — trip summary + star rating
class RideCompleteView extends ConsumerStatefulWidget {
  final String rideId;
  const RideCompleteView({super.key, required this.rideId});

  @override
  ConsumerState<RideCompleteView> createState() => _RideCompleteViewState();
}

class _RideCompleteViewState extends ConsumerState<RideCompleteView> {
  int _selectedRating = 0;
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final ride = state.activeRide;
    final rider = ride?.rider;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Success animation
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  boxShadow: [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 4)],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 52),
              ),

              const SizedBox(height: 20),
              const Text('Ride Completed!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkText)),
              const Text('You reached your destination safely.', style: TextStyle(fontSize: 14, color: AppColors.lightGray)),

              const SizedBox(height: 32),

              // Fare Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 16)],
                ),
                child: Column(
                  children: [
                    const Text('Total Fare', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${ride?.fare.toStringAsFixed(0) ?? '—'}',
                      style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ride?.paymentMethod == 'cash' ? '💵 Paid by Cash' : '👛 Paid by Wallet',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Trip Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.circle, color: AppColors.secondaryPurple, label: 'From', value: state.pickup?.address ?? '—'),
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.location_on, color: AppColors.primaryPink, label: 'To', value: state.drop?.address ?? '—'),
                    const Divider(height: 20),
                    Row(
                      children: [
                        _StatChip(icon: Icons.straighten, label: '${ride?.distanceKm.toStringAsFixed(1) ?? '—'} km'),
                        const SizedBox(width: 10),
                        _StatChip(icon: Icons.timer_outlined, label: '${ride?.durationMinutes ?? '—'} mins'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Rate your rider
              if (!_rated) ...[
                const Text('Rate Your Rider', style: AppTextStyles.actionTitle),
                const SizedBox(height: 4),
                Text(
                  'How was your experience with ${rider?.name ?? 'your rider'}?',
                  style: const TextStyle(fontSize: 13, color: AppColors.lightGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Rider info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightPink,
                        border: Border.all(color: AppColors.primaryPink, width: 2),
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryPink),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider?.name ?? 'Your Rider', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text('${rider?.rating ?? 4.5}', style: const TextStyle(fontSize: 12, color: AppColors.lightGray)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                WooshGradientButton(
                  text: 'Submit Rating',
                  isLoading: state.isLoading,
                  onPressed: _selectedRating > 0
                      ? () async {
                          final success = await ref.read(rideViewModelProvider.notifier).rateRide(widget.rideId, _selectedRating);
                          if (success) setState(() => _rated = true);
                        }
                      : null,
                ),
              ] else ...[
                // Post-rating state
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.lightPink, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: AppColors.primaryPink),
                      SizedBox(width: 8),
                      Text('Thank you for your feedback!', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                WooshGradientButton(
                  text: 'Book Another Ride',
                  onPressed: () {
                    ref.read(rideViewModelProvider.notifier).clearRide();
                    context.go('/home');
                  },
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText)),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryPink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
