import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../view_models/ride_history_view_model.dart';
import 'ride_history_details_view.dart';

class RideHistoryView extends ConsumerStatefulWidget {
  const RideHistoryView({super.key});

  @override
  ConsumerState<RideHistoryView> createState() => _RideHistoryViewState();
}

class _RideHistoryViewState extends ConsumerState<RideHistoryView> {
  int _selectedTab = 0; // 0 = Past, 1 = Scheduled

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideHistoryViewModelProvider);
    final vm = ref.read(rideHistoryViewModelProvider.notifier);

    // Filter rides based on selected tab
    final displayRides = state.rides.where((ride) {
      final status = (ride['status'] as String? ?? '').toLowerCase();
      if (_selectedTab == 0) {
        return status != 'scheduled'; // Past rides
      } else {
        return status == 'scheduled'; // Scheduled rides
      }
    }).toList();

    // Group rides
    final groups = _groupRidesByTime(displayRides);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'My Rides',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSegmentedControl(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.isLoading && state.rides.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    )
                  : state.error != null && state.rides.isEmpty
                  ? Center(child: Text('Error: ${state.error}'))
                  : RefreshIndicator(
                      color: AppColors.primaryPink,
                      onRefresh: () => vm.loadHistory(),
                      child: displayRides.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    'No rides found.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.lightGray,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: groups.length,
                              itemBuilder: (context, index) {
                                final groupTitle = groups.keys.elementAt(index);
                                final groupRides = groups[groupTitle]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildGroupTitle(groupTitle),
                                    ...groupRides.map(
                                      (ride) => _buildRideCard(ride),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<dynamic>> _groupRidesByTime(List<dynamic> rides) {
    final now = DateTime.now();
    final thisWeek = <dynamic>[];
    final earlier = <dynamic>[];

    for (var ride in rides) {
      final dateStr = ride['createdAt'] as String?;
      if (dateStr == null) {
        earlier.add(ride);
        continue;
      }
      final date = DateTime.parse(dateStr).toLocal();
      final difference = now.difference(date).inDays;

      if (difference <= 7) {
        thisWeek.add(ride);
      } else {
        earlier.add(ride);
      }
    }

    final result = <String, List<dynamic>>{};
    if (thisWeek.isNotEmpty) result['THIS WEEK'] = thisWeek;
    if (earlier.isNotEmpty) result['EARLIER'] = earlier;
    return result;
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7A7A7A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF7EBEF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              'Past',
              _selectedTab == 0,
              () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              'Scheduled',
              _selectedTab == 1,
              () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.darkText : const Color(0xFF7A7A7A),
          ),
        ),
      ),
    );
  }

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
      return '${DateFormat('E, d MMM').format(date)} · $timeFormat';
    }
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final status = (ride['status'] as String? ?? '').toLowerCase();
    final isCompleted = status == 'completed' || status == 'payment_completed';
    final isCancelled = status.contains('cancelled');

    final dateStr = ride['createdAt'] as String?;
    final dateText = dateStr != null
        ? _formatDate(DateTime.parse(dateStr).toLocal())
        : 'Unknown Date';

    final vehicleType =
        ride['vehicleType']?['name'] ?? ride['category']?['name'] ?? 'Bike';
    final subtitle = '[$dateText] · $vehicleType';

    final dropAddress =
        ride['drop']?['name'] ??
        ride['drop']?['address'] as String? ??
        '[Drop place]';
    String title = dropAddress;

    final finalFare = ride['finalFare'] ?? ride['estimatedFare'] ?? 0;
    final amountText = '₹$finalFare';

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

    final rating = ride['rating'];
    Widget? ratingWidget;
    if (isCompleted) {
      if (rating != null) {
        ratingWidget = Row(
          children: [
            const Icon(Icons.star, size: 14, color: Color(0xFF7A7A7A)),
            const SizedBox(width: 4),
            Text(
              'You rated [$rating]',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ],
        );
      } else {
        ratingWidget = const Text(
          'Rate ride',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryPink,
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideHistoryDetailsView(ride: ride),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Placeholder
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: MapPathPainter(isCancelled: isCancelled),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amountText,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF7A7A7A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chipBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chipText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: chipTextColor,
                          ),
                        ),
                      ),
                      if (ratingWidget != null) ...[
                        const SizedBox(width: 12),
                        ratingWidget,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPathPainter extends CustomPainter {
  final bool isCancelled;

  MapPathPainter({required this.isCancelled});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF7F1E9); // light map bg
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      bgPaint,
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // draw some simple road lines
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );

    final pathColor = isCancelled
        ? const Color(0xFF9E9E9E)
        : AppColors.primaryPink;
    final startColor = isCancelled
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF4CAF50); // green start

    final pathPaint = Paint()
      ..color = pathColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(size.width * 0.2, size.height * 0.8);
    final end = Offset(size.width * 0.8, size.height * 0.2);

    if (isCancelled) {
      // Dashed line for cancelled
      final dir = end - start;
      final dist = dir.distance;
      const step = 6.0;
      for (double i = 0; i < dist; i += step * 2) {
        final p1 = start + dir * (i / dist);
        final p2 = start + dir * ((i + step).clamp(0.0, dist) / dist);
        canvas.drawLine(p1, p2, pathPaint);
      }
    } else {
      // Solid curve for others
      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.4,
        end.dx,
        end.dy,
      );
      canvas.drawPath(path, pathPaint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    dotPaint.color = startColor;
    canvas.drawCircle(start, 4, dotPaint);
    dotPaint.color = pathColor;
    canvas.drawCircle(end, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! MapPathPainter || oldDelegate.isCancelled != isCancelled;
}
