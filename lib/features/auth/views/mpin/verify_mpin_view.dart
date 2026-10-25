import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../view_models/mpin_view_model.dart';
import '../../../../shared/widgets/woosh_app_bar.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import 'mpin_input_group.dart';

class VerifyMpinView extends ConsumerStatefulWidget {
  final String phoneNumber;
  const VerifyMpinView({super.key, required this.phoneNumber});

  @override
  ConsumerState<VerifyMpinView> createState() => _VerifyMpinViewState();
}

class _VerifyMpinViewState extends ConsumerState<VerifyMpinView> {
  String _mpin = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mpinViewModelProvider);

    ref.listen<MpinState>(mpinViewModelProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.errorRed),
        );
      } else if (next.isSuccess) {
        context.go('/home');
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
              const Text('Enter MPIN', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                'Unlock app for +91 ${widget.phoneNumber}',
                style: const TextStyle(color: AppColors.lightGray, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              MpinInputGroup(onChanged: (val) => setState(() => _mpin = val)),
              
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.push('/forgot-mpin?phone=${widget.phoneNumber}');
                  },
                  child: const Text(
                    'Forgot MPIN?',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              WooshGradientButton(
                text: 'Unlock',
                isLoading: state.isLoading,
                onPressed: () {
                  if (_mpin.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter 4 digits'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  ref.read(mpinViewModelProvider.notifier).verifyMpin(_mpin, widget.phoneNumber);
                },
              ),
              
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text(
                    'Login with OTP instead',
                    style: TextStyle(
                      color: AppColors.lightGray,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}