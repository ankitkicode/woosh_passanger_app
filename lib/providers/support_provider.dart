import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/support_service.dart';
import '../data/repositories/support_repository.dart';
import '../data/models/support_ticket.dart';
import 'di_providers.dart';

final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(ref.read(apiClientProvider));
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(supportServiceProvider));
});

final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final repository = ref.read(supportRepositoryProvider);
  return repository.getTickets();
});

final supportTicketProvider = FutureProvider.autoDispose.family<SupportTicket, String>((ref, ticketId) async {
  final repository = ref.read(supportRepositoryProvider);
  return repository.getTicketById(ticketId);
});
