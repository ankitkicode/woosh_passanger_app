import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/di_providers.dart';

/// Signup state
class SignupState {
  final String fullName;
  final String city;
  final String whatsappNumber;
  final String email;
  final List<EmergencyContact> emergencyContacts;
  final Map<String, String?> errors;
  final bool isSubmitting;
  final String? devOtp;

  const SignupState({
    this.fullName = '',
    this.city = '',
    this.whatsappNumber = '',
    this.email = '',
    this.emergencyContacts = const [],
    this.errors = const {},
    this.isSubmitting = false,
    this.devOtp,
  });

  SignupState copyWith({
    String? fullName,
    String? city,
    String? whatsappNumber,
    String? email,
    List<EmergencyContact>? emergencyContacts,
    Map<String, String?>? errors,
    bool? isSubmitting,
    String? devOtp,
  }) {
    return SignupState(
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      errors: errors ?? this.errors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      devOtp: devOtp ?? this.devOtp,
    );
  }
}

class EmergencyContact {
  final String name;
  final String number;

  const EmergencyContact({this.name = '', this.number = ''});

  EmergencyContact copyWith({String? name, String? number}) {
    return EmergencyContact(
      name: name ?? this.name,
      number: number ?? this.number,
    );
  }
}

/// Signup ViewModel — validates fields and sends OTP via backend.
class SignupViewModel extends StateNotifier<SignupState> {
  final Ref _ref;

  SignupViewModel(this._ref) : super(SignupState(emergencyContacts: [const EmergencyContact()]));

  void updateFullName(String value) => state = state.copyWith(fullName: value);
  void updateCity(String value) => state = state.copyWith(city: value);
  void updateWhatsappNumber(String value) => state = state.copyWith(whatsappNumber: value);
  void updateEmail(String value) => state = state.copyWith(email: value);

  void addEmergencyContact() {
    if (state.emergencyContacts.length < 3) {
      state = state.copyWith(
        emergencyContacts: [...state.emergencyContacts, const EmergencyContact()],
      );
    }
  }

  void removeEmergencyContact(int index) {
    if (state.emergencyContacts.length > 1) {
      final newContacts = List<EmergencyContact>.from(state.emergencyContacts);
      newContacts.removeAt(index);
      state = state.copyWith(emergencyContacts: newContacts);
    }
  }

  void updateEmergencyContact(int index, {String? name, String? number}) {
    final newContacts = List<EmergencyContact>.from(state.emergencyContacts);
    newContacts[index] = newContacts[index].copyWith(name: name, number: number);
    state = state.copyWith(emergencyContacts: newContacts);
  }

  bool validate() {
    final errors = <String, String?>{};
    if (state.fullName.isEmpty) errors['fullName'] = 'Full name is required';
    if (state.city.isEmpty) errors['city'] = 'City is required';
    if (state.whatsappNumber.length < 10) errors['whatsappNumber'] = 'Enter valid WhatsApp number';

    for (int i = 0; i < state.emergencyContacts.length; i++) {
      final contact = state.emergencyContacts[i];
      if (contact.name.isEmpty) errors['contactName$i'] = 'Name required';
      if (contact.number.length < 10) errors['contactNumber$i'] = 'Number required';
    }

    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  /// Submit signup form — sends OTP to whatsapp number.
  Future<String?> submit() async {
    if (!validate()) return null;

    state = state.copyWith(isSubmitting: true);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.sendOTP(state.whatsappNumber);
      final devOtp = result['otp']?.toString();
      state = state.copyWith(isSubmitting: false, devOtp: devOtp);
      return devOtp ?? 'sent';
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }
}

final signupViewModelProvider =
    StateNotifierProvider.autoDispose<SignupViewModel, SignupState>((ref) {
  return SignupViewModel(ref);
});
