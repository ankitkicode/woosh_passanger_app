import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/woosh_app_bar.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/woosh_security_badge.dart';
import '../view_models/otp_view_model.dart';
import '../view_models/login_view_model.dart';
import '../view_models/signup_view_model.dart';

class OtpView extends ConsumerWidget {
  final String phoneNumber;

  const OtpView({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otpViewModelProvider(phoneNumber));
    final notifier = ref.read(otpViewModelProvider(phoneNumber).notifier);

    final loginDevOtp = ref.watch(loginViewModelProvider).devOtp;
    final signupDevOtp = ref.watch(signupViewModelProvider).devOtp;
    final activeOtp = state.devOtp ?? loginDevOtp ?? signupDevOtp;

    // Auto-fill on build if available and empty
    if (activeOtp != null && activeOtp.isNotEmpty && state.otpString.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setDevOtp(activeOtp);
      });
    }

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
          children: [
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(Icons.mobile_friendly_outlined, size: 80, color: AppColors.primaryPink.withValues(alpha: 0.3)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verify Your', style: AppTextStyles.headline),
                      const Text('Number', style: AppTextStyles.headline),
                      const SizedBox(height: 8),
                      Text(
                        "We've sent a 6-digit OTP to\n$phoneNumber",
                        style: const TextStyle(fontSize: 14, color: AppColors.lightGray),
                      ),
                      if (activeOtp != null && activeOtp.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.secondaryPurple.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '🔑 Test OTP: $activeOtp',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondaryPurple),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const Text('Enter 6-Digit OTP', style: AppTextStyles.label),
            const SizedBox(height: 8),
            const Text(
              'Enter the OTP we sent to your phone',
              style: TextStyle(fontSize: 12, color: AppColors.lightGray),
            ),
            const SizedBox(height: 24),

            // OTP Input
            _OtpInputGroup(onChanged: notifier.updateDigit),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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

            const SizedBox(height: 24),
            const Text("Didn't receive the OTP?", style: TextStyle(fontSize: 12, color: AppColors.lightGray)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Resend OTP in ',
                  style: TextStyle(fontSize: 12, color: state.canResend ? AppColors.lightGray : Colors.black),
                ),
                Text(
                  '00:${state.timerSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                ),
                if (state.canResend) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: notifier.resendOTP,
                    child: const Text(
                      'Resend Now',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 40),
            const WooshPrivacyNotice(
              title: 'Your security is important to us',
              subtitle: 'We never share your OTP or personal details with anyone.',
            ),
            const SizedBox(height: 32),

            WooshGradientButton(
              text: 'Verify & Continue',
              isLoading: state.isVerifying,
              onPressed: state.isComplete
                  ? () async {
                      if (await notifier.verify()) {
                        if (context.mounted) {
                          context.go('/home');
                        }
                      }
                    }
                  : null,
            ),

            const SizedBox(height: 24),
          ],
        ),
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
            children: List.generate(
              6,
              (index) {
                final isFocused = _focusNode.hasFocus && _controller.text.length == index ||
                                  (_controller.text.length == 6 && index == 5 && _focusNode.hasFocus);
                final text = index < _controller.text.length ? _controller.text[index] : '';
                
                return Container(
                  width: 45,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused ? AppColors.primaryPink : const Color(0xFFEEEEEE),
                      width: isFocused ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    text,
                    style: AppTextStyles.otpDigit,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
