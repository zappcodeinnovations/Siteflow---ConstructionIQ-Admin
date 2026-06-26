class Client {
  final int id;
  final String name;

  Client({required this.id, required this.name});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
