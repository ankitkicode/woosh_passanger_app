import '../models/support_ticket.dart';
import 'api_client.dart';

class SupportService {
  final ApiClient _apiClient;

  SupportService(this._apiClient);

  Future<SupportTicket> createTicket({
    String? rideId,
    required String category,
    required String subject,
    required String message,
    required String priority,
  }) async {
    final data = <String, dynamic>{
      "category": category,
      "subject": subject,
      "message": message,
      "priority": priority,
    };
    if (rideId != null && rideId.isNotEmpty && rideId != 'none') {
      data["rideId"] = rideId;
    }
    final response = await _apiClient.post(
      '/passenger/support/tickets',
      data: data,
    );
    return SupportTicket.fromJson(response.data['data']);
  }

  Future<List<SupportTicket>> getTickets() async {
    final response = await _apiClient.get('/passenger/support/tickets');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => SupportTicket.fromJson(json)).toList();
  }

  Future<SupportTicket> getTicketById(String ticketId) async {
    final response = await _apiClient.get('/passenger/support/tickets/$ticketId');
    return SupportTicket.fromJson(response.data['data']);
  }

  Future<SupportTicket> sendMessage(String ticketId, String message) async {
    final response = await _apiClient.post(
      '/passenger/support/tickets/$ticketId/message',
      data: {
        "message": message,
      },
    );
    return SupportTicket.fromJson(response.data['data']);
  }
}
