class Client {
  final int id;
  final String name;
  final int projectsCount;

  Client({required this.id, required this.name, this.projectsCount = 0});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'] ?? '',
      projectsCount: json['projects_count'] ?? json['project_count'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
