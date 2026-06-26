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
  final String statusDisplay;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.categoryDisplay,
    required this.priorityDisplay,
    required this.statusDisplay,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      subject: json['subject'] ?? '',
      categoryDisplay: json['category_display'] ?? '',
      priorityDisplay: json['priority_display'] ?? '',
      statusDisplay: json['status_display'] ?? '',
    );
  }
}
