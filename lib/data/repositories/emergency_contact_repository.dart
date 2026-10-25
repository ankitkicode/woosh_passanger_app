import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';

class EmergencyContactRepository {
  final EmergencyContactService _service;

  EmergencyContactRepository(this._service);

  Future<List<EmergencyContact>> getContacts() {
    return _service.getContacts();
  }

  Future<List<EmergencyContact>> addContact(Map<String, dynamic> data) {
    return _service.addContact(data);
  }

  Future<List<EmergencyContact>> updateContact(String id, Map<String, dynamic> data) {
    return _service.updateContact(id, data);
  }

  Future<List<EmergencyContact>> deleteContact(String id) {
    return _service.deleteContact(id);
  }
}
