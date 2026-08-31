import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/di_providers.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';

/// Ride History Screen
class RideHistoryView extends ConsumerStatefulWidget {
  const RideHistoryView({super.key});

  @override
  ConsumerState<RideHistoryView> createState() => _RideHistoryViewState();
}

class _RideHistoryViewState extends ConsumerState<RideHistoryView> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/ride/history');
      // Backend returns { "data": { "rides": [...], "page": 1, ... } }
      final data = response.data['data']['rides'] as List? ?? [];
      setState(() {
        _rides = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () { if (context.canPop()) context.pop(); },
          child: const Icon(Icons.arrow_back, color: AppColors.darkText),
        ),
        title: const Text('Ride History', style: AppTextStyles.actionTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.errorRed)))
              : _rides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.two_wheeler, size: 64, color: AppColors.borderPink),
                          const SizedBox(height: 16),
                          const Text('No rides yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Book your first safe ride with Woosh.', style: TextStyle(color: AppColors.lightGray)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/home'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
                            child: const Text('Book a Ride', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final ride = _rides[i];
                        final fare = (ride['fare'] as num? ?? 0).toDouble();
                        final status = (ride['status'] ?? 'completed').toString();
                        final date = ride['createdAt'] != null ? DateTime.tryParse(ride['createdAt'].toString()) : null;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.dividerColor),
                            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: const BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                                    child: const Icon(Icons.two_wheeler, color: AppColors.primaryPink, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : 'Date —',
                                          style: const TextStyle(fontSize: 12, color: AppColors.lightGray),
                                        ),
                                        Text(
                                          '${(ride['distanceKm'] as num? ?? 0).toStringAsFixed(1)} km  •  ${ride['durationMinutes'] ?? 0} mins',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${fare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'completed' ? const Color(0xFFE8F5E9) : AppColors.lightPink,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                            color: status == 'completed' ? AppColors.successGreen : AppColors.primaryPink),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: AppColors.secondaryPurple),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(ride['pickup']?['address'] ?? '—', style: const TextStyle(fontSize: 12, color: AppColors.lightGray))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 10, color: AppColors.primaryPink),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(ride['drop']?['address'] ?? '—', style: const TextStyle(fontSize: 12, color: AppColors.lightGray))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
