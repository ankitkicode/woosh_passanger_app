import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/woosh_app_bar.dart';
import '../../../shared/widgets/woosh_text_field.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/woosh_security_badge.dart';
import '../view_models/signup_view_model.dart';

class SignupView extends ConsumerWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupViewModelProvider);
    final notifier = ref.read(signupViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WooshAppBar(
        onBack: () {
          if (context.canPop()) context.pop();
        },
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.verified_user_outlined, color: AppColors.primaryPink.withValues(alpha: 0.5)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Row(
              children: [
                Image.asset('assets/safety_note.png', height: 100),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Let's Get You", style: AppTextStyles.headline),
                      Text('Registered', style: AppTextStyles.headline),
                      SizedBox(height: 8),
                      Text(
                        'A few details to get you started.\nWe ensure your safety, always.',
                        style: TextStyle(fontSize: 14, color: AppColors.lightGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            WooshTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              onChanged: notifier.updateFullName,
              errorText: state.errors['fullName'],
            ),
            const SizedBox(height: 16),
            WooshTextField(
              label: 'City',
              hint: 'Enter your city',
              icon: Icons.location_on_outlined,
              onChanged: notifier.updateCity,
              errorText: state.errors['city'],
            ),
            const SizedBox(height: 16),
            WooshTextField(
              label: 'WhatsApp Number',
              hint: 'Enter your WhatsApp number',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              onChanged: notifier.updateWhatsappNumber,
              errorText: state.errors['whatsappNumber'],
            ),
            const SizedBox(height: 16),
            WooshTextField(
              label: 'Email ID (Optional)',
              hint: 'Enter your email ID',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged: notifier.updateEmail,
            ),
            const SizedBox(height: 24),

            // Emergency Contacts Section
            const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primaryPink),
                SizedBox(width: 8),
                Text('Emergency Contacts', style: AppTextStyles.label),
                Spacer(),
                Text('(Max 3)', style: TextStyle(fontSize: 12, color: AppColors.lightGray)),
              ],
            ),
            const Text(
              "We'll use these only in case of emergency.",
              style: TextStyle(fontSize: 12, color: AppColors.lightGray),
            ),
            const SizedBox(height: 16),

            ...List.generate(
              state.emergencyContacts.length,
              (index) => _EmergencyContactField(
                index: index + 1,
                onNameChanged: (v) => notifier.updateEmergencyContact(index, name: v),
                onNumberChanged: (v) => notifier.updateEmergencyContact(index, number: v),
                onRemove: state.emergencyContacts.length > 1 ? () => notifier.removeEmergencyContact(index) : null,
                nameError: state.errors['contactName$index'],
                numberError: state.errors['contactNumber$index'],
              ),
            ),

            if (state.emergencyContacts.length < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton.icon(
                  onPressed: notifier.addEmergencyContact,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryPink),
                  label: const Text('Add Contact', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                ),
              ),

            const SizedBox(height: 8),
            const WooshPrivacyNotice(),
            const SizedBox(height: 32),

            WooshGradientButton(
              text: 'Continue',
              isLoading: state.isSubmitting,
              onPressed: () async {
                final otpOrSent = await notifier.submit();
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
                    context.push('/otp/${state.whatsappNumber}');
                  }
                }
              },
            ),

            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: AppColors.lightGray)),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactField extends StatelessWidget {
  final int index;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onNumberChanged;
  final VoidCallback? onRemove;
  final String? nameError;
  final String? numberError;

  const _EmergencyContactField({
    required this.index,
    required this.onNameChanged,
    required this.onNumberChanged,
    this.onRemove,
    this.nameError,
    this.numberError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1_outlined, size: 18, color: AppColors.primaryPink),
              const SizedBox(width: 8),
              Text('Emergency Contact $index', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.errorRed),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: onNameChanged,
            decoration: InputDecoration(
              hintText: 'Enter contact name',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.lightGray),
              prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.primaryPink),
              errorText: nameError,
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onNumberChanged,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter mobile number',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.lightGray),
              prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primaryPink),
              errorText: numberError,
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
