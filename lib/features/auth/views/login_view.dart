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
import '../view_models/otp_view_model.dart';
import '../view_models/signup_view_model.dart';
import '../../../providers/auth_provider.dart';


class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WooshAppBar(
        onBack: () {
          if (context.canPop()) context.pop();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Welcome Back!', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            const Text(
              'Login to your account to continue your journey with safe and secure rides.',
              style: TextStyle(color: AppColors.lightGray, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Illustration
            Center(child: Image.asset('assets/safety_note.png', height: 120)),

            const SizedBox(height: 20),
            WooshTextField(
              label: 'WhatsApp Number',
              hint: 'Enter your number',
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
                          content: Text(
                            'Test OTP: $otpOrSent (for testing only)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppColors.secondaryPurple,
                          duration: const Duration(seconds: 10),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          OtpBottomSheet(phoneNumber: state.phoneNumber),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Have an MPIN? ",
                    style: TextStyle(color: AppColors.lightGray),
                  ),
                  TextButton(
                    onPressed: () {
                      if (state.phoneNumber.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your phone number first'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                        return;
                      }
                      context.push('/verify-mpin?phone=${state.phoneNumber}');
                    },
                    child: const Text(
                      'Unlock via MPIN',
                      style: TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.lightGray),
                  ),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.bold,
                      ),
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

class OtpBottomSheet extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpBottomSheet({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends ConsumerState<OtpBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpViewModelProvider(widget.phoneNumber));
    final notifier = ref.read(
      otpViewModelProvider(widget.phoneNumber).notifier,
    );

    final loginDevOtp = ref.watch(loginViewModelProvider).devOtp;
    final signupDevOtp = ref.watch(signupViewModelProvider).devOtp;
    final activeOtp = state.devOtp ?? loginDevOtp ?? signupDevOtp;

    if (activeOtp != null && activeOtp.isNotEmpty && state.otpString.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setDevOtp(activeOtp);
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Sent to +91 ${widget.phoneNumber} ',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _OtpInputGroup(onChanged: notifier.updateDigit),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reading SMS automatically',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.canResend)
                GestureDetector(
                  onTap: notifier.resendOTP,
                  child: const Text(
                    'Resend Now',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    text: 'Resend in ',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(
                        text:
                            '0:${state.timerSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          WooshGradientButton(
            text: 'Verify',
            isLoading: state.isVerifying,
            onPressed: state.isComplete
                ? () async {
                    if (await notifier.verify()) {
                      if (context.mounted) {
                        context.pop(); // close bottom sheet
                        final user = ref.read(currentUserProvider);
                        if (user != null && !user.isMpinSet) {
                          context.go('/set-mpin');
                        } else {
                          context.go('/home');
                        }
                      }
                    }
                  }
                : null,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Already registered? You'll go straight to your\ndashboard",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInputGroup extends StatefulWidget {
  final Function(int, String) onChanged;

  const _OtpInputGroup({required this.onChanged});

  @override
  State<_OtpInputGroup> createState() => _OtpInputGroupState();
}

class _OtpInputGroupState extends State<_OtpInputGroup> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
      final text = _controller.text;
      for (int i = 0; i < 6; i++) {
        widget.onChanged(i, i < text.length ? text[i] : '');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden TextField
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
          // Visible OTP Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final isFocused =
                  _focusNode.hasFocus && _controller.text.length == index ||
                  (_controller.text.length == 6 &&
                      index == 5 &&
                      _focusNode.hasFocus);
              final text = index < _controller.text.length
                  ? _controller.text[index]
                  : '';

              return Container(
                width: 45,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primaryPink
                        : Colors.transparent,
                    width: isFocused ? 2 : 1,
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
