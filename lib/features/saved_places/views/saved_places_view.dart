import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/saved_places_view_model.dart';
import '../models/saved_place_model.dart';
import 'add_edit_place_bottom_sheet.dart';

class SavedPlacesView extends ConsumerWidget {
  const SavedPlacesView({super.key});

  void _showAddEditPlaceDialog(BuildContext context, {SavedPlace? place, String defaultType = 'other'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddEditPlaceBottomSheet(
        place: place,
        defaultType: defaultType,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.chevron_left,
              color: Color(0xFF1E1E1E),
              size: 28,
            ),
          ),
        ),
        title: const Text(
          'Saved places',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: state.when(
        data: (places) => _buildPlacesContent(context, ref, places),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFD40B7E)),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPlacesContent(
    BuildContext context,
    WidgetRef ref,
    List<SavedPlace> places,
  ) {
    final home = places.where((p) => p.type == 'home').firstOrNull;
    final work = places.where((p) => p.type == 'work').firstOrNull;
    final others = places
        .where((p) => p.type != 'home' && p.type != 'work')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPlaceItem(
            icon: Icons.home_outlined,
            iconColor: const Color(0xFFD40B7E),
            iconBgColor: const Color(0xFFFFF0F3),
            title: 'Home',
            subtitle: home?.address ?? 'House no, street, area, city',
            onTap: () {
              _showAddEditPlaceDialog(context, place: home, defaultType: 'home');
            },
          ),
          const SizedBox(height: 16),
          _buildPlaceItem(
            icon: Icons.work_outline,
            iconColor: const Color(0xFFE65100),
            iconBgColor: const Color(0xFFFFF3E0),
            title: 'Work',
            subtitle: work?.address ?? 'Office, street, area, city',
            onTap: () {
              _showAddEditPlaceDialog(context, place: work, defaultType: 'work');
            },
          ),
          const SizedBox(height: 16),
          if (others.isNotEmpty) ...[
            ...others.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlaceItem(
                  icon: Icons.bookmark_outline,
                  iconColor: const Color(0xFF1565C0),
                  iconBgColor: const Color(0xFFE3F2FD),
                  title: p.title.isNotEmpty ? p.title : 'Saved Place',
                  subtitle: p.address,
                  onTap: () {
                    _showAddEditPlaceDialog(context, place: p, defaultType: p.type);
                  },
                ),
              ),
            ),
          ] else ...[
            _buildPlaceItem(
              icon: Icons.bookmark_outline,
              iconColor: const Color(0xFF1565C0),
              iconBgColor: const Color(0xFFE3F2FD),
              title: 'College',
              subtitle: 'Street, area, city',
              onTap: () {
                _showAddEditPlaceDialog(context, defaultType: 'other');
              },
            ),
            const SizedBox(height: 16),
          ],

          InkWell(
            onTap: () {
              _showAddEditPlaceDialog(context, defaultType: 'other');
            },
            child: CustomPaint(
              painter: DashedRectPainter(
                color: const Color(0xFFF48FB1),
                strokeWidth: 1.5,
                gap: 4,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
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
                        Icons.add,
                        color: Color(0xFFD40B7E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a new place',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD40B7E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Gym, a friend's home, anywhere you go often",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF757575),
              size: 20,
            ),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );
    final Path path = Path()..addRRect(rrect);

    Path dashedPath = Path();
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + gap * 2),
          Offset.zero,
        );
        distance += gap * 4;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
