import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../ride/views/invoice_bottom_sheet.dart';

class RideHistoryDetailsView extends ConsumerWidget {
  final Map<String, dynamic> ride;

  const RideHistoryDetailsView({super.key, required this.ride});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    final timeFormat = DateFormat('h:mm a').format(date).toLowerCase();

    if (dateToCheck == today) {
      return 'Today, $timeFormat';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, $timeFormat';
    } else {
      return '${DateFormat('E, d MMM').format(date)}, $timeFormat';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    final isCompleted = status == 'completed' || status == 'payment_completed';
    final isCancelled = status.contains('cancelled');

    final dateStr = ride['createdAt'] as String?;
    final dateObj = dateStr != null
        ? DateTime.parse(dateStr).toLocal()
        : DateTime.now();
    final dateText = _formatDate(dateObj);

    final vt = ride['vehicleType'];
    final cat = ride['category'];
    final vehicleType = vt is Map
        ? (vt['name'] ?? 'Bike')
        : (vt?.toString() ?? (cat is Map ? (cat['name'] ?? 'Bike') : (cat?.toString() ?? 'Bike')));
    final rideId =
        ride['_id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A';
    final subtitle = 'Woosh $vehicleType · Ride ID WSH-$rideId';

    final pickup = ride['pickup'];
    final pickupAddress = pickup is Map
        ? (pickup['name'] ?? pickup['address'] ?? 'Pickup place')
        : (pickup?.toString() ?? 'Pickup place');

    final drop = ride['drop'];
    final dropAddress = drop is Map
        ? (drop['name'] ?? drop['address'] ?? 'Drop place')
        : (drop?.toString() ?? 'Drop place');

    final pickupTime = DateFormat('HH:mm').format(dateObj);
    final dropTime = DateFormat('HH:mm').format(
      dateObj.add(Duration(minutes: ride['duration'] ?? 18)),
    ); // Mock drop time if unavailable

    final rider = ride['rider'];
    final riderName = rider is Map ? (rider['name'] ?? 'Rider name') : 'Rider name';
    final vehicle = rider is Map ? rider['vehicle'] : null;
    final riderVehicle = vehicle is Map ? (vehicle['model'] ?? 'Activa') : 'Activa';
    final riderReg = vehicle is Map ? (vehicle['registrationNumber'] ?? 'MP 04 AB 1234') : 'MP 04 AB 1234';
    final riderRating = rider is Map ? (rider['rating'] ?? 5) : 5;

    final distanceKm = (ride['distance'] ?? 5.2).toString();
    final durationMin = (ride['duration'] ?? 18).toString();

    final baseFare = ride['baseFare'] ?? 0;
    final platformFee = ride['platformFee'] ?? 0;
    final taxes = ride['taxes'] ?? 0;
    final discount = ride['discount'] ?? 0;
    final finalFare = ride['finalFare'] ?? ride['estimatedFare'] ?? 0;
    final paymentMethod = ride['paymentMethod'] ?? 'UPI';

    Color chipBgColor;
    Color chipTextColor;
    String chipText;

    if (isCompleted) {
      chipBgColor = const Color(0xFFE6F7EC);
      chipTextColor = const Color(0xFF14804A);
      chipText = 'Completed';
    } else if (isCancelled) {
      chipBgColor = const Color(0xFFF0F0F0);
      chipTextColor = const Color(0xFF4A4A4A);
      chipText = 'Cancelled';
    } else {
      chipBgColor = Colors.orange.shade50;
      chipTextColor = Colors.orange.shade800;
      chipText = status.toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map Background placeholder
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              color: const Color(0xFFF3F4ED),
              child: CustomPaint(painter: DetailedMapPainter()),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),

          // Scrollable Content
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateText,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Color(0xFF7A7A7A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: chipBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            chipText,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: chipTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Timeline
                    _buildTimelineRow(
                      iconColor: const Color(0xFF4CAF50),
                      isCircle: true,
                      title: pickupAddress,
                      subtitle:
                          'Area, city', // Assuming area/city not in API, mock it
                      time: pickupTime,
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 7),
                      height: 30,
                      child: const VerticalDivider(
                        color: Color(0xFFD4D4D4),
                        thickness: 2,
                        width: 2,
                      ),
                    ),
                    _buildTimelineRow(
                      iconColor: AppColors.primaryPink,
                      isCircle: false,
                      title: dropAddress,
                      subtitle: 'Area, city',
                      time: dropTime,
                    ),
                    const SizedBox(height: 24),

                    // Rider Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEBF1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.primaryPink,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riderName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                Text(
                                  '$riderReg · $riderVehicle',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Color(0xFF7A7A7A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$riderRating',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Fare Breakdown
                    _buildFareRow(
                      'Ride fare · $distanceKm km, $durationMin min',
                      '₹$baseFare',
                    ),
                    const SizedBox(height: 12),
                    _buildFareRow('Platform fee', '₹$platformFee'),
                    const SizedBox(height: 12),
                    _buildFareRow('Taxes', '₹$taxes'),
                    const SizedBox(height: 12),
                    _buildFareRow(
                      'Offer applied',
                      '-₹$discount',
                      valueColor: const Color(0xFF4CAF50),
                      titleColor: const Color(0xFF4CAF50),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0xFFEEEEEE), height: 1),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Total paid ',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                            children: [
                              TextSpan(
                                text: '· $paymentMethod',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF7A7A7A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹$finalFare',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Help Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF7E6EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.help_outline,
                              color: AppColors.primaryPink,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need help with this ride?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                Text(
                                  'Fare, lost item, safety or rider feedback',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF7A7A7A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.primaryPink,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final actualRideId = ride['_id']?.toString() ?? ride['id']?.toString() ?? '';
                              if (actualRideId.isNotEmpty) {
                                showInvoiceBottomSheet(context, ref, actualRideId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ride ID not available for invoice')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFEEEEEE)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.download,
                                  size: 18,
                                  color: AppColors.darkText,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Invoice',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPink,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.refresh,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Rebook',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required Color iconColor,
    required bool isCircle,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: iconColor,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF7A7A7A),
          ),
        ),
      ],
    );
  }

  Widget _buildFareRow(
    String title,
    String value, {
    Color? titleColor,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: titleColor ?? const Color(0xFF7A7A7A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

class DetailedMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.2, -50),
      Offset(size.width * 0.5, size.height + 50),
      roadPaint,
    );
    canvas.drawLine(
      Offset(-50, size.height * 0.3),
      Offset(size.width + 50, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, -50),
      Offset(size.width * 0.6, size.height + 50),
      roadPaint,
    );

    // Path
    final pathPaint = Paint()
      ..color = AppColors.primaryPink
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * 0.2, size.height * 0.55);
    final end = Offset(size.width * 0.8, size.height * 0.25);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2, end.dx, end.dy);
    canvas.drawPath(path, pathPaint);

    // Start Dot
    final startDotOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final startDotInner = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(start, 8, startDotOuter);
    canvas.drawCircle(start, 5, startDotInner);

    // End Square
    final endRect = Rect.fromCenter(center: end, width: 16, height: 16);
    final endRectInner = Rect.fromCenter(center: end, width: 10, height: 10);

    canvas.drawRect(endRect, startDotOuter);
    final endRectPaint = Paint()
      ..color = AppColors.primaryPink
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(endRectInner, const Radius.circular(2)),
      endRectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
