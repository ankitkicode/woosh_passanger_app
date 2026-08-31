import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/di_providers.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';

/// Wallet View
class WalletView extends ConsumerStatefulWidget {
  const WalletView({super.key});

  @override
  ConsumerState<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends ConsumerState<WalletView> {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final api = ref.read(apiClientProvider);
      final walletRes = await api.get('/payment/wallet');
      final txnRes = await api.get('/payment/transactions');
      setState(() {
        _wallet = walletRes.data['data'] as Map<String, dynamic>?;
        _transactions = (txnRes.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_wallet?['balance'] as num? ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () { if (context.canPop()) context.pop(); },
          child: const Icon(Icons.arrow_back, color: AppColors.darkText),
        ),
        title: const Text('My Wallet', style: AppTextStyles.actionTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 16)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Woosh Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            const Text('Secure • Instant • Women Safe', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Topup button
                  WooshGradientButton(
                    text: 'Add Money',
                    onPressed: () {
                      _showTopupSheet(context);
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text('Transaction History', style: AppTextStyles.actionTitle),
                  const SizedBox(height: 12),

                  if (_transactions.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, size: 48, color: AppColors.borderPink),
                          const SizedBox(height: 12),
                          const Text('No transactions yet', style: TextStyle(color: AppColors.lightGray)),
                        ],
                      ),
                    )
                  else
                    ...(_transactions.map((t) {
                      final amount = (t['amount'] as num? ?? 0).toDouble();
                      final type = t['type']?.toString() ?? '';
                      final isDebit = type.contains('debit') || amount < 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isDebit ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(isDebit ? Icons.remove : Icons.add, color: isDebit ? AppColors.errorRed : AppColors.successGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t['description']?.toString() ?? type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(t['createdAt']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
                                ],
                              ),
                            ),
                            Text(
                              '${isDebit ? '-' : '+'}₹${amount.abs().toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDebit ? AppColors.errorRed : AppColors.successGreen),
                            ),
                          ],
                        ),
                      );
                    })),
                ],
              ),
            ),
    );
  }

  void _showTopupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Money to Wallet', style: AppTextStyles.actionTitle),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [100, 200, 500, 1000].map((amount) {
                return ActionChip(
                  label: Text('₹$amount'),
                  backgroundColor: AppColors.lightPink,
                  labelStyle: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                  onPressed: () {},
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            WooshGradientButton(
              text: 'Proceed to Pay',
              onPressed: () { Navigator.pop(ctx); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
