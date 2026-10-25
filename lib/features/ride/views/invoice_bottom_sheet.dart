import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/di_providers.dart';
import '../../../core/theme/app_colors.dart';

Future<void> showInvoiceBottomSheet(BuildContext context, WidgetRef ref, String rideId) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _InvoiceBottomSheetContent(rideId: rideId),
  );
}

class _InvoiceBottomSheetContent extends ConsumerStatefulWidget {
  final String rideId;
  const _InvoiceBottomSheetContent({required this.rideId});

  @override
  ConsumerState<_InvoiceBottomSheetContent> createState() => _InvoiceBottomSheetContentState();
}

class _InvoiceBottomSheetContentState extends ConsumerState<_InvoiceBottomSheetContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _invoiceData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/ride/${widget.rideId}/invoice');
      if (mounted) {
        setState(() {
          _invoiceData = response.data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) return;
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF invoice URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ride Invoice',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPink),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          'Error loading invoice: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _invoiceData == null
                        ? const Center(child: Text('No invoice data found'))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Invoice Number & Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _invoiceData!['invoiceNumber'] ?? 'INV-N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryPink,
                                      ),
                                    ),
                                    Text(
                                      _invoiceData!['invoiceDate'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF7A7A7A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Passenger info
                                if (_invoiceData!['invoiceData']?['passenger'] != null) ...[
                                  _sectionTitle('Passenger Details'),
                                  _infoRow('Name', _invoiceData!['invoiceData']['passenger']['name']),
                                  _infoRow('Phone', _invoiceData!['invoiceData']['passenger']['phoneNumber']),
                                  _infoRow('Email', _invoiceData!['invoiceData']['passenger']['email']),
                                  const SizedBox(height: 12),
                                ],

                                // Rider info
                                if (_invoiceData!['invoiceData']?['rider'] != null) ...[
                                  _sectionTitle('Rider Details'),
                                  _infoRow('Name', _invoiceData!['invoiceData']['rider']['name']),
                                  _infoRow('Vehicle', '${_invoiceData!['invoiceData']['rider']['vehicleModel'] ?? ''} (${_invoiceData!['invoiceData']['rider']['vehicleNumber'] ?? ''})'),
                                  const SizedBox(height: 12),
                                ],

                                // Trip info
                                if (_invoiceData!['invoiceData']?['trip'] != null) ...[
                                  _sectionTitle('Trip Details'),
                                  _infoRow('Pickup', _invoiceData!['invoiceData']['trip']['pickupAddress']),
                                  _infoRow('Drop', _invoiceData!['invoiceData']['trip']['dropAddress']),
                                  _infoRow('Distance', '${_invoiceData!['invoiceData']['trip']['distanceKm']} km'),
                                  _infoRow('Duration', '${_invoiceData!['invoiceData']['trip']['durationMinutes']} mins'),
                                  const SizedBox(height: 12),
                                ],

                                // Fare breakdown
                                if (_invoiceData!['invoiceData']?['fare'] != null) ...[
                                  _sectionTitle('Fare Breakdown'),
                                  _fareRow('Base Fare', '₹${_invoiceData!['invoiceData']['fare']['baseFare']}'),
                                  _fareRow('Waiting Charges', '₹${_invoiceData!['invoiceData']['fare']['waitingCharges']}'),
                                  _fareRow('Tip', '₹${_invoiceData!['invoiceData']['fare']['tipAmount']}'),
                                  _fareRow('Wallet Used', '₹${_invoiceData!['invoiceData']['fare']['walletAmountUsed']}'),
                                  const Divider(),
                                  _fareRow('Total Fare', '₹${_invoiceData!['invoiceData']['fare']['totalFare']}', isBold: true),
                                  _infoRow('Payment Method', _invoiceData!['invoiceData']['fare']['paymentMethod'].toString().toUpperCase()),
                                  _infoRow('Payment Status', _invoiceData!['invoiceData']['fare']['paymentStatus'].toString().toUpperCase()),
                                ],
                              ],
                            ),
                          ),
          ),

          const SizedBox(height: 16),

          // Download PDF Button
          if (_invoiceData != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _downloadPdf(
                  _invoiceData!['directPdfUrl'] ?? _invoiceData!['downloadUrl'],
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  'Download PDF Invoice',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.darkText : const Color(0xFF7A7A7A),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
