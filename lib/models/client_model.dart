class Client {
  final int id;
  final String name;
  final int projectsCount;
  final String status;
  final String? createdAt;

  Client({
    required this.id,
    required this.name,
    this.projectsCount = 0,
    this.status = 'active',
    this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    String parsedStatus = 'active';
    if (json['status'] != null) {
      parsedStatus = json['status'].toString().toLowerCase();
    } else if (json['is_active'] != null) {
      parsedStatus = json['is_active'] == true ? 'active' : 'inactive';
    }

    final dateStr = json['created_at'] ??
        json['created_date'] ??
        json['created'] ??
        json['date_created'] ??
        json['date_joined'];

    return Client(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] ?? '',
      projectsCount: json['projects_count'] ?? json['project_count'] ?? 0,
      status: parsedStatus,
      createdAt: dateStr?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
