import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../view_models/mpin_view_model.dart';
import '../../../../shared/widgets/woosh_app_bar.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import '../../../../shared/widgets/woosh_text_field.dart';
import 'mpin_input_group.dart';

class ForgotMpinView extends ConsumerStatefulWidget {
  final String phoneNumber;
  const ForgotMpinView({super.key, required this.phoneNumber});

  @override
  ConsumerState<ForgotMpinView> createState() => _ForgotMpinViewState();
}

class _ForgotMpinViewState extends ConsumerState<ForgotMpinView> {
  String _otp = '';
  String _newMpin = '';
  String _confirmMpin = '';
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mpinViewModelProvider.notifier).sendOtpForForgotMpin(widget.phoneNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mpinViewModelProvider);

    ref.listen<MpinState>(mpinViewModelProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.errorRed),
        );
      } else if (next.isSuccess) {
        if (!_otpSent) {
          setState(() => _otpSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your number'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MPIN Reset Successfully'), backgroundColor: Colors.green),
          );
          // Go back to Verify MPIN screen or Login
          context.pop(); 
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WooshAppBar(
        onBack: () => context.canPop() ? context.pop() : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reset MPIN', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                'Enter the OTP sent to +91 ${widget.phoneNumber} and your new MPIN.',
                style: const TextStyle(color: AppColors.lightGray, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              WooshTextField(
                label: 'OTP',
                hint: 'Enter 6-digit OTP',
                icon: Icons.message_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (val) => setState(() => _otp = val),
              ),
              
              const SizedBox(height: 24),
              
              const Text('New MPIN', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              MpinInputGroup(onChanged: (val) => setState(() => _newMpin = val)),
              
              const SizedBox(height: 32),
              
              const Text('Confirm New MPIN', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              MpinInputGroup(onChanged: (val) => setState(() => _confirmMpin = val)),
              
              const SizedBox(height: 48),
              WooshGradientButton(
                text: 'Reset MPIN',
                isLoading: state.isLoading && _otpSent,
                onPressed: () {
                  if (_otp.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid OTP'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  if (_newMpin.length != 4 || _confirmMpin.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter 4 digits for MPIN'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  if (_newMpin != _confirmMpin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New MPINs do not match'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  ref.read(mpinViewModelProvider.notifier).forgotMpin(widget.phoneNumber, _otp, _newMpin, _confirmMpin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}