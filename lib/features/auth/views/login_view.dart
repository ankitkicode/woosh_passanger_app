import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/woosh_app_bar.dart';
import '../../../shared/widgets/woosh_text_field.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/woosh_security_badge.dart';
import '../view_models/login_view_model.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WooshAppBar(onBack: () {
        if (context.canPop()) context.pop();
      }),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            const Text('Welcome Back!', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            const Text(
              'Login to your account to continue your journey with safe and secure rides.',
              style: TextStyle(color: AppColors.lightGray, fontSize: 14),
            ),
            const SizedBox(height: 48),

            // Illustration
            Center(child: Image.asset('assets/safety_note.png', height: 120)),

            const SizedBox(height: 48),
            WooshTextField(
              label: 'WhatsApp Number',
              hint: 'Enter your 10-digit WhatsApp number',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              onChanged: notifier.updatePhoneNumber,
              errorText: state.error,
            ),

            const SizedBox(height: 40),
            WooshGradientButton(
              text: 'Login',
              isLoading: state.isSubmitting,
              onPressed: () async {
                final otpOrSent = await notifier.sendOTP();
                if (otpOrSent != null) {
                  if (context.mounted) {
                    if (otpOrSent != 'sent') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Test OTP: $otpOrSent (for testing only)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: AppColors.secondaryPurple,
                          duration: const Duration(seconds: 10),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    context.push('/otp/${state.phoneNumber}');
                  }
                }
              },
            ),

            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.lightGray)),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const WooshSecurityBadge(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
