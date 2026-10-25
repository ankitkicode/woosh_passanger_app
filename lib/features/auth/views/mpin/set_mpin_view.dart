import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../view_models/mpin_view_model.dart';
import '../../../../shared/widgets/woosh_app_bar.dart';
import '../../../../shared/widgets/woosh_gradient_button.dart';
import 'mpin_input_group.dart';

class SetMpinView extends ConsumerStatefulWidget {
  const SetMpinView({super.key});

  @override
  ConsumerState<SetMpinView> createState() => _SetMpinViewState();
}

class _SetMpinViewState extends ConsumerState<SetMpinView> {
  String _mpin = '';
  String _confirmMpin = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mpinViewModelProvider);

    ref.listen<MpinState>(mpinViewModelProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.errorRed),
        );
      } else if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MPIN Set Successfully'), backgroundColor: Colors.green),
        );
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
              const Text('Create MPIN', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              const Text(
                'Set a 4-digit MPIN for quick app unlock without OTP.',
                style: TextStyle(color: AppColors.lightGray, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              const Text('Enter 4-digit MPIN', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              MpinInputGroup(onChanged: (val) => setState(() => _mpin = val)),
              
              const SizedBox(height: 32),
              
              const Text('Confirm 4-digit MPIN', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              MpinInputGroup(onChanged: (val) => setState(() => _confirmMpin = val)),
              
              const SizedBox(height: 48),
              WooshGradientButton(
                text: 'Set MPIN',
                isLoading: state.isLoading,
                onPressed: () {
                  if (_mpin.length != 4 || _confirmMpin.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter 4 digits'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  if (_mpin != _confirmMpin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('MPINs do not match'), backgroundColor: AppColors.errorRed),
                    );
                    return;
                  }
                  ref.read(mpinViewModelProvider.notifier).setMpin(_mpin, _confirmMpin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}