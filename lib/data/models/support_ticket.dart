class SupportTicket {
  final String id;
  final String ticketNumber;
  final String passengerId;
  final String category;
  final String subject;
  final String status;
  final String priority;
  final List<SupportMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.passengerId,
    required this.category,
    required this.subject,
    required this.status,
    required this.priority,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      passengerId: json['passenger'] ?? '',
      category: json['category'] ?? '',
      subject: json['subject'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => SupportMessage.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class SupportMessage {
  final String id;
  final String sender;
  final String senderUser;
  final String message;
  final List<String> attachments;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.sender,
    required this.senderUser,
    required this.message,
    required this.attachments,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['_id'] ?? '',
      sender: json['sender'] ?? '',
      senderUser: json['senderUser'] ?? '',
      message: json['message'] ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
