class SupportQuickActions {
  final String supportEmail;
  final String supportPhone;
  final List<SupportLink> links;

  SupportQuickActions({
    required this.supportEmail,
    required this.supportPhone,
    required this.links,
  });

  factory SupportQuickActions.fromJson(Map<String, dynamic> json) {
    var linksList = json['links'] as List? ?? [];
    return SupportQuickActions(
      supportEmail: json['support_email'] ?? '',
      supportPhone: json['support_phone'] ?? '',
      links: linksList.map((e) => SupportLink.fromJson(e)).toList(),
    );
  }
}

class SupportLink {
  final String title;
  final String url;

  SupportLink({
    required this.title,
    required this.url,
  });

  factory SupportLink.fromJson(Map<String, dynamic> json) {
    return SupportLink(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class SupportTicket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String categoryDisplay;
  final String priorityDisplay;
  final String status;
  final String statusDisplay;
  final int unreadCount;
  final String lastMessageAt;
  final String createdAt;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.categoryDisplay,
    required this.priorityDisplay,
    required this.status,
    required this.statusDisplay,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      subject: json['subject'] ?? '',
      categoryDisplay: json['category_display'] ?? '',
      priorityDisplay: json['priority_display'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      unreadCount: json['unread_for_user_count'] ?? 0,
      lastMessageAt: json['last_message_at'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SupportTicketMessage {
  final int id;
  final String senderName;
  final String senderType; // 'user' or 'support' or similar
  final String body;
  final String attachmentUrl;
  final String createdAt;

  SupportTicketMessage({
    required this.id,
    required this.senderName,
    required this.senderType,
    required this.body,
    required this.attachmentUrl,
    required this.createdAt,
  });

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    return SupportTicketMessage(
      id: json['id'] ?? 0,
      senderName: sender['display_name'] ?? 'Support',
      senderType: json['sender_type'] ?? 'user',
      body: json['body'] ?? '',
      attachmentUrl: json['attachment_url'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class SupportTicketDetails {
  final SupportTicket ticket;
  final List<SupportTicketMessage> messages;

  SupportTicketDetails({
    required this.ticket,
    required this.messages,
  });

  factory SupportTicketDetails.fromJson(Map<String, dynamic> json) {
    var msgs = json['messages'] as List? ?? [];
    return SupportTicketDetails(
      ticket: SupportTicket.fromJson(json['ticket'] ?? {}),
      messages: msgs.map((e) => SupportTicketMessage.fromJson(e)).toList(),
    );
  }
}
