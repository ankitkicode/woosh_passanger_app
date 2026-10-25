import '../models/emergency_contact.dart';
import 'api_client.dart';

class EmergencyContactService {
  final ApiClient _apiClient;

  EmergencyContactService(this._apiClient);

  Future<List<EmergencyContact>> getContacts() async {
    final response = await _apiClient.get('/passenger/emergency-contacts');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => EmergencyContact.fromJson(json)).toList();
  }

  Future<List<EmergencyContact>> addContact(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/passenger/emergency-contacts',
      data: data,
    );
    final List<dynamic> responseData = response.data['data'] ?? [];
    return responseData.map((json) => EmergencyContact.fromJson(json)).toList();
  }

  Future<List<EmergencyContact>> updateContact(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '/passenger/emergency-contacts/$id',
      data: data,
    );
    final List<dynamic> responseData = response.data['data'] ?? [];
    return responseData.map((json) => EmergencyContact.fromJson(json)).toList();
  }

  Future<List<EmergencyContact>> deleteContact(String id) async {
    final response = await _apiClient.delete(
      '/passenger/emergency-contacts/$id',
    );
    final List<dynamic> responseData = response.data['data'] ?? [];
    return responseData.map((json) => EmergencyContact.fromJson(json)).toList();
  }
}
