import '../models/support_ticket.dart';
import '../services/support_service.dart';

class SupportRepository {
  final SupportService _supportService;

  SupportRepository(this._supportService);

  Future<SupportTicket> createTicket({
    String? rideId,
    required String category,
    required String subject,
    required String message,
    required String priority,
  }) {
    return _supportService.createTicket(
      rideId: rideId,
      category: category,
      subject: subject,
      message: message,
      priority: priority,
    );
  }

  Future<List<SupportTicket>> getTickets() {
    return _supportService.getTickets();
  }

  Future<SupportTicket> getTicketById(String ticketId) {
    return _supportService.getTicketById(ticketId);
  }

  Future<SupportTicket> sendMessage(String ticketId, String message) {
    return _supportService.sendMessage(ticketId, message);
  }
}
