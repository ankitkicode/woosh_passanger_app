import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../ride/view_models/ride_view_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'invoice_bottom_sheet.dart';

class RideCompleteView extends ConsumerStatefulWidget {
  final String rideId;
  const RideCompleteView({super.key, required this.rideId});

  @override
  ConsumerState<RideCompleteView> createState() => _RideCompleteViewState();
}

class _RideCompleteViewState extends ConsumerState<RideCompleteView> {
  int _selectedRating = 0;
  String? _selectedTip;
  final List<String> _selectedCompliments = [];
  bool _rated = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final success = await ref
        .read(rideViewModelProvider.notifier)
        .verifyPayment(
          widget.rideId,
          response.orderId ?? '',
          response.paymentId ?? '',
          response.signature ?? '',
        );
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}'),
        ),
      );
    }
  }

  void _toggleCompliment(String compliment) {
    setState(() {
      if (_selectedCompliments.contains(compliment)) {
        _selectedCompliments.remove(compliment);
      } else {
        _selectedCompliments.add(compliment);
      }
    });
  }

  void _toggleTip(String tip) {
    setState(() {
      if (_selectedTip == tip) {
        _selectedTip = null;
      } else {
        _selectedTip = tip;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final ride = state.activeRide;
    final rider = ride?.rider;

    // We can assume fare is ride?.fare, payment method etc.
    final double fare = ride?.fare ?? 0.0;
    final String paymentStatus = ride?.paymentStatus ?? 'pending';
    final String paymentMethod = ride?.paymentMethod ?? 'UPI'; // Assuming we default to UPI if online
    final double distanceKm = ride?.distanceKm ?? 0.0;
    final int durationMin = ride?.durationMinutes ?? 0;
    final String riderName = rider?.name ?? 'your rider';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient Curve
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: ClipPath(
              clipper: _CurveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.backgroundGradient, // light pink to white
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Invoice Button at top right
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        showInvoiceBottomSheet(context, ref, widget.rideId);
                      },
                      icon: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primaryPink,
                        size: 18,
                      ),
                      label: const Text(
                        'Invoice',
                        style: TextStyle(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Success Checkmark Circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.verifyButtonGradient, // pink to orange
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // "You've arrived safely"
                  const Text(
                    "You've arrived safely",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Fare & Trip Details
                  Text(
                    '₹${fare.toStringAsFixed(0)} paid via $paymentMethod • ${distanceKm.toStringAsFixed(1)} km • $durationMin min',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightGray,
                    ),
                  ),

                  // Handle unpaid state
                  if (paymentStatus != 'paid' && paymentMethod != 'cash') ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final order = await ref
                                  .read(rideViewModelProvider.notifier)
                                  .createPaymentOrder(widget.rideId);
                              if (order != null) {
                                final options = {
                                  'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
                                  'amount': order['amount'],
                                  'name': 'Woosh',
                                  'description': 'Ride Payment',
                                  'order_id': order['id'],
                                  'prefill': {
                                    'contact': ride?.rider?.phoneNumber ?? '',
                                    'email': 'passenger@woosh.in',
                                  },
                                };
                                try {
                                  _razorpay.open(options);
                                } catch (e) {
                                  debugPrint('Error: $e');
                                }
                              }
                            },
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Pay Now',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Rider Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryPink,
                        width: 2,
                      ),
                      color: AppColors.lightPink, // fallback background
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.primaryPink,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!_rated) ...[
                    // Rating Question
                    Text(
                      'How was your ride with $riderName?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10        ),

                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < _selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFFF7043), // Orange star color
                              size: 34,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 22),

                    // What went well?
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What went well?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      alignment: WrapAlignment.start,
                      children: [
                        'Felt safe',
                        'Careful riding',
                        'On time',
                        'Friendly',
                        'Clean helmet',
                      ].map((c) => _ComplimentChip(
                            label: c,
                            isSelected: _selectedCompliments.contains(c),
                            onTap: () => _toggleCompliment(c),
                          )).toList(),
                    ),

                    const SizedBox(height: 22),

                    // Add a tip
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          text: 'Add a tip for $riderName ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                          children: const [
                            TextSpan(
                              text: '· 100% goes to her',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: AppColors.lightGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        '₹10',
                        '₹20',
                        '₹30',
                        'Other',
                      ].map((t) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _TipChip(
                                label: t,
                                isSelected: _selectedTip == t,
                                onTap: () => _toggleTip(t),
                              ),
                            ),
                          )).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                if (_selectedRating == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a rating'),
                                    ),
                                  );
                                  return;
                                }

                                String comment = '';
                                if (_selectedCompliments.isNotEmpty) {
                                  comment = _selectedCompliments.join(', ');
                                }
                                
                                // Call api
                                final success = await ref
                                    .read(rideViewModelProvider.notifier)
                                    .rateRide(
                                      widget.rideId,
                                      _selectedRating,
                                      comment: comment.isEmpty ? null : comment,
                                    );
                                
                                if (success && mounted) {
                                  setState(() => _rated = true);
                                }
                              },
                        child: state.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // Rated state
                    const SizedBox(height: 24),
                    const Text(
                      'Thank you!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your feedback helps us improve.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.lightGray,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ref.read(rideViewModelProvider.notifier).clearRide();
                          context.go('/home');
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Report Issue link
                  TextButton(
                    onPressed: () {
                      // Navigate to report issue page or show bottom sheet
                    },
                    child: const Text(
                      'Report an issue with this ride',
                      style: TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryPink,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper for the background curve
class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 50,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ComplimentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ComplimentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPink : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryPink : AppColors.darkText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPink : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryPink : AppColors.darkText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
