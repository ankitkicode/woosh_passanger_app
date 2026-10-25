import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/di_providers.dart';
import '../../../data/models/user_model.dart';
import '../view_models/profile_view_model.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load fresh data when entering the edit view
    Future.microtask(() => ref.read(profileViewModelProvider.notifier).loadProfile());

    final user = ref.read(authStateProvider).user;

    // Split name into first and last
    final String fullName = user?.name ?? user?.fullName ?? '';
    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty && nameParts[0].isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final user = ref.read(authStateProvider).user;

      final String fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();

      final data = <String, dynamic>{
        'name': fullName,
      };

      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        data['email'] = email;
      }

      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        data['phoneNumber'] = phone;
      }

      // Preserve existing profile data
      if (user != null) {
        if (user.dateOfBirth != null) data['dateOfBirth'] = user.dateOfBirth;
        if (user.city != null) data['city'] = user.city;
        if (user.state != null) data['state'] = user.state;
        if (user.preferences != null) data['preferences'] = user.preferences;
        if (user.safetySettings != null) data['safetySettings'] = user.safetySettings;
        if (user.emergencyContacts.isNotEmpty) {
          data['emergencyContacts'] = user.emergencyContacts.map((e) => e.toJson()).toList();
        }
      }

      final response = await api.put('/passenger/profile', data: data);

      // Update local state
      if (response.data != null && response.data['data'] != null) {
        final updatedUser = UserModel.fromJson(response.data['data']);
        ref.read(authStateProvider.notifier).setAuthenticated(updatedUser);
      }
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
            content: Text(
              'Failed to update profile: $errMsg',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final api = ref.read(apiClientProvider);
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: image.name),
      });

      final response = await api.post(
        '/passenger/profile-image',
        data: formData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Refresh the profile data from backend to ensure all views are in sync
      await ref.read(profileViewModelProvider.notifier).loadProfile();
      
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final currentUser = ref.read(authStateProvider).user;
        
        if (currentUser != null) {
          UserModel updatedUser;
          if (data is String) {
            updatedUser = currentUser.copyWith(profileImage: data);
          } else if (data is Map<String, dynamic>) {
            // Check if full user object or just image data
            if (data.containsKey('_id') || data.containsKey('phoneNumber')) {
              updatedUser = UserModel.fromJson(data);
            } else if (data.containsKey('profileImage')) {
              updatedUser = currentUser.copyWith(profileImage: data['profileImage']);
            } else if (data.containsKey('url')) {
              updatedUser = currentUser.copyWith(profileImage: data['url']);
            } else {
              updatedUser = currentUser;
            }
          } else {
            updatedUser = currentUser;
          }
          ref.read(authStateProvider.notifier).setAuthenticated(updatedUser);
        }
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
            content: Text(
              'Failed to upload image: $errMsg',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both auth state and profile state to ensure we have the latest image
    final authUser = ref.watch(authStateProvider).user;
    final profileState = ref.watch(profileViewModelProvider);
    final profileData = profileState.data;
    
    // Determine the most up-to-date image
    final String? currentProfileImage = profileData?['profileImage'] as String? ?? authUser?.profileImage;

    final String initial = _firstNameController.text.isNotEmpty
        ? _firstNameController.text[0].toUpperCase()
        : (authUser?.name?.isNotEmpty == true ? authUser!.name![0].toUpperCase() : 'R');

    String? getFullImageUrl(String? path) {
      if (path == null || path.isEmpty) return null;
      if (path.startsWith('http')) return path;
      final baseUrl = AppConfig.imageBaseUrl.endsWith('/')
          ? AppConfig.imageBaseUrl.substring(0, AppConfig.imageBaseUrl.length - 1)
          : AppConfig.imageBaseUrl;
      final imagePath = path.startsWith('/') ? path : '/$path';
      return '$baseUrl$imagePath';
    }

    final String? fullImageUrl = getFullImageUrl(currentProfileImage);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.chevron_left,
              color: Color(0xFF1E1E1E),
              size: 28,
            ),
          ),
        ),
        title: const Text(
          'Edit profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF14264),
                          width: 3,
                        ),
                        color: const Color(0xFFFFF0F3),
                      ),
                      alignment: Alignment.center,
                      child: _isUploadingImage
                          ? const CircularProgressIndicator(color: Color(0xFFD40B7E))
                          : (fullImageUrl != null)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: fullImageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFD40B7E)),
                                    errorWidget: (context, url, error) => Text(
                                      initial,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD40B7E),
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  initial,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD40B7E),
                                  ),
                                ),
                    ),
                    if (!_isUploadingImage)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD40B7E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First name',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          hintText: 'First',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD40B7E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last name',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          hintText: 'Last',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD40B7E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Mobile number',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Mobile number',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD40B7E)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Email (for invoices)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD40B7E)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF00796B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identity verified',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Verified via method keeps Woosh women-only',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF004D40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD40B7E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save changes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
