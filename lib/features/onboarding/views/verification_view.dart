import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/woosh_app_bar.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../view_models/verification_view_model.dart';

class VerificationView extends ConsumerWidget {
  const VerificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationViewModelProvider);
    final notifier = ref.read(verificationViewModelProvider.notifier);

    // Listen for success state to navigate
    ref.listen(verificationViewModelProvider.select((s) => s.isSuccess), (previous, next) {
      if (next) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WooshAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildHeader(),
            const SizedBox(height: 8),
            _buildSubHeader(),
            const SizedBox(height: 40),
            _buildIllustration(state),
            const SizedBox(height: 40),
            _buildPrivacyBox(),
            const SizedBox(height: 20),
            _buildSelfieBox(state, notifier),
            const SizedBox(height: 40),
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            WooshGradientButton(
              text: 'Verify & Continue',
              isLoading: state.isVerifying,
              onPressed: state.isSelfieTaken ? notifier.verify : null,
            ),
            const SizedBox(height: 16),
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text('Verify that', style: AppTextStyles.headline),
        Text(
          'you are a woman',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = AppColors.brandGradient.createShader(
                const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
              ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: AppTextStyles.body,
        children: [
          TextSpan(text: 'This is for '),
          TextSpan(
            text: 'your safety',
            style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' so we can\nprovide a secure ride experience.'),
        ],
      ),
    );
  }

  Widget _buildIllustration(VerificationState state) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryPink.withValues(alpha: 0.1),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryPink.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white, width: 4),
            image: state.selfiePath != null
                ? DecorationImage(
                    image: FileImage(File(state.selfiePath!)),
                    fit: BoxFit.cover,
                  )
                : const DecorationImage(
                    image: AssetImage('assets/profile.png'),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowPink, blurRadius: 20, offset: Offset(0, 4))
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.primaryPink),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your privacy is our priority.', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'We don’t store or share this information.\nIt is used only for verification purposes.',
                  style: AppTextStyles.privacyText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieBox(VerificationState state, VerificationViewModel notifier) {
    return InkWell(
      onTap: notifier.takeSelfie,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Take a Selfie', style: AppTextStyles.actionTitle),
                SizedBox(height: 4),
                Text('Use your front camera to\ntake a clear selfie.', style: AppTextStyles.actionBody),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: AppColors.shadowPink, blurRadius: 10)],
              ),
              child: Icon(
                state.isSelfieTaken ? Icons.check_circle : Icons.camera_alt_outlined,
                color: AppColors.primaryPink,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: AppColors.primaryPink),
        SizedBox(width: 4),
        Text('Secure  •  Private  •  Women Only',
            style: TextStyle(fontSize: 12, color: AppColors.lightGray)),
      ],
    );
  }
}
