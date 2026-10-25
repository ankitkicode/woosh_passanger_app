import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/support_provider.dart';
import '../../../core/theme/app_colors.dart';

class TicketChatView extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketChatView({super.key, required this.ticketId});

  @override
  ConsumerState<TicketChatView> createState() => _TicketChatViewState();
}

class _TicketChatViewState extends ConsumerState<TicketChatView> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repository = ref.read(supportRepositoryProvider);
      await repository.sendMessage(widget.ticketId, text);
      _messageController.clear();
      ref.invalidate(supportTicketProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsyncValue = ref.watch(supportTicketProvider(widget.ticketId));

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
        title: ticketAsyncValue.when(
          data: (ticket) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.ticketNumber,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                ticket.subject,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        centerTitle: false,
      ),
      body: ticketAsyncValue.when(
        data: (ticket) {
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  reverse: true, // Display bottom up
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.messages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    // Reverse the list
                    final message = ticket.messages[ticket.messages.length - 1 - index];
                    final isUser = message.sender == 'passenger';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primaryPink : Colors.white,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: isUser ? Colors.white : const Color(0xFF1E1E1E),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(message.createdAt.toLocal()),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: isUser ? Colors.white70 : const Color(0xFF9E9E9E),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (ticket.status == 'OPEN')
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: AppColors.primaryPink),
                              onPressed: _sendMessage,
                            ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      'This ticket is closed.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
