import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/di_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/woosh_gradient_button.dart';
import '../../../shared/widgets/woosh_text_field.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
      };
      
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        data['email'] = email;
      }
      
      final response = await api.put('/passenger/profile', data: data);
      
      // Update local state
      final updatedUser = UserModel.fromJson(response.data['data']);
      ref.read(authStateProvider.notifier).setAuthenticated(updatedUser);
      if (mounted) {
        context.pop(true); // Return true to indicate profile was updated
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (e is DioException && e.response?.data != null) {
          final resData = e.response!.data;
          if (resData is Map && resData.containsKey('message')) {
            errMsg = resData['message'].toString();
          } else {
            errMsg = resData.toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $errMsg', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back, color: AppColors.darkText),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            WooshTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            WooshTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const Spacer(),
            WooshGradientButton(
              text: 'Save Changes',
              isLoading: _isLoading,
              onPressed: _updateProfile,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
