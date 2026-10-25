import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/emergency_contact.dart';
import '../data/repositories/emergency_contact_repository.dart';
import '../data/services/emergency_contact_service.dart';
import 'di_providers.dart';

final emergencyContactServiceProvider = Provider<EmergencyContactService>((ref) {
  return EmergencyContactService(ref.read(apiClientProvider));
});

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>((ref) {
  return EmergencyContactRepository(ref.read(emergencyContactServiceProvider));
});

class EmergencyContactsNotifier extends StateNotifier<AsyncValue<List<EmergencyContact>>> {
  final EmergencyContactRepository _repository;

  EmergencyContactsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    state = const AsyncValue.loading();
    try {
      final contacts = await _repository.getContacts();
      state = AsyncValue.data(contacts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addContact(Map<String, dynamic> data) async {
    try {
      final contacts = await _repository.addContact(data);
      state = AsyncValue.data(contacts);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateContact(String id, Map<String, dynamic> data) async {
    try {
      final contacts = await _repository.updateContact(id, data);
      state = AsyncValue.data(contacts);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      final contacts = await _repository.deleteContact(id);
      state = AsyncValue.data(contacts);
    } catch (e) {
      rethrow;
    }
  }
}

final emergencyContactsProvider = StateNotifierProvider<EmergencyContactsNotifier, AsyncValue<List<EmergencyContact>>>((ref) {
  return EmergencyContactsNotifier(ref.read(emergencyContactRepositoryProvider));
});
